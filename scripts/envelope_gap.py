"""Diagnose why the envelope is loose: split E_c - max_i U_i into its two sources.

For each awake decision of the GATED model (sub-block c, timestep t):
    E_c - max_i U_i  =  [L(R_c) - max_i L(V_i)]          state gap  (bound on carried potential)
                      + [max(0,D_c) - max_i sum_j W_ij]  drive gap  (proxy max vs actual weights)
(up to the clip). Reports the mean of each, plus the fraction of sub-block-steps where the envelope
wakes a block that the oracle would have kept asleep ("false wakes"), split by which gap alone
would already have pushed E over theta.

    python scripts/envelope_gap.py results/mnist_400/weights.npz --n 300 [--perm perm.npy] [--benv 8]
"""

import argparse
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.encode import if_encode  # noqa: E402
from golden.hush import LIFParams, leak, proxy_table  # noqa: E402
from scripts.measure_rho import load_test, pad_hidden  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n", type=int, default=300)
    ap.add_argument("--perm", default="")
    ap.add_argument("--benv", type=int, default=8)
    a = ap.parse_args()
    z = np.load(a.weights)
    W0, W1 = z["W0"].astype(np.int64), z["W1"].astype(np.int64)
    T, k, theta, gain = (int(z[x]) for x in ("T", "k", "theta", "gain"))
    if a.perm:
        pm = np.load(a.perm)
        W0, W1 = W0[:, pm], W1[pm]
    W0, W1, n_real = pad_hidden(W0, W1, 32)
    p = LIFParams(k=k, theta=theta, b_env=a.benv, b_blk=32)
    C = W0.shape[1] // a.benv
    real = n_real // a.benv
    P = proxy_table(W0, a.benv)
    X, _ = load_test("mnist")
    S_all = if_encode(X[:a.n], T, gain)
    sg, dg, cnt, false_wake, fw_state, fw_drive, awake, n_steps = 0.0, 0.0, 0, 0, 0, 0, 0, []
    for i in range(a.n):
        V = np.zeros(W0.shape[1], np.int64)
        R = np.zeros(C, np.int64)
        for t in range(T):
            s = S_all[i, t].astype(np.int64)
            n_steps.append(int(s.sum()))
            D = s @ P
            LR = leak(R, k)
            E = np.clip(LR + np.maximum(D, 0), p.vmin, p.vmax)
            g = E >= theta
            LV = leak(V, k)
            drive = s @ W0
            U_full = np.clip(LV + drive, p.vmin, p.vmax)
            oracle = (U_full >= theta).reshape(C, a.benv).any(1)
            LVc = LV.reshape(C, a.benv).max(1)
            drc = drive.reshape(C, a.benv).max(1)
            sgap = LR - LVc
            dgap = np.maximum(D, 0) - drc
            m = np.arange(C) < real
            sg += sgap[m].sum()
            dg += dgap[m].sum()
            cnt += m.sum()
            fw = g & ~oracle & m
            false_wake += fw.sum()
            awake += (g & m).sum()
            # would E cross theta from the state bound alone (with the exact drive)? or drive alone?
            fw_state += (fw & (LR + drc >= theta)).sum()
            fw_drive += (fw & (LVc + np.maximum(D, 0) >= theta)).sum()
            gn = np.repeat(g, a.benv)
            U = np.where(gn, U_full, LV)
            sp = (U >= theta) & gn
            V = U - theta * sp
            R = np.where(g, (V).reshape(C, a.benv).max(1), E)
    print(f"benv={a.benv} perm={'yes' if a.perm else 'no'}  mean active inputs/step={np.mean(n_steps):.1f}")
    print(f"mean state gap  L(R)-max L(V) = {sg / cnt:8.1f}   (theta = {theta})")
    print(f"mean drive gap  D-max sum W   = {dg / cnt:8.1f}")
    print(f"awake fraction (real sub-blocks) = {awake / cnt:.3f}; false wakes = {false_wake / cnt:.3f} of all decisions")
    print(f"  of false wakes: state bound alone suffices {fw_state / max(1, false_wake):.2f}, "
          f"drive bound alone suffices {fw_drive / max(1, false_wake):.2f}")


if __name__ == "__main__":
    main()
