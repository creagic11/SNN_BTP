"""Bit-exact RTL check: generate memories, simulate hush_layer with Icarus, compare against golden.

    python rtl/sim/run_case.py --random --M 40 --N 64 --T 12 --gate 1 --mf 0 --seed 3
    python rtl/sim/run_case.py --weights results/nmnist_T100_mf_e05_d025/weights.npz --sample 0 --mf 1

Checks, for every timestep and block: output spikes and the written-back state equal golden
run_gated (GATE=1) / run_ref (GATE=0); and the performance counters equal the golden-derived counts.
"""

from __future__ import annotations

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, mean_table, proxy_table, run_gated, run_ref  # noqa: E402

RTL = ROOT / "rtl"


def hexrow(vals, bits):
    x = 0
    for i, v in enumerate(vals):
        x |= (int(v) & ((1 << bits) - 1)) << (bits * i)
    return f"{x:0{len(vals) * bits // 4}x}"


def write_mems(d: Path, W, S):
    M, N = W.shape
    G, C = N // 32, N // 8
    with open(d / "w.hex", "w") as f:
        for b in range(G):
            for j in range(M):
                f.write(hexrow(W[j, 32 * b:32 * b + 32], 8) + "\n")
    P, Q = proxy_table(W, 8), mean_table(W, 8)
    for name, A in (("p", P), ("q", Q)):
        with open(d / f"{name}.hex", "w") as f:
            for j in range(M):
                f.write(hexrow(A[j], 8) + "\n")
    ev, ts = [], [0]
    for t in range(S.shape[0]):
        idx = np.flatnonzero(S[t])
        ev += idx.tolist()
        ts.append(len(ev))
    with open(d / "ev.hex", "w") as f:
        for e in (ev or [0]):
            f.write(f"{e:04x}\n")
    with open(d / "ts.hex", "w") as f:
        for x in ts:
            f.write(f"{x:04x}\n")
    return max(1, len(ev))


def simulate(d: Path, M, N, T, k, theta, theta_h, gate, mf, nev):
    exe = d / "sim.vvp"
    params = dict(M=M, N=N, T=T, K=k, THETA=theta, THETA_H=theta_h, GATE=gate, MF=mf, NEV=nev)
    cmd = ["iverilog", "-g2012", "-o", str(exe), "-s", "tb_hush_layer"]
    for kname, v in params.items():
        cmd += ["-P", f"tb_hush_layer.{kname}={v}"]
    cmd += ["-P", 'tb_hush_layer.OUT_FILE="rtl_out.txt"',
            str(RTL / "hush_arith.sv"), str(RTL / "hush_layer.sv"), str(RTL / "tb_hush_layer.sv")]
    subprocess.run(cmd, check=True)
    r = subprocess.run(["vvp", "-n", str(exe)], cwd=d, capture_output=True, text=True)
    if "TIMEOUT" in r.stdout or r.returncode:
        print(r.stdout[-2000:], r.stderr[-2000:])
    return (d / "rtl_out.txt").read_text().splitlines()


def check(W, S, k, theta, gate, mf, theta_h=None, verbose=True):
    M, N = W.shape
    T = S.shape[0]
    th_h = theta if theta_h is None else theta_h
    p = LIFParams(k=k, theta=theta, theta_h=th_h, b_env=8, b_blk=32, asleep_drive="mean" if mf else "none")
    tr = run_gated(W, S, p, shadow=False) if gate else run_ref(W, S, LIFParams(k=k, theta=theta, b_env=8, b_blk=32))
    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        nev = write_mems(d, W, S)
        lines = simulate(d, M, N, T, k, theta, th_h, gate, mf, nev)
    G = N // 32
    rows = [l.split() for l in lines if l.startswith("S ")]
    assert len(rows) == T * G, f"expected {T * G} block write-backs, got {len(rows)}"
    mism = 0
    for _, ts, bs, spk, vhex in rows:
        t, b = int(ts), int(bs)
        sp = np.array([(int(spk, 16) >> l) & 1 for l in range(32)], np.uint8)
        vint = int(vhex, 16)
        v = np.array([((vint >> (16 * l)) & 0xFFFF) for l in range(32)], np.int64)
        v = np.where(v >= 1 << 15, v - (1 << 16), v)
        if not (np.array_equal(sp, tr.spikes[t, 32 * b:32 * b + 32]) and np.array_equal(v, tr.V[t, 32 * b:32 * b + 32])):
            mism += 1
    c = [l.split() for l in lines if l.startswith("C ")][0]
    cyc, colr, wordr, awk = map(int, c[1:])
    n = S.sum(axis=1).astype(np.int64)
    exp_word = int((tr.awake_blk.sum(axis=1) * n).sum())
    exp_col = int(sum(tr.awake_sub[t].reshape(G, 4)[tr.awake_blk[t]].sum() * n[t] for t in range(T)))
    exp_awk = int(tr.awake_sub.sum())
    ok = mism == 0 and wordr == exp_word and colr == exp_col and awk == exp_awk
    if verbose:
        print(f"M={M} N={N} T={T} gate={gate} mf={mf}: block mismatches={mism}/{T * G}, "
              f"word reads {wordr}/{exp_word}, col reads {colr}/{exp_col}, awake sub {awk}/{exp_awk}, cycles {cyc} "
              f"-> {'PASS' if ok else 'FAIL'}")
    return ok, cyc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--random", action="store_true")
    ap.add_argument("--weights", default="")
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--M", type=int, default=40)
    ap.add_argument("--N", type=int, default=64)
    ap.add_argument("--T", type=int, default=12)
    ap.add_argument("--k", type=int, default=3)
    ap.add_argument("--theta", type=int, default=64)
    ap.add_argument("--gate", type=int, default=1)
    ap.add_argument("--mf", type=int, default=0)
    ap.add_argument("--rate", type=float, default=0.2)
    ap.add_argument("--seed", type=int, default=0)
    a = ap.parse_args()
    if a.weights:
        from scripts.measure_rho import pad_hidden, test_rasters
        z = np.load(a.weights)
        W0, W1, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
        rasters, _ = test_rasters(z, a.sample + 1)
        ok, _ = check(W0, rasters[a.sample].astype(np.int64), int(z["k"]), int(z["theta"]), a.gate, a.mf)
    else:
        rng = np.random.default_rng(a.seed)
        W = rng.integers(-60, 61, size=(a.M, a.N))
        S = (rng.random((a.T, a.M)) < a.rate).astype(np.int64)
        ok, _ = check(W, S, a.k, a.theta, a.gate, a.mf)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
