"""T0.7 / T0.8: measure awake fractions (rho) of REF, ORACLE and HUSH gates on a trained network.

    python scripts/measure_rho.py results/mnist_400/weights.npz --n 2000 [--perm results/.../perm.npy]

Checks first that the golden REF model reproduces the PyTorch network bit for bit (accuracy and
hidden spikes), then runs the hidden layer with each gate and reports:

* rho_sub  : fraction of (sub-block, timestep) pairs awake, real sub-blocks only
* rho_blk  : fraction of (block, timestep) pairs awake (incl. the partially filled last block)
* rho_blk_w: work-weighted block awake fraction = HUSH cycles / BASE cycles for the PE pass
* speedup  : BASE PE cycles / HUSH cycles with the overlapped envelope, sum_t max(n_{t+1}, A_t n_t)
* acc      : accuracy of the whole network with that gate on the hidden layer
* eff      : envelope efficiency rho_ORACLE / rho (1.0 = as tight as any exact gate can be)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.encode import if_encode  # noqa: E402
from golden.hush import LIFParams, predict, run_gated, run_oracle, run_ref  # noqa: E402


def pad_hidden(W0, W1, b_blk):
    """Pad the hidden layer to a multiple of b_blk with dummy neurons that never fire."""
    M, N = W0.shape
    Np = -(-N // b_blk) * b_blk
    if Np == N:
        return W0, W1, N
    W0p = np.full((M, Np), -128, np.int64)
    W0p[:, :N] = W0
    W1p = np.zeros((Np, W1.shape[1]), np.int64)
    W1p[:N] = W1
    return W0p, W1p, N


def load_test(dataset):
    if dataset == "mnist":
        import torchvision
        te = torchvision.datasets.MNIST(Path.home() / "data", train=False, download=False)
        return te.data.reshape(-1, 784).numpy(), te.targets.numpy()
    raise ValueError(dataset)


def overlapped_cycles(n, A):
    """sum_t max(n_{t+1}, A_t * n_t): envelope of step t+1 overlaps the PE pass of step t."""
    n_next = np.append(n[1:], 0)
    return int(np.maximum(n_next, A * n).sum() + n[0])  # + first envelope pass, not overlapped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--dataset", default="mnist")
    ap.add_argument("--n", type=int, default=2000)
    ap.add_argument("--perm", default="", help="hidden-neuron permutation (.npy) from clustering")
    ap.add_argument("--benv", type=int, nargs="+", default=[4, 8, 32])
    ap.add_argument("--out", default="")
    args = ap.parse_args()

    z = np.load(args.weights)
    W0, W1 = z["W0"].astype(np.int64), z["W1"].astype(np.int64)
    T, k, theta, gain = int(z["T"]), int(z["k"]), int(z["theta"]), int(z["gain"])
    if args.perm:
        perm = np.load(args.perm)
        W0, W1 = W0[:, perm], W1[perm]
    W0, W1, n_real = pad_hidden(W0, W1, 32)
    N = W0.shape[1]
    X, Y = load_test(args.dataset)
    X, Y = X[:args.n], Y[:args.n]
    S_all = if_encode(X, T, gain)            # (n, T, M)

    p_out = LIFParams(k=k, theta=theta, b_env=W1.shape[1], b_blk=W1.shape[1])
    modes = [("REF", None, None)]
    modes += [("ORACLE", "oracle", 8)]
    modes += [(f"HUSH-{b}" if b == 32 else f"HUSH-{b}/32", "gated", b) for b in args.benv]
    agg = {}
    for name, kind, benv in modes:
        p = LIFParams(k=k, theta=theta, b_env=benv or 8, b_blk=32)
        real_sub = n_real // p.b_env  # sub-blocks fully made of real neurons come first
        correct, aw_sub, aw_blk, base_cyc, hush_cyc, sub_tot, blk_tot, in_spk, hid_spk = 0, 0, 0, 0, 0, 0, 0, 0, 0
        for i in range(args.n):
            S = S_all[i]
            if kind is None:
                h = run_ref(W0, S, p)
            elif kind == "oracle":
                h = run_oracle(W0, S, p)
            else:
                h = run_gated(W0, S, p, shadow=False)
            o = run_ref(W1, h.spikes, p_out)
            correct += predict(o) == Y[i]
            n = h.n_active.astype(np.int64)
            A = h.awake_blk.sum(axis=1)
            G = h.awake_blk.shape[1]
            base_cyc += int((G * n).sum())
            hush_cyc += overlapped_cycles(n, A) if kind else int((G * n).sum())
            aw_sub += int(h.awake_sub[:, :real_sub].sum())
            sub_tot += T * real_sub
            aw_blk += int(A.sum())
            blk_tot += T * G
            in_spk += int(n.sum())
            hid_spk += int(h.spikes[:, :n_real].sum())
        agg[name] = {
            "acc": correct / args.n,
            "rho_sub": aw_sub / sub_tot,
            "rho_blk": aw_blk / blk_tot,
            "speedup_pe": base_cyc / max(1, hush_cyc),
            "in_rate": in_spk / (args.n * T * W0.shape[0]),
            "hid_rate": hid_spk / (args.n * T * n_real),
        }
        print(name, json.dumps({k2: round(v, 4) for k2, v in agg[name].items()}), flush=True)
    o_rho = agg["ORACLE"]["rho_sub"]
    for name in agg:
        if name.startswith("HUSH"):
            agg[name]["eff_vs_oracle8"] = o_rho / max(1e-9, agg[name]["rho_sub"])
    out = Path(args.out) if args.out else Path(args.weights).with_name(
        "rho_" + ("clustered" if args.perm else "unclustered") + ".json")
    json.dump({"n": args.n, "T": T, "k": k, "theta": theta, "modes": agg}, open(out, "w"), indent=2)
    print("saved", out)


if __name__ == "__main__":
    main()
