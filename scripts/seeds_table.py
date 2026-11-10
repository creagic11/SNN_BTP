"""A5 + A6: mean ± std over seeds 0-2 for the N-MNIST points (accuracy on the full test set from metrics.json;
latency / column reads from rtl_perf.json, 500 samples, v5 cycle model; energy = seed-0 SAIF power × latency)."""
import json, statistics as st
R = "results/"
P = {"base": 0.145, "gentle": 0.151, "aggr": 0.157,         # W, gate-level SAIF (results/power_saif_v5)
     "gentler12": 0.151, "gentle12": 0.151}                   # A6 points: gentle SAIF power reused (estimate, L1 pending)
tags = {"base": "nmnist_T100{}", "gentle": "nmnist_T100_mf_e05_d025{}", "aggr": "nmnist_T100_mf_e2_d1{}",
        "gentler12": "nmnist_T100_mf_e025_d01_ep12{}", "gentle12": "nmnist_T100_mf_e05_d025_ep12{}"}
suf = ["", "_s1", "_s2"]
rows = {}
for k, t in tags.items():
    acc, lat, rd, sp = [], [], [], []
    for i, s in enumerate(suf):
        acc.append(100 * json.load(open(R + "acc_integer.json"))[t.format(s)]["acc_integer"])   # hardware decision rule
        p = json.load(open(R + t.format(s) + "/rtl_perf.json"))
        b = json.load(open(R + tags["base"].format(s) + "/rtl_perf.json"))["BASE"]["latency_us"]
        L = p["BASE"]["latency_us"] if k == "base" else p["HUSH"]["latency_us"]
        lat.append(L); sp.append(b / L); rd.append(1.0 if k == "base" else p["col_read_ratio"])
    rows[k] = dict(acc=acc, lat=lat, rd=rd, sp=sp, E=[P[k] * x for x in lat])
f = lambda v, d=2: f"{st.mean(v):.{d}f} ± {st.stdev(v):.{d}f}"
out = ["# A5 + A6 — N-MNIST, three seeds (0, 1, 2): mean ± sample std\n",
       "Accuracy on the full 10,000-sample test set with the hardware's integer decision rule (results/acc_integer.json); latency and weight-column reads for the whole 578-256-10 network over",
       "500 test samples (exact v5 cycle model, matches gate-level simulation within 3–8 cycles); speedup vs the ungated",
       "net of the same seed; energy = gate-level SAIF power of the seed-0 builds × latency.\n",
       "| Network | Accuracy % | Latency µs | Speedup vs BASE | Weight-column reads | Energy µJ | per-seed accuracy |",
       "|---|---|---|---|---|---|---|"]
for k, n in (("base", "BASE (ungated)"), ("gentle", "HUSH-MF gentle"), ("aggr", "HUSH-MF aggressive"),
             ("gentler12", "HUSH-MF gentler, 12 ep (A6)*"), ("gentle12", "HUSH-MF gentle, 12 ep (A6)*")):
    r = rows[k]
    out.append(f"| {n} | {f(r['acc'])} | {f(r['lat'],1)} | {f(r['sp'])}× | {f(r['rd'],3)} | {f(r['E'],1)} | {', '.join(f'{a:.2f}' for a in r['acc'])} |")
out.append("\n\\* Energy of the A6 rows uses the gentle build's SAIF power (0.151 W); their own SAIF power is pending (laptop run L1).")
open(R + "seeds_nmnist.md", "w").write("\n".join(out) + "\n")
print("\n".join(out))
