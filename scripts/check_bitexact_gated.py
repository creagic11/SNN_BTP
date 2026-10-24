"""Check that gate-in-the-loop PyTorch training computes exactly golden.hush.run_gated (resync=True).

    python scripts/check_bitexact_gated.py results/shd_T250_gated/weights.npz --benv 8 --n 200
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import torch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, predict, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import test_rasters  # noqa: E402
from train.qsnn import QSNN  # noqa: E402
from train.train_mnist import predict_torch  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--benv", type=int, default=8)
    ap.add_argument("--n", type=int, default=200)
    ap.add_argument("--asleep_drive", default="none")
    a = ap.parse_args()
    z = np.load(a.weights)
    Ws = [z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
    T, k, theta = int(z["T"]), int(z["k"]), int(z["theta"])
    sizes = [Ws[0].shape[0]] + [W.shape[1] for W in Ws]
    assert all(s % 32 == 0 for s in sizes[1:-1]), "hidden sizes must be multiples of 32 for this check"
    model = QSNN(sizes, theta=theta, k=k)
    with torch.no_grad():
        for l, W in zip(model.layers, Ws):
            l.w.copy_(torch.tensor(W, dtype=torch.float32))
    for l in model.layers[:-1]:
        l.gate_benv = a.benv
        l.asleep_drive = a.asleep_drive
    rasters, Y = test_rasters(z, a.n)
    S = torch.tensor(np.stack(rasters)).float().transpose(0, 1)
    with torch.no_grad():
        So, Uo, hid = model(S)
    pred_t = predict_torch(So, Uo).numpy()
    p = LIFParams(k=k, theta=theta, b_env=a.benv, b_blk=32, asleep_drive=a.asleep_drive)
    po = LIFParams(k=k, theta=theta, b_env=Ws[-1].shape[1], b_blk=Ws[-1].shape[1])
    spk_mis = pred_mis = 0
    for i, r in enumerate(rasters):
        x = r
        for li, W in enumerate(Ws[:-1]):
            h = run_gated(W, x, p, shadow=False)
            spk_mis += int((h.spikes != hid[li][0][:, i].numpy().astype(np.uint8)).sum())
            x = h.spikes
        o = run_ref(Ws[-1], x, po)
        pred_mis += int(predict(o) != pred_t[i])
    print(f"samples={a.n} gated hidden-spike mismatches={spk_mis} prediction mismatches={pred_mis}")
    assert spk_mis == 0 and pred_mis == 0
    print("BIT-EXACT: gated PyTorch == golden GATED")


if __name__ == "__main__":
    main()
