"""Paper figures from existing result files (11 Nov 2026). Run from the repo root.

  paper/fig_front.pdf    accuracy vs latency, every seed + mean (results/acc_integer.json, */net_perf.json)
  paper/fig_energy.pdf   active energy per inference split into static and dynamic (results/power_l1/README.md)
  paper/fig_activity.pdf cycles per 3 ms window vs input activity (results/realtime/stream_stats.md, A9.1b)
  paper/fig_replay.pdf   recordings replayed without a drop vs replay speed (results/realtime/stream_sweep.jsonl)
"""
import json
import statistics as st
from collections import defaultdict

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

R = "results/"
INK, MUTE, GRID = "#2b2a27", "#6b6a66", "#e6e5e1"
C = {"BASE": "#2a78d6", "gentler": "#eb6834", "gentle": "#1baf7a", "aggr": "#eda100"}
MK = {"BASE": "s", "gentler": "o", "gentle": "^", "aggr": "D"}
plt.rcParams.update({"pdf.fonttype": 42, "font.size": 8, "font.family": "serif", "axes.edgecolor": "#52514e", "axes.linewidth": 0.6,
                     "xtick.color": MUTE, "ytick.color": MUTE, "axes.labelcolor": INK, "text.color": INK})


def clean(ax):
    ax.grid(True, color=GRID, lw=0.5)
    ax.set_axisbelow(True)
    for s in ("top", "right"):
        ax.spines[s].set_visible(False)


def save(fig, name):
    fig.tight_layout(pad=0.3)
    fig.savefig(f"paper/{name}.pdf")
    fig.savefig(f"paper/{name}.png", dpi=200)
    plt.close(fig)


# ---------------------------------------------------------------- accuracy vs latency
acc = json.load(open(R + "acc_integer.json"))
tags = {"BASE": "nmnist_T100_ft12_ctrl{}", "gentler": "nmnist_T100_mf_e025_d01_ep12{}",
        "gentle": "nmnist_T100_mf_e05_d025_ep12{}", "aggr": "nmnist_T100_mf_e2_d1{}"}
lab = {"BASE": "BASE (gate off)", "gentler": "HUSH gentler", "gentle": "HUSH gentle", "aggr": "HUSH aggressive (6 ep)"}
fig, ax = plt.subplots(figsize=(3.4, 2.25))
pts = {}
for k, t in tags.items():
    a, l = [], []
    for s in ("", "_s1", "_s2"):
        p = json.load(open(R + t.format(s) + "/net_perf.json"))
        l.append((p["BASE"] if k == "BASE" else p["HUSH"])["latency_us"])
        a.append(100 * acc[t.format(s)]["acc_integer"])
    pts[k] = (st.mean(l), st.mean(a))
    ax.scatter(l, a, s=14, marker=MK[k], color=C[k], alpha=0.45, lw=0, zorder=3)
    ax.errorbar(st.mean(l), st.mean(a), xerr=st.stdev(l), yerr=st.stdev(a), fmt=MK[k], ms=5, color=C[k],
                mec="white", mew=0.6, elinewidth=0.8, capsize=1.5, zorder=4)
xs = [pts[k][0] for k in ("aggr", "gentle", "gentler", "BASE")]
ys = [pts[k][1] for k in ("aggr", "gentle", "gentler", "BASE")]
ax.plot(xs, ys, color=MUTE, lw=0.6, ls=(0, (2, 2)), zorder=2)
off = {"BASE": (-12, -22, "right"), "gentler": (6, -13, "left"), "gentle": (-4, 15, "center"), "aggr": (12, -1, "left")}
sp = {"BASE": "1.00×", "gentler": "1.75×", "gentle": "2.44×", "aggr": "3.39×"}
for k, (x, y) in pts.items():
    dx, dy, ha = off[k]
    ax.annotate(f"{lab[k]}\n{y:.2f} %, {sp[k]}", (x, y), xytext=(dx, dy), textcoords="offset points", ha=ha,
                va="center", fontsize=6.6, color=INK)
ax.set_xlim(50, 300); ax.set_ylim(90.5, 99)
ax.set_xlabel("Latency per inference (µs)"); ax.set_ylabel("Test accuracy (%)")
clean(ax)
save(fig, "fig_front")

# ---------------------------------------------------------------- energy split
E = [("BASE", "BASE", 42.49, 14.26), ("gentler", "HUSH gentler", 23.74, 8.47), ("gentle", "HUSH gentle", 18.44, 6.69),
     ("aggr", "HUSH aggr.", 14.39, 5.44)]
fig, ax = plt.subplots(figsize=(3.4, 1.55))
for i, (k, name, tot, dyn) in enumerate(E):
    y = len(E) - 1 - i
    ax.barh(y, tot - dyn, height=0.56, color=C[k], alpha=0.38, lw=0)
    ax.barh(y, dyn, left=tot - dyn + 0.35, height=0.56, color=C[k], lw=0)
    pct = "" if k == "BASE" else f"  ({100 * (tot / 42.49 - 1):+.0f} %)"
    ax.text(tot + 1.0, y, f"{tot:.1f} µJ{pct}", va="center", fontsize=6.8)
ax.set_yticks(range(len(E))); ax.set_yticklabels([e[1] for e in E][::-1], color=INK)
ax.set_xlim(0, 58); ax.set_xlabel("Active energy per inference (µJ)")
ax.text(14.1, 3.47, "static", fontsize=6.3, color=MUTE, ha="center")
ax.text(35.5, 3.47, "dynamic", fontsize=6.3, color=MUTE, ha="center")
clean(ax); ax.grid(axis="y", visible=False); ax.tick_params(axis="y", length=0)
ax.set_ylim(-0.5, 3.75)
save(fig, "fig_energy")

# ---------------------------------------------------------------- cycles per window vs activity (A9.1b, 12-epoch gentle)
B = [("1–9", 21.2, 118, 53, 2.22), ("10–19", 18.9, 195, 92, 2.12), ("20–29", 16.6, 280, 143, 1.96),
     ("30–39", 16.8, 362, 187, 1.94), ("40–59", 22.3, 469, 260, 1.81), ("≥60", 3.4, 610, 384, 1.59)]
fig, ax = plt.subplots(figsize=(3.4, 1.9))
w = 0.36
for i, (name, share, cb, ch, spd) in enumerate(B):
    ax.bar(i - w / 2 - 0.02, cb, w, color=C["BASE"], lw=0, label="BASE" if i == 0 else None)
    ax.bar(i + w / 2 + 0.02, ch, w, color=C["gentle"], lw=0, label="HUSH gentle" if i == 0 else None)
    ax.text(i, cb + 18, f"{spd:.2f}×", ha="center", fontsize=6.8)
ax.set_xticks(range(len(B))); ax.set_xticklabels([f"{b[0]}\n{b[1]:.0f} %" for b in B], fontsize=6.8)
ax.set_xlabel("Active inputs per 3 ms window (share of windows)")
ax.set_ylabel("Cycles per window"); ax.set_ylim(0, 720)
clean(ax); ax.grid(axis="x", visible=False); ax.tick_params(axis="x", length=0)
ax.legend(frameon=False, loc="upper left", fontsize=7, handlelength=1.2)
save(fig, "fig_activity")

# ---------------------------------------------------------------- replay sweep
ok = defaultdict(lambda: defaultdict(list))
for line in open(R + "realtime/stream_sweep.jsonl"):
    r = json.loads(line)
    ok[r["design"]][r["speed"]].append(bool(r["ok"]))
names = {}
for d in ok:
    names[d] = "BASE" if d.startswith("BASE") else ("gentler" if "gentler" in d else "gentle")
fig, ax = plt.subplots(figsize=(3.4, 1.8))
ls = {"BASE": "-", "gentler": "--", "gentle": ":"}
for d in sorted(ok, key=lambda d: ["BASE", "gentler", "gentle"].index(names[d])):
    k = names[d]
    sp_ = sorted(ok[d])
    n = [sum(ok[d][s]) for s in sp_]
    ax.plot(sp_, n, color=C[k], lw=1.5, ls=ls[k], marker=MK[k], ms=4, mec="white", mew=0.5,
            label="BASE" if k == "BASE" else f"HUSH {k}")
    print(d, list(zip(sp_, n)))
ax.set_xlabel("Replay speed (× real time)"); ax.set_ylabel("Recordings without\na dropped event (of 20)")
ax.set_ylim(-1, 22); ax.set_yticks([0, 5, 10, 15, 20]); ax.set_xticks([250, 500, 750, 1000, 1250, 1500, 2000])
clean(ax)
ax.set_xlim(200, 2050)
ax.legend(frameon=False, loc="lower left", bbox_to_anchor=(0.0, 0.08), fontsize=7, handlelength=2.6)
save(fig, "fig_replay")
