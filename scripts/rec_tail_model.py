"""P2 design study: exposed recurrent-envelope tail per timestep under four drain policies.

Per step t: n_t events (FF + recurrent), blocks b with awake flag and spike burst s_b (emitted at BLK_FIN).
Recurrent part of D_{t+1} needs one P_rec row per spike (ports rows/cycle, pipeline latency LAT).
  naive      : all rows read after the block loop                  tail = ceil(S/ports) + LAT
  overlap    : block b's rows drain during block b+1's pass; only the last block is exposed
  overlap+awf: as overlap, awake blocks scheduled first; asleep blocks (2 cycles each, no spikes) hide the tail
  ... each with 1 or 2 read ports (true dual-port BRAM).
Block cycle costs follow rtl/sim/cycle_model.py (awake 3 + n + 3, asleep 2).
Gating pattern: HUSH-G gated run (b_env 8, mean-field) of the given weights, or ungated (all awake, worst case).
"""
import argparse, json, sys
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]; sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams  # noqa: E402
from golden.hush_rec import AdLIFParams, run_rec  # noqa: E402
from scripts.check_bitexact_rec import load_rec  # noqa: E402
from scripts.measure_rho import test_rasters  # noqa: E402

LAT = 3


def exposed(n, awake, burst, ports, policy):
    order = np.argsort(~awake, kind="stable") if policy == "overlap_awf" else np.arange(awake.size)
    cost = np.where(awake, 3 + n + 3 if n else 4, 2)
    if policy == "naive":
        return int(np.ceil(burst.sum() / ports)) + (LAT if burst.sum() else 0)
    pending = 0                                   # rows of P_rec still to read
    for b in order:
        pending = max(0, pending - cost[b] * ports)   # drain during this block's pass
        pending += burst[b]
    pending = max(0, pending - 2 * ports)          # SEL(b==G) + STEP_END cycles
    return int(np.ceil(pending / ports)) + (LAT if pending else 0)


ap = argparse.ArgumentParser(); ap.add_argument("weights"); ap.add_argument("--n", type=int, default=40)
ap.add_argument("--gated", type=int, default=0)
a = ap.parse_args()
z = np.load(a.weights); layers, _ = load_rec(z); L = layers[0]
R, _ = test_rasters(z, a.n)
q = AdLIFParams(lif=LIFParams(k=int(z["k"]), theta=int(z["theta"]), b_env=8, b_blk=32,
                              asleep_drive="mean" if a.gated else "none"), kw=int(z["kw"]), sa=int(z["sa"]))
pols = [(p, k) for p in ("naive", "overlap", "overlap_awf") for k in (1, 2)]
tail = {f"{p}/{k}p": 0 for p, k in pols}
step_cycles = 0
for S in R:
    tr = run_rec(L, S.astype(np.int64), q, "gated" if a.gated else "ref", shadow=False)
    sp = tr.spikes.astype(np.int64).reshape(tr.spikes.shape[0], -1, 32).sum(2)
    for t in range(sp.shape[0]):
        n, aw = int(tr.n_active[t]), tr.awake_blk[t]
        step_cycles += 1 + int(np.where(aw, 3 + n + 3 if n else 4, 2).sum()) + 2
        for p, k in pols:
            tail[f"{p}/{k}p"] += exposed(n, aw, sp[t], k, p)
res = {"gated": bool(a.gated), "samples": len(R), "block_loop_cycles_per_inf": step_cycles / len(R),
       "exposed_tail_cycles_per_inf": {k: v / len(R) for k, v in tail.items()},
       "overhead_pct": {k: 100 * v / step_cycles for k, v in tail.items()}}
print(json.dumps(res, indent=1))
