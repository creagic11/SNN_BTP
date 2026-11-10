"""A9.7: accuracy vs elapsed sensor time. The on-chip classifier's spike counts and summed U after window w are a
prefix of the full run (the network is causal), so the class read after w windows = golden predict on windows
0..w-1. Full test set by default.

    python scripts/early_decision.py --n 10000
"""
import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402

POINTS = {"BASE": ("results/nmnist_T100/weights.npz", None),
          "HUSH gentler 12ep": ("results/nmnist_T100_mf_e025_d01_ep12/weights.npz", "mean"),
          "HUSH gentle 12ep": ("results/nmnist_T100_mf_e05_d025_ep12/weights.npz", "mean"),
          "HUSH aggressive": ("results/nmnist_T100_mf_e2_d1/weights.npz", "mean"),
          "BASE + 12 ep fine-tune, no gate (control)": ("results/nmnist_T100_ft12_ctrl/weights.npz", None)}


def prefix_predict(spk, U, nout):
    """predict() on every prefix: returns class after each window (T,)."""
    cnt = np.cumsum(spk[:, :nout], 0)
    us = np.cumsum(U[:, :nout], 0)
    out = np.empty(len(cnt), np.int64)
    for w in range(len(cnt)):
        best = 0
        for i in range(1, nout):
            if cnt[w, i] > cnt[w, best] or (cnt[w, i] == cnt[w, best] and us[w, i] > us[w, best]):
                best = i
        out[w] = best
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=10000)
    ap.add_argument("--out", default=str(ROOT / "results" / "realtime" / "early_decision.json"))
    a = ap.parse_args()
    res = json.load(open(a.out)) if Path(a.out).exists() and a.n == 10000 else {}
    for name, (w, drive) in POINTS.items():
        if name in res:
            continue
        z = np.load(ROOT / w)
        W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
        nout = W2.shape[1]
        T, t_max = int(z["T"]), float(z["t_max"])
        p = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32, asleep_drive=drive or "none")
        rasters, Y = test_rasters(z, a.n)
        correct = np.zeros(T)
        for S, y in zip(rasters, Y):
            h = run_gated(W1, S, p, shadow=False) if drive else run_ref(W1, S, p)
            o = run_ref(W2, h.spikes.astype(np.int64), p)
            correct += prefix_predict(o.spikes, o.U, nout) == y
        acc = correct / len(Y)
        res[name] = {"window_ms": [round((w + 1) * t_max * 1e3 / T, 3) for w in range(T)], "acc": acc.tolist()}
        print(name, {f"{(w + 1) * 3} ms": round(100 * acc[w], 2) for w in (9, 19, 32, 49, 66, 99)}, flush=True)
    res["n"] = a.n
    Path(a.out).parent.mkdir(parents=True, exist_ok=True)
    json.dump(res, open(a.out, "w"), indent=1)


if __name__ == "__main__":
    main()
