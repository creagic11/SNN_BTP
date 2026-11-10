"""A9.4b: replay-speed sweep of hush_net in STREAM mode (RTL, Icarus) on the heaviest test recordings.

    python scripts/stream_sweep.py --k 40 --speeds 500,1000,1500,2000,2500,3000

Samples: the k test recordings with the most active (pooled, de-duplicated) input events, over all 10,000.
Designs: BASE (ungated net), HUSH gentle 12 ep, HUSH gentler 12 ep. Buffer: ring of 1,024 events (one RAMB18),
input FIFO 64. Per (design, speed, sample): drops, ring / FIFO peaks, max and mean per-window delay, bit-exact.
Output: results/realtime/stream_sweep.jsonl (one line per run) and a summary table stream_sweep.md.
"""
import argparse
import json
import sys
import tempfile
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
sys.path.insert(0, str(ROOT / "rtl" / "sim"))
from run_stream import compile_stream, run_sample  # noqa: E402
from run_net import pad_out  # noqa: E402
from golden.datasets import NMNIST  # noqa: E402
from scripts.measure_rho import pad_hidden  # noqa: E402

DESIGNS = {"BASE": ("results/nmnist_T100/weights.npz", 0, 0),
           "HUSH gentle 12ep": ("results/nmnist_T100_mf_e05_d025_ep12/weights.npz", 1, 1),
           "HUSH gentler 12ep": ("results/nmnist_T100_mf_e025_d01_ep12/weights.npz", 1, 1)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--k", type=int, default=40)
    ap.add_argument("--speeds", default="500,1000,1500,2000,2500,3000")
    ap.add_argument("--out", default=str(ROOT / "results" / "realtime" / "stream_sweep.jsonl"))
    a = ap.parse_args()
    speeds = [float(s) for s in a.speeds.split(",")]
    z0 = np.load(ROOT / DESIGNS["BASE"][0])
    T, t_max = int(z0["T"]), int(float(z0["t_max"]) * 1e6)
    ds = NMNIST(False, t_max)
    act = np.array([int(ds.raster(i, T)[0].sum()) for i in range(len(ds))])
    pick = np.argsort(-act)[:a.k]
    print("picked samples, active events:", act[pick].min(), "-", act[pick].max(), "(test-set mean", act.mean(), ")", flush=True)
    done = set()
    if Path(a.out).exists():
        for l in open(a.out):
            r = json.loads(l)
            done.add((r["design"], r["speed"], r["sample"]))
    with open(a.out, "a") as fo, tempfile.TemporaryDirectory() as td:
        d = Path(td)
        for name, (w, gate, mf) in DESIGNS.items():
            z = np.load(ROOT / w)
            W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
            nout = W2.shape[1]
            Wo = pad_out(W2, nout)
            exe = compile_stream(d, M1=W1.shape[0], N1=W1.shape[1], N2=32, NOUT=nout, T=T, K=int(z["k"]),
                                 THETA=int(z["theta"]), THETA_H=int(z["theta"]), GATE=gate, MF=mf, NEV1=1024,
                                 NEV2=4096, FIFO_D=32, IN_D=128, EVQ=64, SIDE=ds.side, POOL=ds.pool,
                                 TIMEOUT_CYC=int(3 * T * t_max / T * 100 / min(speeds)) + 1_000_000)
            for sp in speeds:
                for i in pick:
                    if (name, sp, int(i)) in done:
                        continue
                    ev, y = ds.ds[int(i)]
                    S, _ = ds.raster(int(i), T)
                    r = run_sample(exe, d, W1, Wo, ev, S.astype(np.int64), int(z["k"]), int(z["theta"]), gate, mf,
                                   nout, T, t_max, sp)
                    r.update(design=name, speed=sp, sample=int(i), label=int(y))
                    fo.write(json.dumps(r) + "\n")
                    fo.flush()
                print(name, sp, "done", flush=True)


if __name__ == "__main__":
    main()
