"""Paper Fig.: accuracy vs elapsed sensor time (results/realtime/early_decision.json) -> paper/fig_early.pdf"""
import json
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
e = json.load(open("results/realtime/early_decision.json"))
S = [("BASE + 12 ep fine-tune, no gate (control)", "BASE (gate off)", "#2a78d6", "-"),
     ("HUSH gentler 12ep", "HUSH gentler", "#eb6834", "--"),
     ("HUSH gentle 12ep", "HUSH gentle", "#1baf7a", ":")]
plt.rcParams.update({"pdf.fonttype": 42, "font.size": 8, "font.family": "serif", "axes.edgecolor": "#52514e", "axes.linewidth": 0.6})
fig, ax = plt.subplots(figsize=(3.4, 2.1))
for k, lab, c, ls in S:
    ms = e[k]["window_ms"]; a = [100 * x for x in e[k]["acc"]]
    ax.plot(ms, a, color=c, lw=1.6, ls=ls, label=lab)
ax.axvspan(21, 156, color="#eb6834", alpha=0.06, lw=0)
ax.text(88, 45, "gentler ahead\n21–156 ms", ha="center", va="center", fontsize=7, color="#52514e")
ax.set_xlim(0, 300); ax.set_ylim(10, 100)
ax.set_xlabel("Elapsed sensor time (ms)"); ax.set_ylabel("Test accuracy (%)")
ax.grid(True, color="#e6e5e1", lw=0.5); ax.set_axisbelow(True)
for s in ("top", "right"): ax.spines[s].set_visible(False)
ax.legend(frameon=False, loc="lower right", fontsize=7, handlelength=2.4)
fig.tight_layout(pad=0.3)
fig.savefig("paper/fig_early.pdf"); fig.savefig("paper/fig_early.png", dpi=200)
