"""A9.2: bit-exact check of hush_net (hidden layer -> output layer -> class) against the golden model.

    python rtl/sim/run_net.py --random --seed 3                 # small random network
    python rtl/sim/run_net.py --weights results/nmnist_T100_mf_e05_d025_ep12/weights.npz --mf 1 --n 50

Checks per inference: every hidden-layer block result (spikes + state) = golden run_gated / run_ref, every
output-layer result = golden run_ref on the hidden spikes, class = golden predict. Prints cycles start -> class.
The simulator is compiled once per parameter set and rerun per sample (memories via $readmemh in the run dir).
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from golden.hush import LIFParams, LayerTrace, predict, run_gated, run_ref  # noqa: E402
from run_case import write_mems  # noqa: E402
from net_cycle_model import net_cycles  # noqa: E402

RTL = ROOT / "rtl"


def compile_net(d: Path, **params) -> Path:
    exe = d / "net.vvp"
    cmd = ["iverilog", "-g2012", "-o", str(exe), "-s", "tb_hush_net"]
    for k, v in params.items():
        cmd += ["-P", f"tb_hush_net.{k}={int(v)}"]
    cmd += [str(RTL / "hush_arith.sv"), str(RTL / "hush_layer.sv"), str(RTL / "hush_net.sv"), str(RTL / "tb_hush_net.sv")]
    c = subprocess.run(cmd, capture_output=True, text=True)
    if c.returncode or "error" in c.stderr.lower():
        raise RuntimeError(f"iverilog failed: {c.stderr}")
    return exe


def write_net_mems(d: Path, W1, Wo, S):
    nev = write_mems(d, W1, S)                       # L1: w0..w3, p, q, ev, ts2
    t2 = d / "l2"
    t2.mkdir(exist_ok=True)
    write_mems(t2, Wo, np.zeros((1, Wo.shape[0]), np.int64))
    for s in range(4):
        shutil.copy(t2 / f"w{s}.hex", d / f"o{s}.hex")
    return nev


def parse_words(spk, vhex):
    sp = np.array([(int(spk, 16) >> l) & 1 for l in range(32)], np.uint8)
    vint = int(vhex, 16)
    v = np.array([((vint >> (16 * l)) & 0xFFFF) for l in range(32)], np.int64)
    return sp, np.where(v >= 1 << 15, v - (1 << 16), v)


def golden(W1, Wo, S, k, theta, gate, mf, nout):
    pg = LIFParams(k=k, theta=theta, b_env=8, b_blk=32, asleep_drive="mean" if mf else "none")
    pr = LIFParams(k=k, theta=theta, b_env=8, b_blk=32)
    h = run_gated(W1, S, pg, shadow=False) if gate else run_ref(W1, S, pr)
    o = run_ref(Wo, h.spikes.astype(np.int64), pr)
    oc = LayerTrace(spikes=o.spikes[:, :nout], V=o.V[:, :nout], U=o.U[:, :nout],
                    awake_sub=o.awake_sub, awake_blk=o.awake_blk, n_active=o.n_active)
    return h, o, predict(oc)


def run_one(exe: Path, d: Path, W1, Wo, S, k, theta, gate, mf, nout):
    write_net_mems(d, W1, Wo, S)
    r = subprocess.run(["vvp", "-n", str(exe)], cwd=d, capture_output=True, text=True)
    if "TIMEOUT" in r.stdout or r.returncode:
        raise RuntimeError(r.stdout[-1500:] + r.stderr[-1500:])
    lines = (d / "net_out.txt").read_text().splitlines()
    h, o, cls = golden(W1, Wo, S, k, theta, gate, mf, nout)
    T, G1 = S.shape[0], W1.shape[1] // 32
    A = [l.split() for l in lines if l.startswith("A ")]
    B = [l.split() for l in lines if l.startswith("B ")]
    R = [l.split() for l in lines if l.startswith("R ")][0]
    mis1 = mis2 = 0
    for _, ts, bs, spk, vh in A:
        t, b = int(ts), int(bs)
        sp, v = parse_words(spk, vh)
        mis1 += not (np.array_equal(sp, h.spikes[t, 32 * b:32 * b + 32]) and np.array_equal(v, h.V[t, 32 * b:32 * b + 32]))
    for _, ts, spk, vh in B:
        t = int(ts)
        sp, v = parse_words(spk, vh)
        mis2 += not (np.array_equal(sp, o.spikes[t, :32]) and np.array_equal(v, o.V[t, :32]))
    res = dict(rows1=len(A), exp1=T * G1, mis1=mis1, rows2=len(B), exp2=T, mis2=mis2,
               cls=int(R[1]), cls_gold=int(cls), cycles=int(R[2]), l1_cycles=int(R[3]), fifo_peak=int(R[5]),
               hid_spikes=int(h.spikes.sum()))
    mc, mpeak, _ = net_cycles(S.sum(1).astype(np.int64), h.awake_blk, bool(gate or mf), h.spikes.astype(np.int64), nout)
    res.update(model_cycles=int(mc), model_peak=int(mpeak), cyc_ok=int(mc) == res["cycles"] and int(mpeak) == res["fifo_peak"])
    res["ok"] = (mis1 == 0 and mis2 == 0 and len(A) == T * G1 and len(B) == T and res["cls"] == res["cls_gold"])
    return res


def pad_out(W, n_out):
    M, N = W.shape
    Wp = np.full((M, 32), -128, np.int64)
    Wp[:, :N] = W
    return Wp


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--random", action="store_true")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--n", type=int, default=1)
    ap.add_argument("--weights", default="")
    ap.add_argument("--mf", type=int, default=1)
    ap.add_argument("--gate", type=int, default=1)
    ap.add_argument("--out", default="")
    ap.add_argument("--fifo", type=int, default=0, help="FIFO depth (random mode: 0 = random 8 or 32)")
    a = ap.parse_args()
    results = []
    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        if a.weights:
            from scripts.measure_rho import pad_hidden, test_rasters
            z = np.load(a.weights)
            W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
            nout = W2.shape[1]
            Wo = pad_out(W2, nout)
            k, theta, T = int(z["k"]), int(z["theta"]), int(z["T"])
            rasters, Y = test_rasters(z, a.n)
            nev = max(1, max(int(S.sum()) for S in rasters))
            exe = compile_net(d, M1=W1.shape[0], N1=W1.shape[1], N2=32, NOUT=nout, T=T, K=k, THETA=theta,
                              THETA_H=theta, GATE=a.gate, MF=a.mf, NEV1=nev, NEV2=4096, FIFO_D=32)
            for i, S in enumerate(rasters):
                r = run_one(exe, d, W1, Wo, S.astype(np.int64), k, theta, a.gate, a.mf, nout)
                r["label"] = int(Y[i])
                results.append(r)
                print(i, json.dumps(r), flush=True)
        else:
            rng = np.random.default_rng(a.seed)
            M1, N1, T, k, theta = int(rng.integers(20, 90)), 32 * int(rng.integers(1, 4)), int(rng.integers(2, 16)), \
                int(rng.integers(2, 5)), int(rng.integers(20, 120))
            gate, mf = int(rng.integers(0, 2)), int(rng.integers(0, 2))
            W1 = np.clip(rng.integers(-60, 61, size=(M1, N1)) + int(rng.integers(-20, 15)), -128, 127)
            nout = int(rng.integers(2, 11))
            Wo = pad_out(rng.integers(-50, 70, size=(N1, nout)), nout)
            S = (rng.random((T, M1)) < float(rng.choice([0.05, 0.2, 0.5]))).astype(np.int64)
            exe = compile_net(d, M1=M1, N1=N1, N2=32, NOUT=nout, T=T, K=k, THETA=theta, THETA_H=theta,
                              GATE=gate, MF=mf, NEV1=max(1, int(S.sum())), NEV2=4096, FIFO_D=a.fifo or int(rng.choice([8, 32])))
            r = run_one(exe, d, W1, Wo, S, k, theta, gate, mf, nout)
            r.update(seed=a.seed, M1=M1, N1=N1, T=T, gate=gate, mf=mf)
            results.append(r)
            print(json.dumps(r))
    ok = all(r["ok"] for r in results)
    print(f"{sum(r['ok'] for r in results)}/{len(results)} PASS")
    if a.out:
        Path(a.out).write_text(json.dumps(results, indent=1))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
