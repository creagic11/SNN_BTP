"""T1.5: compare HUSH with SITRA-style and Early-style heuristic gates at equal weight-read reduction.

All gates act on 8-neuron sub-blocks with the same dropping / mean-field semantics, so only the
*predictor* differs:

  HUSH   : envelope L(max V) + relu(sum_j s_j P_jc) >= theta           (provably no false negatives)
  SITRA  : per neuron, count of active inputs whose weight is negative (weight MSB = 1) is below tau
           -> predicted non-silent; sub-block awake if any neuron is. State-free, like SITRA.
  EARLY  : per neuron, L(V) + sum of the K largest-magnitude active weights >= V_sth; sub-block
           awake if any neuron is (importance-ordered partial sum, like Early's early exit).

The heuristic thresholds are calibrated by bisection so their column-read fraction matches HUSH's.

11 Nov 2026 (review: "charge the predictors' own reads"): every gate is also charged its predictor's memory
traffic, in bytes per (sub-block, active input), next to the 8-byte weight column read when awake:
  HUSH  : P and Q bytes (2 B)                                   -> 2 + 8*awake
  SITRA : the 8 sign bits of the sub-block (1 B)                -> 1 + 8*awake
  EARLY : the top-K weight columns per sub-block, read before the decision (8 B each, a lower bound: the 8
          neurons' top-K sets may differ); when awake only the remaining columns are read
                                                                -> 8*min(K, n) + 8*awake*max(0, n - K) per step
With --match traffic the heuristics are calibrated to HUSH's total traffic instead of its column reads.
Reported: accuracy, read fraction, and suppressed spikes = neurons in gated sub-blocks whose
ungated update from the same state would have reached theta (false negatives).

    python scripts/heuristic_gates.py results/nmnist_T100_mf_e05_d025/weights.npz --n 200 --asleep_drive mean
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, clip, leak, mean_table, predict, proxy_table, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402


def run_layer(W, S, p, kind, thr, asleep_drive, K=8):
    T = S.shape[0]
    N = W.shape[1]
    C = N // p.b_env
    P = proxy_table(W, p.b_env)
    Q = mean_table(W, p.b_env) if asleep_drive == "mean" else None
    neg = (W < 0).astype(np.int64)
    V = np.zeros(N, np.int64)
    spikes = np.zeros((T, N), np.uint8)
    reads = fn = 0
    traffic = 0
    for t in range(T):
        s = S[t].astype(np.int64)
        LV = leak(V, p.k)
        drive = s @ W
        U_full = clip(LV + drive, p)
        if kind == "hush":
            R = V.reshape(C, p.b_env).max(1)
            g = clip(leak(R, p.k) + np.maximum(s @ P, 0), p) >= p.theta
        elif kind == "sitra":
            g = ((s @ neg) < thr).reshape(C, p.b_env).any(1) & (s.sum() > 0)
        elif kind == "early":
            act = np.flatnonzero(s)
            if act.size:
                Wa = W[act]                                            # (n, N)
                kk = min(K, act.size)
                idx = np.argpartition(-np.abs(Wa), kk - 1, axis=0)[:kk]
                part = np.take_along_axis(Wa, idx, axis=0).sum(0)
            else:
                part = np.zeros(N, np.int64)
            g = (LV + part >= thr).reshape(C, p.b_env).any(1)
        gn = np.repeat(g, p.b_env)
        U_sleep = LV if Q is None else clip(LV + np.repeat(s @ Q, p.b_env), p)
        U = np.where(gn, U_full, U_sleep)
        sp = (U >= p.theta) & gn
        fn += int(((~gn) & (U_full >= p.theta)).sum())
        V = U - p.theta * sp
        spikes[t] = sp
        n = int(s.sum())
        reads += int(g.sum()) * n
        if kind == "hush":
            traffic += C * 2 * n + 8 * int(g.sum()) * n
        elif kind == "sitra":
            traffic += C * 1 * n + 8 * int(g.sum()) * n
        else:
            traffic += C * 8 * min(K, n) + 8 * int(g.sum()) * max(0, n - K)
    return spikes, reads, fn, traffic


def evaluate(Ws, rasters, Y, p, po, kind, thr, asleep_drive, n_real, match="reads"):
    acc = reads = fn = base = traffic = 0
    for S, y in zip(rasters, Y):
        x = S
        for li in range(len(Ws) - 1):
            x2, r, f, tr = run_layer(Ws[li], x, p, kind, thr, asleep_drive)
            reads += r
            fn += f
            traffic += tr
            base += (Ws[li].shape[1] // p.b_env) * int(x.sum())
            x = x2
        acc += predict(run_ref(Ws[-1], x, po)) == y
    rf, tf = reads / max(1, base), traffic / max(1, 8 * base)   # traffic relative to BASE's 8 B per column
    return acc / len(Y), (rf if match == "reads" else tf), fn, rf, tf


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n", type=int, default=200)
    ap.add_argument("--asleep_drive", default="none")
    ap.add_argument("--target", type=float, default=0.0, help="read fraction to calibrate heuristics to (default: HUSH's)")
    ap.add_argument("--out", default="")
    ap.add_argument("--match", default="reads", choices=["reads", "traffic"])
    ap.add_argument("--ncal", type=int, default=40)
    a = ap.parse_args()
    z = np.load(a.weights)
    Ws = [z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
    k, theta = int(z["k"]), int(z["theta"])
    n_real = []
    for li in range(len(Ws) - 1):
        Ws[li], Ws[li + 1], nr = pad_hidden(Ws[li], Ws[li + 1], 32)
        n_real.append(nr)
    rasters, Y = test_rasters(z, a.n)
    p = LIFParams(k=k, theta=theta, b_env=8, b_blk=32)
    po = LIFParams(k=k, theta=theta, b_env=Ws[-1].shape[1], b_blk=Ws[-1].shape[1])
    res = {}
    acc, m, fn, rf, tf = evaluate(Ws, rasters, Y, p, po, "hush", None, a.asleep_drive, n_real, a.match)
    res["HUSH"] = {"acc": acc, "read_frac": rf, "traffic_frac": tf, "suppressed_spikes": fn, "thr": None}
    rf = m
    print("HUSH", res["HUSH"], flush=True)
    target = a.target or rf
    for kind, lo, hi in (("sitra", 0, 200), ("early", -2000, 2000)):
        # read fraction falls as the threshold moves: sitra -> smaller tau, early -> larger V_sth
        for _ in range(14):
            mid = (lo + hi) / 2
            _, r, _, _, _ = evaluate(Ws, rasters[:a.ncal], Y[:a.ncal], p, po, kind, mid, a.asleep_drive, n_real, a.match)
            if kind == "sitra":
                lo, hi = (lo, mid) if r > target else (mid, hi)
            else:
                lo, hi = (mid, hi) if r > target else (lo, mid)
        thr = (lo + hi) / 2
        acc, _, fn2, rf2, tf2 = evaluate(Ws, rasters, Y, p, po, kind, thr, a.asleep_drive, n_real, a.match)
        res[kind.upper()] = {"acc": acc, "read_frac": rf2, "traffic_frac": tf2, "suppressed_spikes": fn2, "thr": thr}
        print(kind.upper(), res[kind.upper()], flush=True)
    out = Path(a.out) if a.out else Path(a.weights).with_name("heuristic_gates.json")
    json.dump({"n": len(Y), "asleep_drive": a.asleep_drive, "match": a.match, "results": res}, open(out, "w"), indent=2)
    print("saved", out)


if __name__ == "__main__":
    main()
