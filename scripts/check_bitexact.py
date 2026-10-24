"""Check that the PyTorch integer-unit network and the numpy golden REF model agree bit for bit.

    python scripts/check_bitexact.py results/mnist_400/weights.npz --n 500
"""

import argparse
import sys
from pathlib import Path

import numpy as np
import torch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.encode import if_encode  # noqa: E402
from golden.hush import LIFParams, predict, run_ref  # noqa: E402
from train.qsnn import QSNN  # noqa: E402
from train.train_mnist import if_encode_torch, predict_torch  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n", type=int, default=500)
    a = ap.parse_args()
    z = np.load(a.weights)
    W0, W1 = z["W0"].astype(np.int64), z["W1"].astype(np.int64)
    T, k, theta, gain = (int(z[x]) for x in ("T", "k", "theta", "gain"))
    import torchvision
    te = torchvision.datasets.MNIST(Path.home() / "data", train=False, download=False)
    X = te.data.reshape(-1, 784)[:a.n]

    model = QSNN([W0.shape[0], W0.shape[1], W1.shape[1]], theta=theta, k=k)
    with torch.no_grad():
        model.layers[0].w.copy_(torch.tensor(W0, dtype=torch.float32))
        model.layers[1].w.copy_(torch.tensor(W1, dtype=torch.float32))
        S_t = if_encode_torch(X, T, gain)
        So, Uo, hid = model(S_t)
        pred_t = predict_torch(So, Uo).numpy()
    S_np = if_encode(X.numpy(), T, gain)
    assert np.array_equal(S_np.transpose(1, 0, 2), S_t.numpy().astype(np.uint8)), "encoder mismatch"

    pv = LIFParams(k=k, theta=theta, b_env=8, b_blk=8)
    po = LIFParams(k=k, theta=theta, b_env=W1.shape[1], b_blk=W1.shape[1])
    mism_spk, mism_pred, vmax = 0, 0, 0
    for i in range(a.n):
        h = run_ref(W0, S_np[i], LIFParams(k=k, theta=theta, b_env=W0.shape[1], b_blk=W0.shape[1]))
        o = run_ref(W1, h.spikes, po)
        mism_spk += int((h.spikes != hid[0][0][:, i].numpy().astype(np.uint8)).sum())
        mism_pred += int(predict(o) != pred_t[i])
        vmax = max(vmax, int(np.abs(h.U).max()), int(np.abs(o.U).max()))
    print(f"samples={a.n} hidden-spike mismatches={mism_spk} prediction mismatches={mism_pred} max|U|={vmax}")
    assert mism_spk == 0 and mism_pred == 0
    print("BIT-EXACT: PyTorch == golden REF")


if __name__ == "__main__":
    main()
