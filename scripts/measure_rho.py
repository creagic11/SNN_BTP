"""T0.7 / T0.9: awake fractions (rho), accuracy and cycle speedup of REF, ORACLE and HUSH gates.

    python scripts/measure_rho.py results/shd_T250/weights.npz --n 500 [--perm perm.npy]

Gates applied to every hidden layer (the output layer is always ungated). Reported per mode:
  acc       : accuracy of the whole network with that gate
  rho_sub   : awake fraction of (sub-block, timestep), real sub-blocks only
  rho_blk   : awake fraction of (block, timestep), incl. a partially filled last block
  speedup   : BASE cycles / HUSH cycles for the hidden layer(s), cycle model:
                BASE = sum_t G*(n_t + 1)                         (load+leak+threshold per block, n_t weight words)
                HUSH = sum_t max(n_{t+1}, A_t*(n_t + 1), G)      (envelope of t+1 | PE pass | leak sweep, overlapped)
  read_frac : weight-BRAM column reads relative to BASE (sub-block gating also disables columns)
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, predict, run_gated, run_oracle, run_ref  # noqa: E402


def pad_hidden(W_in, W_out, b_blk):
    """Pad a hidden layer to a multiple of b_blk with dummy neurons that never fire."""
    M, N = W_in.shape
    Np = -(-N // b_blk) * b_blk
    if Np == N:
        return W_in, W_out, N
    Wi = np.full((M, Np), -128, np.int64)
    Wi[:, :N] = W_in
    Wo = np.zeros((Np, W_out.shape[1]), np.int64)
    Wo[:N] = W_out
    return Wi, Wo, N


def load_test(dataset):
    """Back-compat helper for MNIST arrays."""
    from golden.datasets import mnist_arrays
    return mnist_arrays(False)


def test_rasters(z, n):
    ds = str(z["dataset"]) if "dataset" in z else "mnist"
    T, gain = int(z["T"]), int(z["gain"])
    if ds == "mnist":
        from golden.datasets import mnist_spikes
        S, Y = mnist_spikes(False, T, gain, n)
        return list(S), Y
    if ds == "shd":
        from golden.datasets import SHD
        d = SHD(False, float(z["t_max"]))
        idx = np.random.default_rng(0).permutation(len(d))[:n]
        return [d.raster(i, T) for i in idx], d.labels[idx]
    if ds == "nmnist":
        from golden.datasets import NMNIST
        d = NMNIST(False, int(float(z["t_max"]) * 1e6))
        idx = np.random.default_rng(0).permutation(len(d))[:n]
        rs = [d.raster(i, T) for i in idx]
        return [r for r, _ in rs], np.array([y for _, y in rs])
    raise ValueError(ds)


def cycles(n, A, G):
    base = int((G * (n + 1)).sum())
    n_next = np.append(n[1:], 0)
    hush = int(np.maximum(np.maximum(n_next, A * (n + 1)), G).sum() + n[0])
    return base, hush


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n", type=int, default=500)
    ap.add_argument("--perm", default="", help="permutation (.npy) of the first hidden layer")
    ap.add_argument("--benv", type=int, nargs="+", default=[8])
    ap.add_argument("--asleep_drive", default="none", choices=["none", "mean", "both"])
    ap.add_argument("--carried", action="store_true", help="also run the v1 carried-bound envelope")
    ap.add_argument("--theta_h", type=int, nargs="*", default=[], help="extra predictive-mode gate thresholds")
    ap.add_argument("--out", default="")
    a = ap.parse_args()

    z = np.load(a.weights)
    Ws = [z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
    T, k, theta = int(z["T"]), int(z["k"]), int(z["theta"])
    if a.perm:
        pm = np.load(a.perm)
        Ws[0], Ws[1] = Ws[0][:, pm], Ws[1][pm]
    n_real = []
    for li in range(len(Ws) - 1):
        Ws[li], Ws[li + 1], nr = pad_hidden(Ws[li], Ws[li + 1], 32)
        n_real.append(nr)
    rasters, Y = test_rasters(z, a.n)

    modes = [("REF", "ref", 8, True, None), ("ORACLE-8", "oracle", 8, True, None)]
    drives = ["none", "mean"] if a.asleep_drive == "both" else [a.asleep_drive]
    for b in a.benv:
        for dr in drives:
            modes.append((f"HUSH-{b}" + ("" if b == 32 else "/32") + ("-mf" if dr == "mean" else ""), "gated", b, True, None))
        if a.carried:
            modes.append((f"HUSH-{b}-carried", "gated", b, False, None))
    for th in a.theta_h:
        modes.append((f"HUSH-8/32 th_h={th}", "gated", 8, True, th))
    p_out = LIFParams(k=k, theta=theta, b_env=Ws[-1].shape[1], b_blk=Ws[-1].shape[1])
    res = {}
    for name, kind, benv, resync, th in modes:
        p = LIFParams(k=k, theta=theta, b_env=benv, b_blk=32, resync=resync, theta_h=th,
                      asleep_drive="mean" if name.endswith("-mf") else "none")
        acc = 0
        aw_sub = sub_tot = aw_blk = blk_tot = base = hush = reads = in_spk = hid_spk = hid_tot = 0
        for S, y in zip(rasters, Y):
            for li in range(len(Ws) - 1):
                fn = {"ref": run_ref, "oracle": run_oracle}.get(kind)
                h = fn(Ws[li], S, p) if fn else run_gated(Ws[li], S, p, shadow=False)
                n = h.n_active.astype(np.int64)
                G = h.awake_blk.shape[1]
                A = h.awake_blk.sum(axis=1)
                b, hc = cycles(n, A, G)
                base += b
                hush += hc if kind != "ref" else b
                real_sub = n_real[li] // benv
                aw_sub += int(h.awake_sub[:, :real_sub].sum())
                sub_tot += T * real_sub
                aw_blk += int(A.sum())
                blk_tot += T * G
                reads += int((h.awake_sub.sum(axis=1) * n).sum()) * benv // 8
                if li == 0:
                    in_spk += int(n.sum())
                hid_spk += int(h.spikes[:, :n_real[li]].sum())
                hid_tot += T * n_real[li]
                S = h.spikes
            o = run_ref(Ws[-1], S, p_out)
            acc += predict(o) == y
        res[name] = {
            "acc": acc / len(Y), "rho_sub": aw_sub / sub_tot, "rho_blk": aw_blk / blk_tot,
            "speedup": base / max(1, hush), "in_per_step": in_spk / (len(Y) * T),
            "hid_rate": hid_spk / hid_tot, "col_reads": reads,
        }
    ref_reads = res["REF"]["col_reads"]
    for name in res:
        res[name]["read_frac"] = res[name]["col_reads"] / max(1, ref_reads)
        print(f"{name:22s}", json.dumps({k2: round(v, 4) if isinstance(v, float) else v for k2, v in res[name].items()}), flush=True)
    out = Path(a.out) if a.out else Path(a.weights).with_name("rho_" + ("clustered" if a.perm else "unclustered") + ".json")
    json.dump({"n": len(Y), "T": T, "k": k, "theta": theta, "modes": res}, open(out, "w"), indent=2)
    print("saved", out)


if __name__ == "__main__":
    main()
