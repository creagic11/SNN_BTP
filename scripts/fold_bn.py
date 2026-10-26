"""Fold training-time BatchNorm of a QDSNN export into integer weights, a per-neuron bias current and a
per-layer threshold, so the deployed network is pure integer LIF (+ constant current) with delays.

    python scripts/fold_bn.py results/shd_delay_bn/weights.npz results/shd_delay_bn_fold/weights.npz

Hidden layer i (inference BN): I' = (z W) g + c. With a per-layer scale s = 127 / max|W g|:
    W' = round(W g s) (INT8), bias' = round(c s), theta' = round(theta s).
Dynamics are linear in (V, I, theta) except for the leak's floor rounding, so the folded layer matches the
BN layer up to rounding; scripts/check_bitexact_delay.py then validates trainer == golden on the folded net.
"""
import sys
import numpy as np

src, dst = sys.argv[1], sys.argv[2]
z = dict(np.load(src))
nl = sum(1 for k in z if k.startswith("W") and k[1:].isdigit())
theta = int(z["theta"])
for i in range(nl - 1):
    if f"BNg{i}" not in z:
        continue
    W, g, c = z[f"W{i}"].astype(np.float64), z.pop(f"BNg{i}"), z.pop(f"BNc{i}")
    Wg = W * g[None, :]
    s = 127.0 / max(1e-9, np.abs(Wg).max())
    z[f"W{i}"] = np.clip(np.rint(Wg * s), -128, 127).astype(np.int8)
    z[f"BI{i}"] = np.rint(c * s).astype(np.int64)
    z[f"TH{i}"] = max(1, int(round(theta * s)))
    print(f"layer {i}: scale {s:.3f}, theta' {z[f'TH{i}']}, bias range [{z[f'BI{i}'].min()}, {z[f'BI{i}'].max()}], "
          f"|W'| max {np.abs(z[f'W{i}']).max()}")
z["folded"] = True
import os
os.makedirs(os.path.dirname(dst), exist_ok=True)
np.savez(dst, **z)
print("wrote", dst)
