"""Bit-exact check of a trained recurrent adLIF network (train/qsnn.QRSNN) against golden/hush_rec.py.

    python scripts/check_bitexact_rec.py results/shd_rec_T250/weights.npz --n 100 [--gate 8 --asleep_drive mean]

Compares hidden spikes and readout potentials sample by sample, and the integer class decision
(argmax of summed readout potential, ties to the lower index). Also reports the readout potential range
so the readout accumulator width is justified (vbits_out).
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
import torch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, run_ref  # noqa: E402
from golden.hush_rec import AdLIFParams, RecLayer, run_rec  # noqa: E402
from scripts.measure_rho import test_rasters  # noqa: E402
from train.qsnn import QRSNN  # noqa: E402


def load_rec(z):
    nl = sum(1 for k in z.files if k.startswith("W") and k[1:].isdigit())
    layers = [RecLayer(z[f"W{i}"].astype(np.int64), z[f"R{i}"].astype(np.int64) if f"R{i}" in z else None,
                       z[f"A{i}"].astype(np.int64), z[f"Bad{i}"].astype(np.int64),
                       z[f"K{i}"].astype(np.int64) if f"K{i}" in z else None,
                       z[f"KW{i}"].astype(np.int64) if f"KW{i}" in z else None) for i in range(nl - 1)]
    return layers, z[f"W{nl - 1}"].astype(np.int64)


def predict_u(U: np.ndarray) -> int:
    return int(np.argmax(U.sum(axis=0)))          # numpy argmax: ties go to the lower index


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("weights")
    ap.add_argument("--n", type=int, default=100)
    ap.add_argument("--gate", type=int, default=0, help="b_env for gated hidden layers (0 = ungated)")
    ap.add_argument("--asleep_drive", default="none")
    ap.add_argument("--vbits_out", type=int, default=24)
    a = ap.parse_args()
    z = np.load(a.weights)
    layers, Wo = load_rec(z)
    k, theta, T = int(z["k"]), int(z["theta"]), int(z["T"])
    kw, sa, k_out, out_theta = int(z["kw"]), int(z["sa"]), int(z["k_out"]), int(z["out_theta"])
    readout = str(z["readout"])
    sizes = [layers[0].Wff.shape[0]] + [L.N for L in layers] + [Wo.shape[1]]
    model = QRSNN(sizes, theta=theta, k=k, kw=kw, sa=sa, recurrent=layers[0].Wrec is not None, k_out=k_out)
    model.layers[-1].theta = out_theta
    with torch.no_grad():
        for l, L in zip(model.layers[:-1], layers):
            l.w.copy_(torch.tensor(L.Wff, dtype=torch.float32))
            if L.Wrec is not None:
                l.wr.copy_(torch.tensor(L.Wrec, dtype=torch.float32))
            l.a.copy_(torch.tensor(L.a, dtype=torch.float32))
            l.b.copy_(torch.tensor(L.b, dtype=torch.float32))
            if L.kv is not None:
                l.kv.copy_(torch.tensor(L.kv, dtype=torch.float32))
                l.kwv.copy_(torch.tensor(L.kwv, dtype=torch.float32))
            l.gate_benv, l.asleep_drive = a.gate, a.asleep_drive
        model.layers[-1].w.copy_(torch.tensor(Wo, dtype=torch.float32))
    model.eval()
    rasters, Y = test_rasters(z, a.n)
    S = torch.tensor(np.stack(rasters)).float().transpose(0, 1)
    with torch.no_grad():
        So, Uo, hid = model(S)
    q = AdLIFParams(lif=LIFParams(k=k, theta=theta, b_env=a.gate or 8, b_blk=32, asleep_drive=a.asleep_drive),
                    kw=kw, sa=sa)
    po = LIFParams(k=k_out, theta=out_theta, vbits=a.vbits_out, b_env=Wo.shape[1], b_blk=Wo.shape[1])
    spk_mis = u_mis = pred_mis = correct = 0
    umax = 0
    reads = base = 0
    for i, r in enumerate(rasters):
        x = r.astype(np.int64)
        for li, L in enumerate(layers):
            h = run_rec(L, x, q, "gated" if a.gate else "ref", shadow=False)
            spk_mis += int((h.spikes != hid[li][0][:, i].numpy().astype(np.uint8)).sum())
            reads += int((h.awake_sub.sum(1) * h.n_active).sum())
            base += h.awake_sub.shape[1] * int(h.n_active.sum())
            x = h.spikes.astype(np.int64)
        o = run_ref(Wo, x, po)
        umax = max(umax, int(np.abs(o.U).max()))
        u_mis += int((o.U != Uo[:, i].numpy().astype(np.int64)).sum())
        p_g = predict_u(o.U) if readout == "u" else None
        p_t = int(Uo[:, i].sum(0).argmax()) if readout == "u" else None
        pred_mis += int(p_g != p_t)
        correct += int(p_g == Y[i])
    print(f"{a.weights}: n={len(Y)} gate={a.gate} drive={a.asleep_drive}: hidden spike mismatches {spk_mis}, "
          f"readout U mismatches {u_mis}, prediction mismatches {pred_mis}, golden acc {correct / len(Y):.4f}, "
          f"max|U_out| {umax} (fits {int(np.ceil(np.log2(umax + 1))) + 1} bits), col read frac {reads / max(1, base):.3f}")
    sys.exit(0 if spk_mis == u_mis == pred_mis == 0 else 1)


if __name__ == "__main__":
    main()
