"""Cycle-exact RTL latency of a whole network from the golden model + rtl/sim/cycle_model.py (T2.4).

    python scripts/rtl_perf.py results/nmnist_T100_mf_e05_d025/weights.npz --mf 1 --n 300

Hidden layers run as HUSH (GATE=1, MF as given); the output layer runs as BASE (padded to 32
neurons). Also runs the same network fully as BASE for comparison. Reports mean cycles, latency at
f_clk, accuracy, and weight-word / column reads per inference.
"""

import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "rtl" / "sim"))
from cycle_model import rtl_cycles  # noqa: E402
from golden.hush import LIFParams, predict, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402


def pad_out(W):
    M, N = W.shape
    Np = -(-N // 32) * 32
    Wp = np.zeros((M, Np), np.int64)
    Wp[:, :N] = W
    Wp[:, N:] = -128
    return Wp, N


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--mf", type=int, default=0)
    ap.add_argument("--n", type=int, default=300)
    ap.add_argument("--fclk", type=float, default=100e6)
    a = ap.parse_args()
    z = np.load(a.weights)
    Ws = [z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
    k, theta, T = int(z["k"]), int(z["theta"]), int(z["T"])
    for li in range(len(Ws) - 1):
        Ws[li], Ws[li + 1], _ = pad_hidden(Ws[li], Ws[li + 1], 32)
    Wo, n_out = pad_out(Ws[-1])
    rasters, Y = test_rasters(z, a.n)
    pg = LIFParams(k=k, theta=theta, b_env=8, b_blk=32, asleep_drive="mean" if a.mf else "none")
    pr = LIFParams(k=k, theta=theta, b_env=8, b_blk=32)
    res = {}
    for mode in ("BASE", "HUSH"):
        cyc = acc = words = cols = 0
        for S, y in zip(rasters, Y):
            x = S
            for W in Ws[:-1]:
                h = run_gated(W, x, pg, shadow=False) if mode == "HUSH" else run_ref(W, x, pr)
                n = h.n_active.astype(np.int64)
                cyc += rtl_cycles(n, h.awake_blk, envelope=(mode == "HUSH"))
                words += int((h.awake_blk.sum(1) * n).sum())
                G = h.awake_blk.shape[1]
                cols += int(sum(h.awake_sub[t].reshape(G, 4)[h.awake_blk[t]].sum() * n[t] for t in range(len(n))))
                x = h.spikes
            o = run_ref(Wo, x, pr)
            n = o.n_active.astype(np.int64)
            cyc += rtl_cycles(n, o.awake_blk, envelope=False)
            words += int((o.awake_blk.sum(1) * n).sum())
            cols += int(4 * o.awake_blk.shape[1] * n.sum())
            o.spikes = o.spikes[:, :n_out]
            o.U = o.U[:, :n_out]
            acc += predict(o) == y
        m = len(Y)
        res[mode] = {"acc": acc / m, "cycles": cyc / m, "latency_us": cyc / m / a.fclk * 1e6,
                     "word_reads": words / m, "col_reads": cols / m}
    res["speedup"] = res["BASE"]["cycles"] / res["HUSH"]["cycles"]
    res["col_read_ratio"] = res["HUSH"]["col_reads"] / res["BASE"]["col_reads"]
    print(json.dumps(res, indent=1))
    json.dump(res, open(Path(a.weights).with_name("rtl_perf.json"), "w"), indent=2)


if __name__ == "__main__":
    main()
