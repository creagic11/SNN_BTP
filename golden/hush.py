"""Integer golden models for HUSH v2.

Three models of one fully connected LIF layer, all in exact integer arithmetic:

* ``run_ref``    -- REF: plain ungated integer LIF with soft reset.
* ``run_gated``  -- GATED: what the HUSH hardware computes. Each sub-block of
                    ``b_env`` neurons has a gate from the proxy envelope; a gated
                    sub-block drops that timestep's input drive and only leaks.
* ``run_oracle`` -- ORACLE: same dropping semantics, but the gate is the true
                    "some neuron in the sub-block reaches theta" test. It is the
                    lowest awake fraction any exact-mode gate can reach.

Conventions (shared with the RTL and the trainer):

* Weights ``W`` have shape (M, N): M inputs, N neurons, signed ints (INT8 range).
* Spikes ``S`` have shape (T, M), values 0/1.
* Leak:  L(x) = x - (x >> k)   (arithmetic shift, i.e. floor(x / 2**k)).
* Every potential is clipped to the signed ``vbits`` range with the same
  monotone clip. Because the clip is non-decreasing, it preserves every
  inequality used in the safety proof (see docs/proposal_v2.md, Theorem 1).
* Neuron i belongs to sub-block i // b_env and to block i // b_blk.
  N must be a multiple of b_blk, and b_blk a multiple of b_env.
"""

from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np


@dataclass(frozen=True)
class LIFParams:
    k: int = 3            # leak shift; lambda = 1 - 2**-k
    theta: int = 64       # firing threshold
    theta_h: int | None = None  # gate threshold; None means theta (exact mode)
    vbits: int = 16       # width of membrane and envelope registers
    b_env: int = 8        # neurons per envelope sub-block
    b_blk: int = 32       # neurons per scheduling block (one 256-bit weight word)
    resync: bool = True   # True: R_c = exact max V every step (the leak sweep sees asleep neurons);
                          # False: v1-style carried bound, R_c = E_c while asleep (error accumulates)

    @property
    def th_gate(self) -> int:
        return self.theta if self.theta_h is None else self.theta_h

    @property
    def vmin(self) -> int:
        return -(1 << (self.vbits - 1))

    @property
    def vmax(self) -> int:
        return (1 << (self.vbits - 1)) - 1


def leak(x, k: int):
    """L(x) = x - (x >> k) on integer arrays (numpy >> is arithmetic for signed ints)."""
    x = np.asarray(x, dtype=np.int64)
    return x - (x >> k)


def clip(x, p: LIFParams):
    return np.clip(x, p.vmin, p.vmax)


def proxy_table(W: np.ndarray, b_env: int) -> np.ndarray:
    """Signed proxy P[j, c] = max over neurons i in sub-block c of W[j, i]. Shape (M, N // b_env)."""
    M, N = W.shape
    assert N % b_env == 0, "N must be a multiple of b_env"
    return W.reshape(M, N // b_env, b_env).max(axis=2)


@dataclass
class LayerTrace:
    """Everything a layer run produces; the RTL testbench compares against these."""
    spikes: np.ndarray            # (T, N) output spikes, uint8
    V: np.ndarray                 # (T, N) post-reset potentials
    U: np.ndarray                 # (T, N) pre-reset potentials (for gated neurons: L(V_prev))
    awake_sub: np.ndarray         # (T, C) sub-block gates (all ones for REF)
    awake_blk: np.ndarray         # (T, G) block gates = OR of its sub-blocks
    n_active: np.ndarray          # (T,) active inputs per timestep
    E_hat: np.ndarray | None = None   # (T, C) envelope values (GATED only)
    R: np.ndarray | None = None       # (T, C) running bounds (GATED only)
    U_ungated: np.ndarray | None = None  # (T, N) what the ungated update would give from the same state
    stats: dict = field(default_factory=dict)


def _block_or(awake_sub: np.ndarray, p: LIFParams) -> np.ndarray:
    T, C = awake_sub.shape
    per = p.b_blk // p.b_env
    return awake_sub.reshape(T, C // per, per).any(axis=2)


def _stats(tr: LayerTrace, p: LIFParams) -> dict:
    T, C = tr.awake_sub.shape
    G = tr.awake_blk.shape[1]
    n = tr.n_active.astype(np.int64)
    # Cycle-weighted work: a block costs n_t cycles when awake (one weight word per active input).
    base_work = int(G * n.sum())
    blk_work = int((tr.awake_blk.sum(axis=1) * n).sum())
    sub_work = int((tr.awake_sub.sum(axis=1) * n).sum())
    return {
        "rho_sub": float(tr.awake_sub.mean()),
        "rho_blk": float(tr.awake_blk.mean()),
        # work-weighted awake fractions (timesteps with more inputs count more)
        "rho_sub_w": sub_work / max(1, C * int(n.sum())),
        "rho_blk_w": blk_work / max(1, base_work),
        "base_work": base_work,
        "blk_work": blk_work,
        "sub_work": sub_work,
        "spike_rate": float(tr.spikes.mean()),
        "in_rate": float(n.sum()) / max(1, T * 1),
    }


def run_ref(W: np.ndarray, S: np.ndarray, p: LIFParams, V0=None) -> LayerTrace:
    """Plain integer LIF, no gating."""
    W = np.asarray(W, dtype=np.int64)
    S = np.asarray(S, dtype=np.int64)
    T, M = S.shape
    N = W.shape[1]
    C, G = N // p.b_env, N // p.b_blk
    V = np.zeros(N, np.int64) if V0 is None else np.asarray(V0, np.int64).copy()
    out = LayerTrace(
        spikes=np.zeros((T, N), np.uint8), V=np.zeros((T, N), np.int64), U=np.zeros((T, N), np.int64),
        awake_sub=np.ones((T, C), bool), awake_blk=np.ones((T, G), bool), n_active=S.sum(axis=1),
    )
    for t in range(T):
        U = clip(leak(V, p.k) + S[t] @ W, p)
        s = U >= p.theta
        V = U - p.theta * s
        out.U[t], out.V[t], out.spikes[t] = U, V, s
    out.stats = _stats(out, p)
    return out


def run_gated(W: np.ndarray, S: np.ndarray, p: LIFParams, P: np.ndarray | None = None,
              shadow: bool = True) -> LayerTrace:
    """HUSH envelope-gated LIF: the exact behaviour the hardware must reproduce bit for bit.

    If ``shadow`` is True, also records U_ungated, the pre-reset potential the ungated update
    would have produced from the same state, so tests can check the safety invariant.
    """
    W = np.asarray(W, dtype=np.int64)
    S = np.asarray(S, dtype=np.int64)
    T, M = S.shape
    N = W.shape[1]
    C, G = N // p.b_env, N // p.b_blk
    if P is None:
        P = proxy_table(W, p.b_env)
    P = np.asarray(P, np.int64)
    V = np.zeros(N, np.int64)
    R = np.zeros(C, np.int64)
    out = LayerTrace(
        spikes=np.zeros((T, N), np.uint8), V=np.zeros((T, N), np.int64), U=np.zeros((T, N), np.int64),
        awake_sub=np.zeros((T, C), bool), awake_blk=np.zeros((T, G), bool), n_active=S.sum(axis=1),
        E_hat=np.zeros((T, C), np.int64), R=np.zeros((T, C), np.int64),
        U_ungated=np.zeros((T, N), np.int64) if shadow else None,
    )
    for t in range(T):
        D = S[t] @ P                                        # (C,) signed drive bound
        E = clip(leak(R, p.k) + np.maximum(D, 0), p)        # envelope
        g = E >= p.th_gate                                  # sub-block gates
        gn = np.repeat(g, p.b_env)                          # per-neuron gate
        LV = leak(V, p.k)
        U_full = clip(LV + S[t] @ W, p)
        U = np.where(gn, U_full, LV)                        # gated neurons only leak
        s = (U >= p.theta) & gn
        V = U - p.theta * s
        Vmax = V.reshape(C, p.b_env).max(axis=1)
        R = Vmax if p.resync else np.where(g, Vmax, E)
        out.U[t], out.V[t], out.spikes[t] = U, V, s
        out.awake_sub[t], out.E_hat[t], out.R[t] = g, E, R
        if shadow:
            out.U_ungated[t] = U_full
    out.awake_blk = _block_or(out.awake_sub, p)
    out.stats = _stats(out, p)
    return out


def run_oracle(W: np.ndarray, S: np.ndarray, p: LIFParams) -> LayerTrace:
    """Same dropping semantics as GATED, but a sub-block sleeps exactly when none of its neurons
    would reach theta this timestep. Lower bound on the awake fraction of any exact-mode gate."""
    W = np.asarray(W, dtype=np.int64)
    S = np.asarray(S, dtype=np.int64)
    T, M = S.shape
    N = W.shape[1]
    C, G = N // p.b_env, N // p.b_blk
    V = np.zeros(N, np.int64)
    out = LayerTrace(
        spikes=np.zeros((T, N), np.uint8), V=np.zeros((T, N), np.int64), U=np.zeros((T, N), np.int64),
        awake_sub=np.zeros((T, C), bool), awake_blk=np.zeros((T, G), bool), n_active=S.sum(axis=1),
    )
    for t in range(T):
        LV = leak(V, p.k)
        U_full = clip(LV + S[t] @ W, p)
        g = (U_full >= p.theta).reshape(C, p.b_env).any(axis=1)
        gn = np.repeat(g, p.b_env)
        U = np.where(gn, U_full, LV)
        s = (U >= p.theta) & gn
        V = U - p.theta * s
        out.U[t], out.V[t], out.spikes[t], out.awake_sub[t] = U, V, s, g
    out.awake_blk = _block_or(out.awake_sub, p)
    out.stats = _stats(out, p)
    return out


RUNNERS = {"ref": run_ref, "gated": run_gated, "oracle": run_oracle}


def run_network(layers: list[np.ndarray], S_in: np.ndarray, params: list[LIFParams],
                mode: str = "gated", gate_layers: tuple[int, ...] | None = None):
    """Layer-major run of a feed-forward network. ``gate_layers`` lists the layer indices that use
    ``mode``; the others run REF (the small output layer is normally left ungated)."""
    if gate_layers is None:
        gate_layers = tuple(range(len(layers) - 1))
    S = S_in
    traces = []
    for li, (W, p) in enumerate(zip(layers, params)):
        fn = RUNNERS[mode] if li in gate_layers else run_ref
        tr = fn(W, S, p)
        traces.append(tr)
        S = tr.spikes
    return traces


def predict(out_trace: LayerTrace) -> int:
    """Class decision: most output spikes; ties broken by the larger summed pre-reset potential,
    then by the lower index. Integer-only so the RTL can do the same."""
    counts = out_trace.spikes.sum(axis=0).astype(np.int64)
    usum = out_trace.U.sum(axis=0)
    best = 0
    for i in range(1, counts.size):
        if counts[i] > counts[best] or (counts[i] == counts[best] and usum[i] > usum[best]):
            best = i
    return best
