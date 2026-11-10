"""Why do the gated nets decide earlier (A9.7)? Per design, over n test samples: first output-spike window,
output spikes in the first 20 / 33 windows, hidden spikes per window, and whether early errors are 'no output
spike yet' (decision falls back to summed U) or 'wrong spikes'."""
import sys, json
import numpy as np
sys.path.insert(0, ".")
from golden.hush import LIFParams, run_gated, run_ref
from scripts.measure_rho import pad_hidden, test_rasters
P = {"BASE": ("results/nmnist_T100/weights.npz", None),
     "control": ("results/nmnist_T100_ft12_ctrl/weights.npz", None),
     "gentler12": ("results/nmnist_T100_mf_e025_d01_ep12/weights.npz", "mean"),
     "gentle12": ("results/nmnist_T100_mf_e05_d025_ep12/weights.npz", "mean")}
n = int(sys.argv[1]) if len(sys.argv) > 1 else 1000
res = {}
for name, (w, drive) in P.items():
    z = np.load(w)
    W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    p = LIFParams(k=4, theta=64, b_env=8, b_blk=32, asleep_drive=drive or "none")
    R, Y = test_rasters(z, n)
    first, s20, s33, hid20, nospk33, wrong33 = [], [], [], [], 0, 0
    for S, y in zip(R, Y):
        h = run_gated(W1, S, p, shadow=False) if drive else run_ref(W1, S, p)
        o = run_ref(W2, h.spikes.astype(np.int64), p)
        sp = o.spikes[:, :10]
        tt = np.flatnonzero(sp.sum(1))
        first.append(tt[0] if len(tt) else 100)
        s20.append(sp[:20].sum()); s33.append(sp[:33].sum()); hid20.append(h.spikes[:20].sum())
        c = sp[:33].sum(0)
        if c.max() == 0: nospk33 += 1
        elif int(np.argmax(c)) != y and c[y] < c.max(): wrong33 += 1
    res[name] = dict(first_out_spike_window_median=float(np.median(first)), first_mean=float(np.mean(first)),
                     out_spikes_first20=float(np.mean(s20)), out_spikes_first33=float(np.mean(s33)),
                     hidden_spikes_first20=float(np.mean(hid20)),
                     no_output_spike_by_99ms=nospk33 / n, wrong_leader_by_99ms=wrong33 / n)
    print(name, json.dumps(res[name]), flush=True)
json.dump(res, open("results/realtime/early_analysis.json", "w"), indent=1)
