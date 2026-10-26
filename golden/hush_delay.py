"""Golden model for feed-forward integer LIF networks with axonal (per-input) delays (tier-1 P1, delay path).

A delay d_j on input row j turns the event stream into z_t[j] = x_{t - d_j}[j] (events delayed past T are
dropped). The delayed stream is still a binary input stream, so every HUSH result for feed-forward layers
(Theorem 1 / 1') applies unchanged; hardware needs only a dmax-slot event ring buffer per layer input.
"""

from __future__ import annotations

import numpy as np

from golden.hush import LIFParams, run_ref
from golden.hush_rec import AdLIFParams, RecLayer, run_rec


def delay_events(S: np.ndarray, d: np.ndarray) -> np.ndarray:
    """S: (T, M) 0/1, d: (M,) ints >= 0. Returns Z with Z[t, j] = S[t - d_j, j] (0 if t < d_j)."""
    T, M = S.shape
    Z = np.zeros_like(S)
    for j in np.flatnonzero(S.any(axis=0)):
        dj = int(d[j])
        if dj < T:
            Z[dj:, j] = S[:T - dj, j]
    return Z


def run_delay_network(z, X: np.ndarray, mode: str = "ref", b_env: int = 8, asleep_drive: str = "none",
                      out_vbits: int = 24):
    """Run a QDSNN export (W*, D*, k, theta, k_out, out_theta). Hidden layers: mode 'ref' or 'gated'.
    Returns (hidden traces, output trace)."""
    nl = sum(1 for key in z.files if key.startswith("W") and key[1:].isdigit())
    k, theta = int(z["k"]), int(z["theta"])
    q = AdLIFParams(lif=LIFParams(k=k, theta=theta, b_env=b_env, b_blk=32, asleep_drive=asleep_drive),
                    signed_drive=True)
    x = X.astype(np.int64)
    traces = []
    for i in range(nl - 1):
        x = delay_events(x, z[f"D{i}"])
        tr = run_rec(RecLayer(z[f"W{i}"].astype(np.int64)), x, q, mode, shadow=False)
        traces.append(tr)
        x = tr.spikes.astype(np.int64)
    Wo = z[f"W{nl - 1}"].astype(np.int64)
    x = delay_events(x, z[f"D{nl - 1}"])
    po = LIFParams(k=int(z["k_out"]), theta=int(z["out_theta"]), vbits=out_vbits, b_env=Wo.shape[1], b_blk=Wo.shape[1])
    return traces, run_ref(Wo, x, po)
