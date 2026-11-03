"""Compare GHDL simulation of a generated small Spiker+ net with spiker_model.run for several random input rasters."""
import subprocess, sys, numpy as np
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent)); import spiker_model as sm
d = Path(sys.argv[1]); T = int(sys.argv[2]); CW = int(sys.argv[3]); trials = int(sys.argv[4]) if len(sys.argv) > 4 else 5
z = np.load(d / "weights_int.npz"); Ws = [z["W0"], z["W1"]]; M, O = Ws[0].shape[0], Ws[1].shape[1]
rng = np.random.default_rng(7); ok = {0: 0, 1: 0, 2: 0}
for tr in range(trials):
    S = (rng.random((T, M)) < rng.choice([0.0, 0.1, 0.3, 0.6])).astype(np.int64)
    (d / "stim.txt").write_text("".join("".join("1" if S[t, M-1-i] else "0" for i in range(M)) + "\n" for t in range(T)))
    subprocess.run([str(Path(__file__).parent / "ghdl_run.sh"), str(d), str(M), str(O), str(T), str(CW)], check=True)
    lines = (d / "out.txt").read_text().split("\n")
    rows = [l for l in lines if l and not l.startswith("END")]; cyc = [l for l in lines if l.startswith("END")][0]
    hw = np.array([[int(c) for c in r[::-1]] for r in rows])      # hw[i] = out_spikes at start_all i (bit 0 first)
    for dl in (0, 1, 2):
        out = sm.run(Ws, S, delay=dl)[1][0]                      # (T, O)
        for sh in (0, 1, 2):                                      # hw line i shows spikes fired sh steps earlier
            ref = np.zeros_like(hw); n = min(len(hw) - sh, T)
            ref[sh:sh + n] = out[:n]
            if np.array_equal(hw[:T + 1], ref[:T + 1]): ok[dl] += 1; print(f"trial {tr}: match delay={dl} shift={sh} {cyc} spikes={int(out.sum())}")
print("matches per delay:", ok)
