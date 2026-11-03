"""A4.2: accuracy of our trained INT8 weights on Spiker+'s neuron semantics (spiker_model, GHDL-verified),
full N-MNIST test set, compared with our own golden model on the same weights."""
import sys, json, numpy as np
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]; sys.path[:0] = [str(ROOT), str(ROOT / "spikerplus")]
import spiker_model as sm
from scripts.measure_rho import test_rasters
tag = sys.argv[1] if len(sys.argv) > 1 else "nmnist_T100"; n = int(sys.argv[2]) if len(sys.argv) > 2 else 10000
z = np.load(ROOT / "results" / tag / "weights.npz"); Ws = [z["W0"].astype(np.int64), z["W1"].astype(np.int64)]
R, Y = test_rasters(z, n); R = np.asarray(R, np.int8); Y = np.asarray(Y)
correct = 0; vmax = 0; hid_rate = 0.0
for i in range(0, len(Y), 500):
    outs = sm.run(Ws, R[i:i+500].astype(np.int64), theta=int(z["theta"]), k=int(z["k"]), delay=1)
    correct += int((sm.predict(outs[1]) == Y[i:i+500]).sum()); hid_rate += outs[0].mean() * len(Y[i:i+500])
res = {"weights": tag, "n": len(Y), "spikerplus_acc": correct / len(Y), "hidden_rate": hid_rate / len(Y)}
print(json.dumps(res)); (ROOT / "results" / "spikerplus").mkdir(exist_ok=True)
json.dump(res, open(ROOT / "results" / "spikerplus" / f"accuracy_{tag}.json", "w"), indent=1)
