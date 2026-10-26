"""Learned grouping (P1.3): permute hidden neurons into sub-blocks to minimise the envelope drive cost

    J(perm) = sum_c sum_j r_j * relu(max_{i in c} Wc[j, i])

(r_j = firing rate of input row j, Wc = [Wff; Wrec] for recurrent layers). A permutation of hidden
neurons leaves the network function unchanged (apply it to Wff columns, Wrec rows and columns, a, b and
the next layer's rows), so any decrease of J is free.

Optimiser: balanced k-means start, then greedy pairwise swaps between sub-blocks (accept if J drops).
"""

from __future__ import annotations

import numpy as np


def drive_cost(Wc: np.ndarray, r: np.ndarray, b_env: int) -> float:
    M, N = Wc.shape
    P = Wc.reshape(M, N // b_env, b_env).max(axis=2)
    return float((r[:, None] * np.maximum(P, 0)).sum())


def optimise_groups(Wc: np.ndarray, r: np.ndarray, b_env: int, sweeps: int = 4, seed: int = 0,
                    init: np.ndarray | None = None) -> np.ndarray:
    """Return perm (new position -> old neuron index), grouping consecutive b_env neurons."""
    M, N = Wc.shape
    C = N // b_env
    rng = np.random.default_rng(seed)
    Wr = np.maximum(Wc, 0).astype(np.float64)                 # only positive parts enter relu(max)
    perm = np.arange(N) if init is None else init.copy()
    groups = perm.reshape(C, b_env).copy()

    def gcost(members):
        return float(r @ Wr[:, members].max(axis=1))

    cost = np.array([gcost(groups[c]) for c in range(C)])
    for _ in range(sweeps):
        improved = 0
        for c1 in rng.permutation(C):
            for c2 in rng.permutation(C):
                if c2 <= c1:
                    continue
                g1, g2 = groups[c1], groups[c2]
                # try every cross swap, pick the best one
                base = cost[c1] + cost[c2]
                best, arg = base - 1e-9, None
                for p1 in range(b_env):
                    m1 = np.delete(g1, p1)
                    mx1 = Wr[:, m1].max(axis=1)
                    for p2 in range(b_env):
                        m2 = np.delete(g2, p2)
                        n1 = r @ np.maximum(mx1, Wr[:, g2[p2]])
                        n2 = r @ np.maximum(Wr[:, m2].max(axis=1), Wr[:, g1[p1]])
                        if n1 + n2 < best:
                            best, arg = n1 + n2, (p1, p2, n1, n2)
                if arg is not None:
                    p1, p2, n1, n2 = arg
                    g1[p1], g2[p2] = g2[p2], g1[p1]
                    cost[c1], cost[c2] = n1, n2
                    improved += 1
        if not improved:
            break
    return groups.reshape(-1)


def permute_layer(z: dict, li: int, perm: np.ndarray) -> dict:
    """Apply a hidden-neuron permutation to layer li of a weights dict (FF or rec)."""
    z = dict(z)
    z[f"W{li}"] = z[f"W{li}"][:, perm]
    if f"R{li}" in z:
        z[f"R{li}"] = z[f"R{li}"][perm][:, perm]
    for key in (f"A{li}", f"Bad{li}"):
        if key in z:
            z[key] = z[key][perm]
    z[f"W{li + 1}"] = z[f"W{li + 1}"][perm]
    return z
