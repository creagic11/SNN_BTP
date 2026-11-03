"""A9.1: statistics of the N-MNIST input stream at sensor timing, and the per-bin work of BASE and HUSH.

    python scripts/stream_stats.py results/nmnist_T100_mf_e05_d025/weights.npz --n_raw 10000 --n_work 500

Part 1 (all test samples): raw DVS events and active pooled inputs (578) per 3 ms bin; link bandwidth.
Part 2 (n_work samples): per-bin cycles of the whole network (hidden HUSH or BASE + BASE output layer).
Per-bin cycles are an upper bound: each bin is costed alone, including the envelope pre-pass that the
real pipeline overlaps with the previous bin.
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
from golden.datasets import NMNIST  # noqa: E402
from golden.hush import LIFParams, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden  # noqa: E402
from scripts.rtl_perf import pad_out  # noqa: E402


def pct(a):
    a = np.asarray(a)
    return {"mean": float(a.mean()), "p50": float(np.percentile(a, 50)), "p99": float(np.percentile(a, 99)),
            "p999": float(np.percentile(a, 99.9)), "max": int(a.max())}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n_raw", type=int, default=10000)
    ap.add_argument("--n_work", type=int, default=500)
    ap.add_argument("--fclk", type=float, default=100e6)
    ap.add_argument("--out", default=str(ROOT / "results" / "realtime" / "stream_stats.json"))
    a = ap.parse_args()
    z = np.load(a.weights)
    T, t_max = int(z["T"]), int(float(z["t_max"]) * 1e6)
    bin_us = t_max / T
    d = NMNIST(False, t_max)
    idx = np.random.default_rng(0).permutation(len(d))
    raw, act, dur = [], [], []
    for i in idx[: a.n_raw]:
        ev, _ = d.ds[i]
        dur.append(int(ev["t"].max()))
        ev = ev[ev["t"] < t_max]
        b = ev["t"].astype(np.int64) * T // t_max
        raw.append(np.bincount(b, minlength=T))
        ch = ev["p"].astype(np.int64) * d.side * d.side + (ev["y"] // d.pool) * d.side + ev["x"] // d.pool
        act.append(np.array([len(np.unique(ch[b == t])) for t in range(T)]))
    raw, act = np.concatenate(raw), np.concatenate(act)
    res = {"samples_raw": a.n_raw, "T": T, "bin_us": bin_us, "budget_cycles_per_bin": int(bin_us * 1e-6 * a.fclk),
           "recording_length_us": pct(dur), "raw_events_per_bin": pct(raw), "active_inputs_per_bin": pct(act)}
    # link: an event as 2 bytes (10-bit pooled address + polarity) + 1 end-of-bin byte per bin; UART 10 bits/byte
    for k in ("mean", "max"):
        bits = (2 * res["active_inputs_per_bin"][k] + 1) * 10
        res[f"uart_baud_needed_{k}"] = bits / (bin_us * 1e-6)

    Ws = [z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
    for li in range(len(Ws) - 1):
        Ws[li], Ws[li + 1], _ = pad_hidden(Ws[li], Ws[li + 1], 32)
    Wo, _ = pad_out(Ws[-1])
    pg = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32, asleep_drive="mean")
    pr = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32)
    per = {"BASE": [], "HUSH": []}
    for i in idx[: a.n_work]:
        S, _ = d.raster(i, T)
        for mode in per:
            x, c = S, np.zeros(T, np.int64)
            for W in Ws[:-1]:
                h = run_gated(W, x, pg, shadow=False) if mode == "HUSH" else run_ref(W, x, pr)
                n = h.n_active.astype(np.int64)
                c += [rtl_cycles(n[t:t + 1], h.awake_blk[t:t + 1], envelope=(mode == "HUSH")) for t in range(T)]
                x = h.spikes
            o = run_ref(Wo, x, pr)
            n = o.n_active.astype(np.int64)
            c += [rtl_cycles(n[t:t + 1], o.awake_blk[t:t + 1], envelope=False) for t in range(T)]
            per[mode].append(c)
    B = res["budget_cycles_per_bin"]
    for mode, v in per.items():
        v = np.concatenate(v)
        res[f"{mode}_cycles_per_bin"] = pct(v)
        res[f"{mode}_headroom_at_max"] = B / int(v.max())
        res[f"{mode}_streams_per_chip_mean"] = B / float(v.mean())
        res[f"{mode}_min_fclk_MHz_for_worst_bin"] = int(v.max()) / (bin_us * 1e-6) / 1e6
    res["samples_work"] = a.n_work
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    json.dump(res, open(a.out, "w"), indent=2)
    print(json.dumps(res, indent=1))


if __name__ == "__main__":
    main()
