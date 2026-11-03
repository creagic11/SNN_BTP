"""A4: generate Spiker+ (spikerplus 2.0.3) VHDL for an integer feed-forward LIF network, using our trained INT8 weights.
Mapping: Spiker+ fixed point with fp_dec = 6 decimals, so weight w_int is passed as w_int / 64 and threshold 1.0 = 64;
neuron state 16 bit (saturating), weights 8 bit, beta = 0.9375 = 1 - 2^-4 (our k = 4), subtract reset.
usage: gen_spiker.py <weights.npz | random:M,N,O,seed> <outdir> [T]"""
import sys, logging
from pathlib import Path
import numpy as np, torch
from spikerplus import NetBuilder, VhdlGenerator
from spikerplus.vhdl import write_vhdl

src, outdir = sys.argv[1], Path(sys.argv[2]); T = int(sys.argv[3]) if len(sys.argv) > 3 else 100
if src.startswith("random:"):
    M, N, O, seed = map(int, src[7:].split(",")); rng = np.random.default_rng(seed)
    Ws = [rng.integers(-60, 61, (M, N)), rng.integers(-60, 61, (N, O))]
else:
    z = np.load(src); Ws = [z["W0"].astype(np.int64), z["W1"].astype(np.int64)]
sizes = [Ws[0].shape[0]] + [W.shape[1] for W in Ws]
layer = lambda n: {"neuron_model": "lif", "n_neurons": n, "beta": 0.9375, "learn_beta": False, "threshold": 1.,
                   "learn_threshold": False, "reset_mechanism": "subtract"}
net = {"n_cycles": T, "n_inputs": sizes[0], **{f"layer_{i}": layer(n) for i, n in enumerate(sizes[1:])}}
snn = NetBuilder(net).build()
fcs = [k for k in snn.layers if "fc" in k]
with torch.no_grad():
    for k, W in zip(fcs, Ws):
        snn.layers[k].weight.copy_(torch.tensor(W.T / 64.0, dtype=torch.float64))
vg = VhdlGenerator(snn, {"weights_bw": 8, "neurons_bw": 16, "fp_dec": 6})
v = vg.generate(interface=False, functional=True)
outdir.mkdir(parents=True, exist_ok=True)
import os; cwd = os.getcwd(); os.chdir(outdir); write_vhdl(v, rm=True); os.chdir(cwd)
np.savez(outdir / "weights_int.npz", W0=Ws[0], W1=Ws[1])
print("generated", outdir, "sizes", sizes, "T", T)
