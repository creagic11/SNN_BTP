"""A3 (gate-level SAIF flow): on-chip multi-sample memory images for power builds.

    python scripts/make_power_hex.py --nsmp 20

fpga/pwr/<case>/{w,p,q,ev,ts}.hex for case in base (ungated net), mf_gentle, mf_aggr. ev.hex concatenates the
events of NSMP N-MNIST test samples (fixed permutation); ts.hex holds NSMP*(T+1) absolute start indices, so
sample s uses ts entries [s*(T+1), (s+1)*(T+1)). Also fpga/pwr/expected.csv (per-sample model cycles).
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

ap = argparse.ArgumentParser(); ap.add_argument("--nsmp", type=int, default=20); ap.add_argument("--nev", type=int, default=65536)
a = ap.parse_args()
nets = {"base": "nmnist_T100", "mf_gentle": "nmnist_T100_mf_e05_d025", "mf_aggr": "nmnist_T100_mf_e2_d1"}
z = np.load(ROOT / "results" / "nmnist_T100" / "weights.npz")
R, _ = test_rasters(z, a.nsmp)
ev, ts = [], []
for S in R:
    S = S.astype(np.int64)
    ts.append(len(ev))
    for t in range(S.shape[0]):
        ev += np.flatnonzero(S[t]).tolist(); ts.append(len(ev))
assert len(ev) < min(a.nev, 65536), f"{len(ev)} events do not fit"
out = ROOT / "fpga" / "pwr"
rows = ["idx,events,cycles_base,cycles_mf_gentle,cycles_mf_aggr"]
cyc = {}
for name, tag in nets.items():
    zz = np.load(ROOT / "results" / tag / "weights.npz")
    W0, _, _ = pad_hidden(zz["W0"].astype(np.int64), zz["W1"].astype(np.int64), 32)
    k, th = int(zz["k"]), int(zz["theta"])
    d = out / name; d.mkdir(parents=True, exist_ok=True)
    M, N = W0.shape
    with open(d / "w.hex", "w") as f:
        for b in range(N // 32):
            for j in range(M):
                f.write(hexrow(W0[j, 32 * b:32 * b + 32], 8) + "\n")
    for nm, A in (("p", proxy_table(W0, 8)), ("q", mean_table(W0, 8))):
        with open(d / f"{nm}.hex", "w") as f:
            for j in range(M):
                f.write(hexrow(A[j], 8) + "\n")
    with open(d / "ev.hex", "w") as f:
        f.write("".join(f"{e:04x}\n" for e in ev))
    with open(d / "ts.hex", "w") as f:
        f.write("".join(f"{x:04x}\n" for x in ts))
    cyc[name] = []
    for S in R:
        S = S.astype(np.int64); n = S.sum(1)
        if name == "base":
            tr = run_ref(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32)); cyc[name].append(rtl_cycles(n, tr.awake_blk, envelope=False))
        else:
            tr = run_gated(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32, asleep_drive="mean"), shadow=False)
            cyc[name].append(rtl_cycles(n, tr.awake_blk, envelope=True))
for i, S in enumerate(R):
    rows.append(f"{i},{int(S.sum())},{cyc['base'][i]},{cyc['mf_gentle'][i]},{cyc['mf_aggr'][i]}")
(out / "expected.csv").write_text("\n".join(rows) + "\n")
print(f"{a.nsmp} samples, {len(ev)} events total; mean cycles base {np.mean(cyc['base']):.0f}, "
      f"mf_gentle {np.mean(cyc['mf_gentle']):.0f}, mf_aggr {np.mean(cyc['mf_aggr']):.0f}")
