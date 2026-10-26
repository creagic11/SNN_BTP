"""P1.5: how much accuracy can a better asleep drive recover? Same trained net, same gate rule; only the
asleep-neuron drive changes: none (drop), mean (floor mean, v2), lr1/lr2/lr3 (clamped rank-r), exact (clamped
exact drive = ceiling of any approximation). Also the ungated accuracy of the same weights.

    python scripts/hibernation_ceiling.py results/shd_T250_mf_e2_d1/weights.npz --n 300
"""
import argparse, json, sys
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, predict, run_ref  # noqa: E402
from golden.hush_rec import AdLIFParams, RecLayer, run_rec  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402

ap = argparse.ArgumentParser(); ap.add_argument("weights"); ap.add_argument("--n", type=int, default=300)
ap.add_argument("--modes", default="none,mean,lr1,lr2,lr3,exact")
a = ap.parse_args()
z = np.load(a.weights)
W0, W1, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
k, th = int(z["k"]), int(z["theta"])
R, Y = test_rasters(z, a.n)
po = LIFParams(k=k, theta=th, b_env=W1.shape[1], b_blk=W1.shape[1])
res = {}
for mode in ["ungated"] + a.modes.split(","):
    lif = LIFParams(k=k, theta=th, b_env=8, b_blk=32, asleep_drive="none" if mode == "ungated" else mode)
    q = AdLIFParams(lif=lif, signed_drive=False)
    acc = col = base = 0
    for S, y in zip(R, Y):
        h = run_rec(RecLayer(W0), S, q, "ref" if mode == "ungated" else "gated", shadow=False)
        n = h.n_active
        col += int((h.awake_sub.sum(1) * n).sum()); base += h.awake_sub.shape[1] * int(n.sum())
        acc += predict(run_ref(W1, h.spikes, po)) == y
    res[mode] = {"acc": acc / len(Y), "reads": col / base}
    print(f"{Path(a.weights).parent.name:26s} {mode:8s} acc {acc / len(Y):.4f} reads {col / base:.3f}", flush=True)
json.dump(res, open(Path(a.weights).with_name("hibernation_ceiling.json"), "w"), indent=1)
