"""A3: memory images for SAIF power runs.

    python scripts/make_saif_hex.py --n 100

Writes fpga/saif/samples/{ev,ts}_NNN.hex for the first n N-MNIST test samples (fixed permutation used
everywhere else) whose event count fits NEV = 4096, and weight sets:
  fpga/saif/base/       ungated network (results/nmnist_T100, 97.59%)             -> BASE build
  fpga/saif/mf_gentle/  HUSH co-trained, gentle (nmnist_T100_mf_e05_d025, 95.32%) -> HUSH-MF build
  fpga/saif/mf_aggr/    HUSH co-trained, aggressive (nmnist_T100_mf_e2_d1, 92.72%) -> HUSH-MF build
Also fpga/saif/expected_cycles.csv: per-sample cycle count from the exact cycle model, to cross-check xsim.
"""
import argparse, sys
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "rtl" / "sim")]
from run_case import hexrow  # noqa: E402
from cycle_model import rtl_cycles  # noqa: E402
from golden.hush import LIFParams, mean_table, proxy_table, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402

ap = argparse.ArgumentParser(); ap.add_argument("--n", type=int, default=100); ap.add_argument("--nev", type=int, default=4096)
a = ap.parse_args()
out = ROOT / "fpga" / "saif"
nets = {"base": "nmnist_T100", "mf_gentle": "nmnist_T100_mf_e05_d025", "mf_aggr": "nmnist_T100_mf_e2_d1"}
W = {}
for name, tag in nets.items():
    z = np.load(ROOT / "results" / tag / "weights.npz")
    W0, _, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    W[name] = (W0, int(z["k"]), int(z["theta"]))
    d = out / name; d.mkdir(parents=True, exist_ok=True)
    M, N = W0.shape; G = N // 32
    with open(d / "w.hex", "w") as f:
        for b in range(G):
            for j in range(M):
                f.write(hexrow(W0[j, 32 * b:32 * b + 32], 8) + "\n")
    for nm, A in (("p", proxy_table(W0, 8)), ("q", mean_table(W0, 8))):
        with open(d / f"{nm}.hex", "w") as f:
            for j in range(M):
                f.write(hexrow(A[j], 8) + "\n")
z = np.load(ROOT / "results" / "nmnist_T100" / "weights.npz")
R, _ = test_rasters(z, 3 * a.n)
sd = out / "samples"; sd.mkdir(parents=True, exist_ok=True)
rows = ["idx,events,cycles_base,cycles_mf_gentle,cycles_mf_aggr"]
kept = 0
for S in R:
    S = S.astype(np.int64)
    ev, ts = [], [0]
    for t in range(S.shape[0]):
        ev += np.flatnonzero(S[t]).tolist(); ts.append(len(ev))
    if len(ev) > a.nev:
        continue
    with open(sd / f"ev_{kept:03d}.hex", "w") as f:
        for e in (ev or [0]):
            f.write(f"{e:04x}\n")
    with open(sd / f"ts_{kept:03d}.hex", "w") as f:
        for x in ts:
            f.write(f"{x:04x}\n")
    cyc = []
    for name in nets:
        W0, k, th = W[name]
        n = S.sum(1)
        if name == "base":
            tr = run_ref(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32)); cyc.append(rtl_cycles(n, tr.awake_blk, envelope=False))
        else:
            tr = run_gated(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32, asleep_drive="mean"), shadow=False)
            cyc.append(rtl_cycles(n, tr.awake_blk, envelope=True))
    rows.append(f"{kept},{len(ev)},{cyc[0]},{cyc[1]},{cyc[2]}")
    kept += 1
    if kept == a.n:
        break
(out / "expected_cycles.csv").write_text("\n".join(rows) + "\n")
c = np.array([[int(x) for x in r.split(",")[2:]] for r in rows[1:]])
print(f"{kept} samples; mean cycles base {c[:,0].mean():.0f}, mf_gentle {c[:,1].mean():.0f}, mf_aggr {c[:,2].mean():.0f}")
