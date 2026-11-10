"""A9.2: whole-network latency on chip (hush_net: output layer overlapped with the hidden layer, class on chip),
3 seeds, 500 test samples each (scripts/net_perf.py, exact cycle model). -> results/net_latency.md"""
import json
import statistics as st
R = "results/"
tags = {"base": "nmnist_T100{}", "gentle": "nmnist_T100_mf_e05_d025{}", "aggr": "nmnist_T100_mf_e2_d1{}",
        "gentler12": "nmnist_T100_mf_e025_d01_ep12{}", "gentle12": "nmnist_T100_mf_e05_d025_ep12{}"}
names = {"base": "BASE (ungated)", "gentler12": "HUSH-MF gentler, 12 ep", "gentle12": "HUSH-MF gentle, 12 ep",
         "gentle": "HUSH-MF gentle, 6 ep", "aggr": "HUSH-MF aggressive"}
suf = ["", "_s1", "_s2"]
f = lambda v, d=1: f"{st.mean(v):.{d}f} ± {st.stdev(v):.{d}f}"
out = ["# A9.2 — whole network on chip: latency per inference (3 seeds × 500 test samples)\n",
       "hush_net: hidden layer → spike FIFO → output layer (overlapped, one timestep behind) → integer class on chip.",
       "Exact cycle model (`rtl/sim/net_cycle_model.py`), equal to the RTL cycle for cycle on 8 random nets and",
       "200 N-MNIST runs (`results/net/`). 100 MHz. 'Before' = hidden + output layer run one after the other",
       "(the model used in the A5 tables). Speedup vs the ungated net of the same seed.\n",
       "| Network | Latency µs (on chip) | Before (sequential) µs | Max µs | Speedup vs BASE | Peak spike-FIFO |",
       "|---|---|---|---|---|---|"]
for k in ("base", "gentler12", "gentle12", "gentle", "aggr"):
    lat, seq, mx, sp, pk = [], [], [], [], 0
    for s in suf:
        p = json.load(open(R + tags[k].format(s) + "/net_perf.json"))
        b = json.load(open(R + tags["base"].format(s) + "/net_perf.json"))["BASE"]
        m = p["BASE"] if k == "base" else p["HUSH"]
        lat.append(m["latency_us"]); seq.append(m["seq_sum_cycles"] / 100); mx.append(m["cycles_max"] / 100)
        sp.append(b["cycles"] / m["cycles"]); pk = max(pk, m["fifo_peak"])
    out.append(f"| {names[k]} | {f(lat)} | {f(seq)} | {max(mx):.1f} | {f(sp, 2)}× | {pk} |")
open(R + "net_latency.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
