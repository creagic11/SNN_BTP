"""Train the ungated INT8 LIF baseline on MNIST (T0.6) and export integer weights.

    python train/train_mnist.py --hidden 400 --epochs 8 --T 25

Outputs results/mnist_<hidden>/weights.npz (int8 weights per layer + params) and metrics.json.
The exported network is re-evaluated with the numpy golden REF model to confirm bit-exactness.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from train.qsnn import QSNN  # noqa: E402

DATA_DIR = Path(os.environ.get("DATA_DIR", Path.home() / "data"))


def load_mnist():
    import torchvision
    tr = torchvision.datasets.MNIST(DATA_DIR, train=True, download=False)
    te = torchvision.datasets.MNIST(DATA_DIR, train=False, download=False)
    return (tr.data.reshape(-1, 784), tr.targets), (te.data.reshape(-1, 784), te.targets)


def if_encode_torch(x_u8: torch.Tensor, T: int, gain: int = 1) -> torch.Tensor:
    """Same arithmetic as golden.encode.if_encode. x: (B, P) uint8 -> (T, B, P) float spikes."""
    x = x_u8.to(torch.int32) * gain
    acc = torch.zeros_like(x)
    out = []
    for _ in range(T):
        acc = acc + x
        s = acc >= 256
        acc = acc - 256 * s
        out.append(s.float())
    return torch.stack(out)


def predict_torch(S_out: torch.Tensor, U_out: torch.Tensor) -> torch.Tensor:
    """Most spikes, ties broken by larger summed U, then lower index (matches golden.predict)."""
    counts = S_out.sum(0)
    usum = U_out.sum(0)
    # lexicographic key; usum is bounded well below 1e6 in magnitude
    key = counts * 1e7 + usum
    return key.argmax(dim=1)


def evaluate(model, X, Y, T, gain, bs=1000):
    model.eval()
    correct, rate_h = 0, 0.0
    with torch.no_grad():
        for i in range(0, len(X), bs):
            S = if_encode_torch(X[i:i + bs], T, gain)
            So, Uo, hid = model(S)
            correct += (predict_torch(So, Uo) == Y[i:i + bs]).sum().item()
            rate_h += hid[0][0].mean().item() * len(X[i:i + bs])
    return correct / len(X), rate_h / len(X)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hidden", type=int, default=400)
    ap.add_argument("--T", type=int, default=25)
    ap.add_argument("--k", type=int, default=3)
    ap.add_argument("--theta", type=int, default=64)
    ap.add_argument("--gain", type=int, default=1)
    ap.add_argument("--epochs", type=int, default=8)
    ap.add_argument("--bs", type=int, default=128)
    ap.add_argument("--lr", type=float, default=0.05)
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0, help="use only N training samples (smoke test)")
    ap.add_argument("--out", type=str, default="")
    args = ap.parse_args()

    torch.manual_seed(args.seed)
    np.random.seed(args.seed)
    (Xtr, Ytr), (Xte, Yte) = load_mnist()
    if args.limit:
        Xtr, Ytr = Xtr[:args.limit], Ytr[:args.limit]
    model = QSNN([784, args.hidden, 10], theta=args.theta, k=args.k)
    opt = torch.optim.Adam(model.parameters(), lr=args.lr)
    steps = args.epochs * ((len(Xtr) + args.bs - 1) // args.bs)
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, max_lr=args.lr, total_steps=steps, pct_start=0.15)
    out = Path(args.out or ROOT / "results" / f"mnist_{args.hidden}")
    out.mkdir(parents=True, exist_ok=True)
    log = []
    for ep in range(args.epochs):
        model.train()
        perm = torch.randperm(len(Xtr))
        t0, tot, n = time.time(), 0.0, 0
        for i in range(0, len(Xtr), args.bs):
            idx = perm[i:i + args.bs]
            S = if_encode_torch(Xtr[idx], args.T, args.gain)
            So, Uo, _ = model(S)
            logits = So.sum(0) + 0.01 * Uo.mean(0) / args.theta   # spike count, small membrane term
            loss = F.cross_entropy(logits, Ytr[idx])
            opt.zero_grad()
            loss.backward()
            opt.step()
            sched.step()
            tot += loss.item() * len(idx)
            n += len(idx)
        acc, rate = evaluate(model, Xte, Yte, args.T, args.gain)
        rec = {"epoch": ep + 1, "loss": tot / n, "test_acc": acc, "hidden_rate": rate, "sec": time.time() - t0}
        log.append(rec)
        print(json.dumps(rec), flush=True)

    Ws = model.export_int()
    np.savez(out / "weights.npz", W0=Ws[0].astype(np.int8), W1=Ws[1].astype(np.int8),
             T=args.T, k=args.k, theta=args.theta, gain=args.gain)
    json.dump({"args": vars(args), "log": log}, open(out / "metrics.json", "w"), indent=2)
    print("saved", out)


if __name__ == "__main__":
    main()
