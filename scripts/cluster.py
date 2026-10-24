"""T0.8: permute hidden neurons into 8-neuron sub-blocks (then 32-neuron blocks) to tighten the envelope.

Permuting neurons changes no weight value, so accuracy is unchanged; only the grouping changes.

Two grouping criteria:
  weight : balanced k-means on input-rate-weighted weight columns, so neurons in a sub-block have
           similar weights and the per-input max P is close to each neuron's own weight.
  coact  : balanced k-means on each neuron's firing pattern over samples and timesteps, so a
           sub-block's neurons are quiet at the same time (the v1 co-inactivity idea).
  mixed  : concatenation of both (each normalised).

    python scripts/cluster.py results/mnist_400/weights.npz --method weight
writes results/mnist_400/perm_<method>.npy (new order of the real hidden neurons).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from scipy.optimize import linear_sum_assignment

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.encode import if_encode  # noqa: E402
from golden.hush import LIFParams, run_ref  # noqa: E402


def balanced_kmeans(F: np.ndarray, size: int, iters: int = 20, seed: int = 0) -> np.ndarray:
    """Partition rows of F into groups of exactly ``size`` (N must be divisible). Returns labels."""
    N = F.shape[0]
    C = N // size
    rng = np.random.default_rng(seed)
    centers = F[rng.choice(N, C, replace=False)]
    labels = None
    for _ in range(iters):
        d = (F ** 2).sum(1)[:, None] - 2 * F @ centers.T + (centers ** 2).sum(1)[None, :]   # (N, C)
        cost = np.repeat(d, size, axis=1)                               # each center has `size` slots
        r, c = linear_sum_assignment(cost)
        new = np.empty(N, int)
        new[r] = c // size
        if labels is not None and np.array_equal(new, labels):
            break
        labels = new
        centers = np.stack([F[labels == g].mean(0) for g in range(C)])
    return labels


def group_order(labels: np.ndarray, F: np.ndarray, per_block: int) -> np.ndarray:
    """Order sub-blocks so that similar sub-blocks share a 32-neuron block, then flatten to neurons."""
    C = labels.max() + 1
    cent = np.stack([F[labels == g].mean(0) for g in range(C)])
    if C % per_block == 0:
        blk = balanced_kmeans(cent, per_block)
        sub_order = np.argsort(blk, kind="stable")
    else:
        sub_order = np.arange(C)
    return np.concatenate([np.flatnonzero(labels == g) for g in sub_order])


def coact_features(W0, X, T, k, theta, gain, n=300):
    S_all = if_encode(X[:n], T, gain)
    p = LIFParams(k=k, theta=theta, b_env=W0.shape[1], b_blk=W0.shape[1])
    rows = [run_ref(W0, S_all[i], p).spikes.astype(np.float32) for i in range(n)]
    return np.concatenate(rows, axis=0).T                              # (N, n*T)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--method", choices=["weight", "coact", "mixed"], default="weight")
    ap.add_argument("--size", type=int, default=8)
    a = ap.parse_args()
    z = np.load(a.weights)
    W0 = z["W0"].astype(np.int64)
    T, k, theta, gain = (int(z[x]) for x in ("T", "k", "theta", "gain"))
    import torchvision
    tr = torchvision.datasets.MNIST(Path.home() / "data", train=True, download=False)
    X = tr.data.reshape(-1, 784).numpy()
    rate = if_encode(X[:2000], T, gain).mean(axis=(0, 1))              # input firing probability per pixel
    Fw = (W0 * rate[:, None]).T.astype(np.float64)                     # (N, M)
    Fw /= np.linalg.norm(Fw) / np.sqrt(len(Fw)) + 1e-9
    if a.method == "weight":
        F = Fw
    else:
        Fc = coact_features(W0, X, T, k, theta, gain)
        Fc /= np.linalg.norm(Fc) / np.sqrt(len(Fc)) + 1e-9
        F = Fc if a.method == "coact" else np.concatenate([Fw, Fc], axis=1)
    N = F.shape[0]
    assert N % a.size == 0, "hidden size must be a multiple of the sub-block size"
    labels = balanced_kmeans(F, a.size)
    perm = group_order(labels, F, 32 // a.size)
    out = Path(a.weights).with_name(f"perm_{a.method}.npy")
    np.save(out, perm)
    print("saved", out)


if __name__ == "__main__":
    main()
