"""A4.3: GHDL simulation of the full generated Spiker+ network on the 20 N-MNIST test samples used for the A3 power
runs; compares every output-spike line with spiker_model and records cycles per inference."""
import subprocess, sys, json, time, numpy as np
from pathlib import Path
here = Path(__file__).resolve().parent; ROOT = here.parent; sys.path[:0] = [str(ROOT), str(here)]
import spiker_model as sm
from scripts.measure_rho import test_rasters
d = Path(sys.argv[1]); n = int(sys.argv[2]) if len(sys.argv) > 2 else 20
z = np.load(d / "weights_int.npz"); Ws = [z["W0"], z["W1"]]; M, O = Ws[0].shape[0], Ws[1].shape[1]; T = 100
R, Y = test_rasters(np.load(ROOT / "results/nmnist_T100/weights.npz"), n)
rows = []
for i, S in enumerate(R):
    S = np.asarray(S, np.int64)
    (d / "stim.txt").write_text("".join("".join("1" if S[t, M-1-j] else "0" for j in range(M)) + "\n" for t in range(T)))
    t0 = time.time(); subprocess.run([str(here / "ghdl_run.sh"), str(d), str(M), str(O), str(T), "8"], check=True)
    lines = (d / "out.txt").read_text().split("\n")
    hw = np.array([[int(c) for c in r[::-1]] for r in lines if r and not r.startswith("END")])
    cyc = int([l for l in lines if l.startswith("END")][0].split()[1])
    out = sm.run(Ws, S, delay=0)[1][0]; ref = np.zeros_like(hw); ref[2:2 + T] = out[:len(hw) - 2]   # hw line i = spikes fired 2 steps earlier
    match = bool(np.array_equal(hw, ref)); cls_hw = int(np.argmax(hw.sum(0))); cls_m = int(sm.predict(out[None])[0])
    rows.append(dict(idx=i, label=int(Y[i]), events=int(S.sum()), cycles=cyc, match=match, class_hw=cls_hw, class_model=cls_m,
                     sim_s=round(time.time() - t0, 1)))
    print(rows[-1], flush=True)
res = dict(n=len(rows), all_match=all(r["match"] for r in rows), mean_cycles=float(np.mean([r["cycles"] for r in rows])),
           correct_hw=sum(r["class_hw"] == r["label"] for r in rows), rows=rows)
(ROOT / "results/spikerplus").mkdir(exist_ok=True); json.dump(res, open(ROOT / "results/spikerplus/ghdl_20.json", "w"), indent=1)
print({k: v for k, v in res.items() if k != "rows"})
