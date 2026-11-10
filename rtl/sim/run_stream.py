"""A9.3/A9.4: hush_net in STREAM mode fed with raw N-MNIST events at a chosen replay speed.

    python rtl/sim/run_stream.py --weights results/nmnist_T100_mf_e05_d025_ep12/weights.npz --mf 1 --n 5 --speed 1
    python rtl/sim/run_stream.py --weights ... --gate 0 --mf 0 --n 20 --speed 1000

speed = 1: events presented at their true sensor times (100 MHz clock: 1 us = 100 cycles); speed s > 1: time
compressed s times. At most one item per cycle (an item that would collide waits one cycle). End-of-window markers
at (w+1) * window_us. Checks: no drops; every hidden/output-layer result and the class = golden on the 0/1
raster (same as the batch model). Reports per-window delay (output layer done for window w minus the cycle its
marker was presented), the final decision delay, and buffer peaks.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_net import golden, parse_words, write_net_mems, pad_out  # noqa: E402

RTL = ROOT / "rtl"


def compile_stream(d: Path, **params) -> Path:
    exe = d / "stream.vvp"
    cmd = ["iverilog", "-g2012", "-o", str(exe), "-s", "tb_hush_stream"]
    for k, v in params.items():
        cmd += ["-P", f"tb_hush_stream.{k}={int(v)}"]
    cmd += [str(RTL / "hush_arith.sv"), str(RTL / "hush_layer.sv"), str(RTL / "hush_net.sv"), str(RTL / "tb_hush_stream.sv")]
    c = subprocess.run(cmd, capture_output=True, text=True)
    if c.returncode or "error" in c.stderr.lower():
        raise RuntimeError(f"iverilog failed: {c.stderr}")
    return exe


def stimulus(ev, T, t_max_us, speed, fclk=100e6):
    """Items (cycle, type, x, y, p) for one recording; returns items and marker cycles."""
    ev = ev[ev["t"] < t_max_us]
    win_us = t_max_us / T
    cyc_per_us = fclk / 1e6 / speed
    items = [(int(e["t"]), 0, int(e["x"]), int(e["y"]), int(e["p"])) for e in ev]           # time in us
    items += [(int(round((w + 1) * win_us)), 1, 0, 0, 0) for w in range(T)]
    items.sort(key=lambda r: (r[0], -r[1]))           # an event exactly at a window edge belongs to the next window
    out, last = [], -1
    for t_us, typ, x, y, p in items:
        cc = max(int(np.ceil(t_us * cyc_per_us)), last + 1)
        out.append((cc, typ, x, y, p))
        last = cc
    return out


def run_sample(exe, d, W1, Wo, ev, S, k, theta, gate, mf, nout, T, t_max_us, speed):
    write_net_mems(d, W1, Wo, S)
    items = stimulus(ev, T, t_max_us, speed)
    (d / "stim.txt").write_text("".join(f"{c} {t} {x} {y} {p}\n" for c, t, x, y, p in items))
    r = subprocess.run(["vvp", "-n", str(exe)], cwd=d, capture_output=True, text=True)
    if r.returncode:
        raise RuntimeError(r.stdout[-1500:] + r.stderr[-1500:])
    if "TIMEOUT" in r.stdout:      # overload lost an end-of-window marker, so the inference never completes
        return dict(ok=False, timeout=True, drops=-1, in_peak=-1, ring_peak=-1, win_delay_max=-1, win_delay_mean=-1,
                    decision_delay=-1, mis1=-1, mis2=-1)
    lines = (d / "stream_out.txt").read_text().splitlines()
    h, o, cls = golden(W1, Wo, S, k, theta, gate, mf, nout)
    G1 = W1.shape[1] // 32
    A = [l.split() for l in lines if l.startswith("A ")]
    B = [l.split() for l in lines if l.startswith("B ")]
    K = {int(l.split()[1]): int(l.split()[2]) for l in lines if l.startswith("K ")}
    L = {int(l.split()[1]): int(l.split()[2]) for l in lines if l.startswith("L ")}
    R = [l.split() for l in lines if l.startswith("R ")][0]
    mis1 = sum(not (np.array_equal(sp, h.spikes[int(t), 32 * int(b):32 * int(b) + 32]) and
                    np.array_equal(v, h.V[int(t), 32 * int(b):32 * int(b) + 32]))
               for _, t, b, *rest in A for sp, v in [parse_words(*rest)])
    mis2 = sum(not (np.array_equal(sp, o.spikes[int(t), :32]) and np.array_equal(v, o.V[int(t), :32]))
               for _, t, *rest in B for sp, v in [parse_words(*rest)])
    delay = np.array([L[w] - K[w] for w in range(T)])
    res = dict(cls=int(R[1]), cls_gold=int(cls), drops=int(R[3]), in_peak=int(R[4]), ring_peak=int(R[5]),
               mis1=mis1, rows1=len(A), mis2=mis2, rows2=len(B),
               win_delay_mean=float(delay.mean()), win_delay_max=int(delay.max()),
               last_marker=K[T - 1], cycles_total=int(R[2]), events=int(len(ev)), active=int(S.sum()))
    res["decision_delay"] = res["cycles_total"] - K[T - 1]
    res["ok"] = (res["drops"] == 0 and mis1 == 0 and mis2 == 0 and len(A) == T * G1 and len(B) == T
                 and res["cls"] == res["cls_gold"])
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", required=True)
    ap.add_argument("--gate", type=int, default=1)
    ap.add_argument("--mf", type=int, default=1)
    ap.add_argument("--n", type=int, default=3)
    ap.add_argument("--speed", type=float, default=1.0)
    ap.add_argument("--nev1", type=int, default=1024)
    ap.add_argument("--in_d", type=int, default=64)
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    from golden.datasets import NMNIST
    from scripts.measure_rho import pad_hidden
    z = np.load(a.weights)
    W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    nout = W2.shape[1]
    Wo = pad_out(W2, nout)
    k, theta, T, t_max = int(z["k"]), int(z["theta"]), int(z["T"]), int(float(z["t_max"]) * 1e6)
    ds = NMNIST(False, t_max)
    idx = np.random.default_rng(0).permutation(len(ds))[:a.n]          # same samples as test_rasters
    results = []
    with tempfile.TemporaryDirectory() as td:
        d = Path(td)
        exe = compile_stream(d, M1=W1.shape[0], N1=W1.shape[1], N2=32, NOUT=nout, T=T, K=k, THETA=theta,
                             THETA_H=theta, GATE=a.gate, MF=a.mf, NEV1=a.nev1, NEV2=4096, FIFO_D=32, IN_D=a.in_d,
                             SIDE=ds.side, POOL=ds.pool)
        for i in idx:
            ev, y = ds.ds[i]
            S, _ = ds.raster(i, T)
            r = run_sample(exe, d, W1, Wo, ev, S.astype(np.int64), k, theta, a.gate, a.mf, nout, T, t_max, a.speed)
            r.update(sample=int(i), label=int(y), speed=a.speed)
            results.append(r)
            print(json.dumps(r), flush=True)
    print(f"{sum(r['ok'] for r in results)}/{len(results)} PASS")
    if a.out:
        Path(a.out).write_text(json.dumps(results, indent=1))
    sys.exit(0 if all(r["ok"] for r in results) else 1)


if __name__ == "__main__":
    main()
