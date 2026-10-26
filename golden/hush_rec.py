"""HUSH-G: integer golden models for recurrent adaptive LIF (adLIF) layers (tier-1 plan, P1.1).

Generalises golden/hush.py from a feed-forward LIF layer to

    z_t   = [x_t ; s_{t-1}]                      FF input spikes and the layer's own previous spikes
    Wc    = [Wff ; Wrec]                         (M + N, N); recurrence is just more input rows
    B_i   = L_k(V_i) - w_i                       drive-free part of the next potential
    U_i   = clip(B_i + z_t . Wc[:, i])           pre-reset potential
    s_i   = U_i >= theta ;  V_i' = U_i - theta s_i
    w_i'  = clip_w(L_kw(w_i) + ((a_i V_i') >> sa) + b_i s_i)      integer adLIF adaptation (Bittar & Garner 2022)

a_i (signed) and b_i are per-neuron integers. With a = b = 0, Wrec = None this is exactly the
golden/hush.py LIF layer (tested).

Gate ("headroom envelope"). For sub-block c, before the step's inputs are fetched:

    Bmax_c = max_{i in c} B_i                    exact, from the eager state sweep
    D_c    = z_t . P[:, c]                       P = signed proxy table of Wc (row max over c)
    g_c    = clip(Bmax_c) + D_c' >= theta_h      D_c' = D_c (signed_drive) or max(0, D_c) (v1 rule)
             or Bmax_c > vmax                    (saturated bound forces the sub-block awake)

Theorem 1' (safety): if g_c = 0 and theta_h <= theta then for every i in c the ungated update from
the same state has U_i < theta, so gating suppresses no spike. Proof: B_i <= Bmax_c <= clip(Bmax_c)
unless Bmax_c > vmax (then forced awake); z . Wc[:, i] <= z . P[:, c] = D_c <= D_c' because z >= 0;
clip is monotone and theta <= vmax. The adaptation term only enters through B_i, which the sweep
knows exactly, so negative adaptation (a_i < 0, which can push V up) is covered.

Asleep sub-blocks: "none" drops the step's drive (U = clip(B)); "mean" adds the shared mean drive
z . Q[:, c] with Q = floor(mean over c of Wc) <= P, so asleep neurons provably stay below theta.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from golden.hush import LayerTrace, LIFParams, _block_or, _stats, clip, leak, mean_table, proxy_table


@dataclass(frozen=True)
class AdLIFParams:
    lif: LIFParams = LIFParams()
    kw: int = 4              # adaptation leak shift (beta_w = 1 - 2**-kw)
    sa: int = 4              # coupling shift: w += (a_i * V') >> sa
    wbits: int = 16          # adaptation register width
    signed_drive: bool = True   # gate uses signed D (tighter); False = v1 rule max(0, D)

    @property
    def wmin(self) -> int:
        return -(1 << (self.wbits - 1))

    @property
    def wmax(self) -> int:
        return (1 << (self.wbits - 1)) - 1


@dataclass
class RecLayer:
    """Integer weights of one recurrent adLIF layer."""
    Wff: np.ndarray                    # (M, N) int
    Wrec: np.ndarray | None = None     # (N, N) int or None
    a: np.ndarray | None = None        # (N,) int, signed coupling V -> w
    b: np.ndarray | None = None        # (N,) int >= 0, spike-triggered adaptation

    @property
    def N(self) -> int:
        return self.Wff.shape[1]

    def Wc(self) -> np.ndarray:
        W = np.asarray(self.Wff, np.int64)
        return W if self.Wrec is None else np.vstack([W, np.asarray(self.Wrec, np.int64)])

    def ab(self):
        z = np.zeros(self.N, np.int64)
        a = z if self.a is None else np.asarray(self.a, np.int64)
        b = z if self.b is None else np.asarray(self.b, np.int64)
        return a, b


def _adapt(w, Vn, s, a, b, q: AdLIFParams):
    return np.clip(leak(w, q.kw) + ((a * Vn) >> q.sa) + b * s, q.wmin, q.wmax)


def _new_trace(T, N, C, G, n_active, gated, shadow):
    tr = LayerTrace(spikes=np.zeros((T, N), np.uint8), V=np.zeros((T, N), np.int64),
                    U=np.zeros((T, N), np.int64), awake_sub=np.ones((T, C), bool),
                    awake_blk=np.ones((T, G), bool), n_active=n_active)
    tr.Wad = np.zeros((T, N), np.int64)          # adaptation state after the step
    if gated:
        tr.E_hat = np.zeros((T, C), np.int64)    # clip(Bmax) + D' (the gate's left-hand side)
        tr.R = np.zeros((T, C), np.int64)        # Bmax_c used for the gate
        if shadow:
            tr.U_ungated = np.zeros((T, N), np.int64)
    return tr


def run_rec(L: RecLayer, X: np.ndarray, q: AdLIFParams, mode: str = "ref", shadow: bool = True) -> LayerTrace:
    """mode: 'ref' (no gating), 'gated' (HUSH-G), 'oracle' (sleep iff no neuron would reach theta).

    n_active counts the events the hardware processes at step t: FF spikes plus the layer's own
    spikes of step t-1.
    """
    p = q.lif
    X = np.asarray(X, np.int64)
    T, M = X.shape
    N = L.N
    C, G = N // p.b_env, N // p.b_blk
    Wc = L.Wc()
    rec = L.Wrec is not None
    a, b = L.ab()
    P = proxy_table(Wc, p.b_env)
    Q = mean_table(Wc, p.b_env) if p.asleep_drive == "mean" else None
    V = np.zeros(N, np.int64)
    w = np.zeros(N, np.int64)
    s = np.zeros(N, np.int64)
    gated = mode == "gated"
    tr = _new_trace(T, N, C, G, np.zeros(T, np.int64), gated, shadow)
    for t in range(T):
        z = np.concatenate([X[t], s]) if rec else X[t]
        tr.n_active[t] = int(z.sum())
        B = leak(V, p.k) - w
        U_full = clip(B + z @ Wc, p)
        if mode == "ref":
            g = np.ones(C, bool)
        elif mode == "oracle":
            g = (U_full >= p.theta).reshape(C, p.b_env).any(axis=1)
        else:
            Bmax = B.reshape(C, p.b_env).max(axis=1)
            D = z @ P
            Dp = D if q.signed_drive else np.maximum(D, 0)
            lhs = clip(Bmax, p) + Dp
            g = (lhs >= p.th_gate) | (Bmax > p.vmax)
            tr.E_hat[t], tr.R[t] = lhs, Bmax
            if shadow:
                tr.U_ungated[t] = U_full
        gn = np.repeat(g, p.b_env)
        if Q is None or mode != "gated":
            U_sleep = clip(B, p)
        else:
            U_sleep = clip(B + np.repeat(z @ Q, p.b_env), p)
        U = np.where(gn, U_full, U_sleep)
        s = ((U >= p.theta) & gn).astype(np.int64)
        V = U - p.theta * s
        w = _adapt(w, V, s, a, b, q)
        tr.U[t], tr.V[t], tr.spikes[t], tr.Wad[t], tr.awake_sub[t] = U, V, s, w, g
    tr.awake_blk = _block_or(tr.awake_sub, p)
    tr.stats = _stats(tr, p)
    return tr


def run_rec_network(layers: list[RecLayer], X: np.ndarray, qs: list[AdLIFParams], mode: str = "gated",
                    gate_layers: tuple[int, ...] | None = None) -> list[LayerTrace]:
    """Layer-major run; the output layer (last) runs 'ref' unless listed in gate_layers."""
    if gate_layers is None:
        gate_layers = tuple(range(len(layers) - 1))
    out, x = [], X
    for li, (L, q) in enumerate(zip(layers, qs)):
        tr = run_rec(L, x, q, mode if li in gate_layers else "ref", shadow=False)
        out.append(tr)
        x = tr.spikes
    return out
