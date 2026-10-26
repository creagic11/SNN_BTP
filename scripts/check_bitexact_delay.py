"""Bit-exact check of a trained delay network (train/qsnn.QDSNN) against golden/hush_delay.py.

    python scripts/check_bitexact_delay.py results/<tag>/weights.npz --n 100 [--gate 8 --asleep_drive mean]
"""
import argparse, sys
from pathlib import Path
import numpy as np
import torch
ROOT = Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT))
from golden.hush_delay import run_delay_network  # noqa: E402
from scripts.measure_rho import test_rasters  # noqa: E402
from train.qsnn import QDSNN  # noqa: E402

ap = argparse.ArgumentParser(); ap.add_argument("weights"); ap.add_argument("--n", type=int, default=100)
ap.add_argument("--gate", type=int, default=0); ap.add_argument("--asleep_drive", default="none")
a = ap.parse_args()
z = np.load(a.weights)
nl = sum(1 for k in z.files if k.startswith("W") and k[1:].isdigit())
sizes = [z["W0"].shape[0]] + [z[f"W{i}"].shape[1] for i in range(nl)]
m = QDSNN(sizes, theta=int(z["theta"]), k=int(z["k"]), dmax=int(z["dmax"]), k_out=int(z["k_out"]))
m.layers[-1].theta = int(z["out_theta"])
with torch.no_grad():
    for i in range(nl):
        m.layers[i].w.copy_(torch.tensor(z[f"W{i}"].astype(np.float32)))
        m.delays[i].pos.copy_(torch.tensor(z[f"D{i}"].astype(np.float32)))
    for l in m.layers[:-1]:
        l.gate_benv, l.asleep_drive = a.gate, a.asleep_drive
m.eval(); m.set_sigma(0.0)
R, Y = test_rasters(z, a.n)
S = torch.tensor(np.stack(R)).float().transpose(0, 1)
with torch.no_grad():
    So, Uo, hid = m(S)
mis_s = mis_u = mis_p = corr = 0; umax = 0; reads = base = 0
umaxmode = str(z["readout"]) == "umax"
for i, r in enumerate(R):
    trs, o = run_delay_network(z, r, "gated" if a.gate else "ref", a.gate or 8, a.asleep_drive)
    for li, tr in enumerate(trs):
        mis_s += int((tr.spikes != hid[li][0][:, i].numpy().astype(np.uint8)).sum())
        reads += int((tr.awake_sub.sum(1) * tr.n_active).sum()); base += tr.awake_sub.shape[1] * int(tr.n_active.sum())
    mis_u += int((o.U != Uo[:, i].numpy().astype(np.int64)).sum())
    umax = max(umax, int(np.abs(o.U).max()))
    pg = int(np.argmax(o.U.max(0) if umaxmode else o.U.sum(0)))
    pt = int((Uo[:, i].max(0).values if umaxmode else Uo[:, i].sum(0)).argmax())
    mis_p += pg != pt; corr += pg == Y[i]
print(f"{a.weights}: n={len(Y)} gate={a.gate}: hidden spike mismatches {mis_s}, readout U mismatches {mis_u}, "
      f"prediction mismatches {mis_p}, golden acc {corr / len(Y):.4f}, max|U_out| {umax}, col read frac {reads / max(1, base):.3f}")
sys.exit(0 if mis_s == mis_u == mis_p == 0 else 1)
