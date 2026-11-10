"""Test-set accuracy with the hardware's integer decision rule (golden.hush.predict: most output spikes, ties by the
larger summed U, then the lower index) for every trained point and seed. The training-time number in metrics.json
uses a float32 key counts*1e7 + sum(U), which rounds sum(U) away when counts are large (BASE seed 0: 2 of 10,000
decisions differ, 97.58 % vs 97.59 %). The paper reports this integer-rule accuracy. -> results/acc_integer.json"""
import json, sys
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, LayerTrace, predict, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402
tags = ["nmnist_T100", "nmnist_T100_mf_e05_d025", "nmnist_T100_mf_e2_d1", "nmnist_T100_mf_e025_d01_ep12",
        "nmnist_T100_mf_e05_d025_ep12"]
out = ROOT / "results" / "acc_integer.json"
res = json.load(open(out)) if out.exists() else {}
runs = [t + s for t in tags for s in ("", "_s1", "_s2")] + ["nmnist_T100_ft12_ctrl"]
R = Y = None
for run in runs:
    w = ROOT / "results" / run / "weights.npz"
    if run in res or not w.exists():
        continue
    z = np.load(w)
    if R is None:
        R, Y = test_rasters(z, 10000)
    W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    gated = "_mf_" in run
    p = LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32, asleep_drive="mean" if gated else "none")
    c = 0
    for S, y in zip(R, Y):
        h = run_gated(W1, S, p, shadow=False) if gated else run_ref(W1, S, p)
        o = run_ref(W2, h.spikes.astype(np.int64), p)
        c += predict(LayerTrace(spikes=o.spikes, V=o.V, U=o.U, awake_sub=o.awake_sub, awake_blk=o.awake_blk,
                                n_active=o.n_active)) == y
    m = json.load(open(ROOT / "results" / run / "metrics.json"))["log"][-1]["test_acc"]
    res[run] = {"acc_integer": c / len(Y), "acc_train_eval": m}
    json.dump(res, open(out, "w"), indent=1)
    print(run, res[run], flush=True)
