"""A9.2: whole-network latency of hush_net (hidden + output layer overlapped, class decided on chip) from the
golden model + rtl/sim/net_cycle_model.py (exact against the RTL; see rtl/sim/run_net.py).

    python scripts/net_perf.py results/nmnist_T100_mf_e05_d025_ep12/weights.npz --mf 1 --n 500

Writes net_perf.json next to the weights: for BASE (same weights, ungated) and HUSH: accuracy, mean / max
cycles, latency at f_clk, mean hidden-layer cycles, peak FIFO occupancy; and the old sequential sum (rtl_perf).
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
from net_cycle_model import net_cycles  # noqa: E402
from golden.hush import LIFParams, LayerTrace, predict, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--mf", type=int, default=1)
    ap.add_argument("--n", type=int, default=500)
    ap.add_argument("--fclk", type=float, default=100e6)
    a = ap.parse_args()
    z = np.load(a.weights)
    W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    nout = W2.shape[1]
    Wo = np.full((W2.shape[0], 32), -128, np.int64)
    Wo[:, :nout] = W2
    rasters, Y = test_rasters(z, a.n)
    pg = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32, asleep_drive="mean" if a.mf else "none")
    pr = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32)
    res = {}
    for mode in ("BASE", "HUSH"):
        cyc, l1c, seq, peak, acc = [], [], [], 0, 0
        for S, y in zip(rasters, Y):
            h = run_gated(W1, S, pg, shadow=False) if mode == "HUSH" else run_ref(W1, S, pr)
            n1 = h.n_active.astype(np.int64)
            hs = h.spikes.astype(np.int64)
            c, pk, l1 = net_cycles(n1, h.awake_blk, mode == "HUSH", hs, nout)
            o = run_ref(Wo, hs, pr)
            seq.append(l1 + rtl_cycles(o.n_active.astype(np.int64), o.awake_blk, envelope=False))
            cyc.append(c); l1c.append(l1); peak = max(peak, pk)
            acc += predict(LayerTrace(spikes=o.spikes[:, :nout], V=o.V[:, :nout], U=o.U[:, :nout],
                                      awake_sub=o.awake_sub, awake_blk=o.awake_blk, n_active=o.n_active)) == y
        cyc = np.array(cyc)
        res[mode] = {"acc": acc / len(Y), "cycles": float(cyc.mean()), "cycles_max": int(cyc.max()),
                     "latency_us": float(cyc.mean()) / a.fclk * 1e6, "l1_cycles": float(np.mean(l1c)),
                     "seq_sum_cycles": float(np.mean(seq)), "fifo_peak": int(peak)}
    res["speedup"] = res["BASE"]["cycles"] / res["HUSH"]["cycles"]
    res["n"] = len(Y)
    print(json.dumps(res, indent=1))
    json.dump(res, open(Path(a.weights).with_name("net_perf.json"), "w"), indent=2)


if __name__ == "__main__":
    main()
