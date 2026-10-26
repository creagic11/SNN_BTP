"""Full-test-set accuracy and hidden rate of a QDSNN export (folded or not), and optionally gated reads.
    python scripts/eval_delay.py results/shd_delay_fold/weights.npz [--gate 8 --asleep_drive mean]"""
import argparse, sys
from pathlib import Path
import numpy as np, torch
ROOT = Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT))
from train.qsnn import QDSNN  # noqa: E402
from golden.datasets import SHD  # noqa: E402
ap = argparse.ArgumentParser(); ap.add_argument("weights"); ap.add_argument("--gate", type=int, default=0)
ap.add_argument("--asleep_drive", default="none"); ap.add_argument("--bn_model", default="")
a = ap.parse_args(); torch.set_num_threads(2)
z = np.load(a.weights)
nl = sum(1 for k in z.files if k.startswith("W") and k[1:].isdigit())
sizes = [z["W0"].shape[0]] + [z[f"W{i}"].shape[1] for i in range(nl)]
m = QDSNN(sizes, theta=int(z["theta"]), k=int(z["k"]), dmax=int(z["dmax"]), k_out=int(z["k_out"]))
m.layers[-1].theta = int(z["out_theta"])
with torch.no_grad():
    for i in range(nl):
        m.layers[i].w.copy_(torch.tensor(z[f"W{i}"].astype(np.float32)))
        m.delays[i].pos.copy_(torch.tensor(z[f"D{i}"].astype(np.float32)))
    for i, l in enumerate(m.layers[:-1]):
        l.gate_benv, l.asleep_drive = a.gate, a.asleep_drive
        if f"TH{i}" in z: l.theta = int(z[f"TH{i}"]); l.sscale = l.theta / 4
        if f"BI{i}" in z: l.bias = torch.nn.Parameter(torch.tensor(z[f"BI{i}"].astype(np.float32)))
m.eval(); m.set_sigma(0.0)
ds = SHD(False, float(z["t_max"]), int(z["pool"]))
T = int(z["T"]); n = len(ds); corr = 0; rate = 0.0; work = 0.0
with torch.no_grad():
    for i in range(0, n, 250):
        idx = list(range(i, min(n, i + 250)))
        S = torch.tensor(ds.batch(idx, T)).float().transpose(0, 1)
        So, Uo, hid = m(S)
        corr += int((Uo.max(0).values.argmax(1) == torch.tensor(ds.labels[idx])).sum())
        rate += float(np.mean([h[0].mean() for h in hid[:-1]])) * len(idx)
        if a.gate: work += float(np.mean([l.work for l in m.layers[:-1]])) * len(idx)
print(f"{a.weights}: test acc {corr / n:.4f} (n={n}), hidden rate {rate / n:.4f}" + (f", col read frac {work / n:.3f}" if a.gate else ""))
