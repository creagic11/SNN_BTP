"""A9.4 / A9.6: real-time tables from the RTL stream runs.

Inputs: results/realtime/sensor_{base,gentle12}.json (true sensor timing), results/realtime/stream_sweep.jsonl (replay
sweep on the heaviest recordings), results/*/net_perf.json (mean cycles, 500 samples), results/realtime/
early_decision.json. Output: results/realtime/realtime.md
"""
import json
from collections import defaultdict
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RT = ROOT / "results" / "realtime"
FCLK = 100e6
WIN_US, T = 3000.0, 100
NETS = {"BASE": ("nmnist_T100", "BASE"), "HUSH gentle 12ep": ("nmnist_T100_mf_e05_d025_ep12", "HUSH"),
        "HUSH gentler 12ep": ("nmnist_T100_mf_e025_d01_ep12", "HUSH")}


def load(p):
    return [json.loads(l) for l in open(p)] if p.exists() else []


def main():
    out = ["# A9.4 — real-time operation on a live N-MNIST stream (RTL simulation, 100 MHz)\n"]
    sens = []
    for f, d in (("sensor_base.json", "BASE"), ("sensor_gentle12.json", "HUSH gentle 12ep")):
        if (RT / f).exists():
            sens += [dict(r, design=d) for r in json.load(open(RT / f))]
    if sens:
        out += ["## (a) True sensor timing: events presented at their recorded times (3 ms windows)\n",
                "| Design | Recordings | Bit-exact, no drops | Window delay mean µs | Window delay max µs | Decision after last window µs | Input FIFO peak | Ring peak (of 1,024) |",
                "|---|---|---|---|---|---|---|---|"]
        g = defaultdict(list)
        for r in sens:
            g[r["design"]].append(r)
        for d, rs in g.items():
            out.append(f"| {d} | {len(rs)} | {sum(r['ok'] for r in rs)}/{len(rs)} | "
                       f"{np.mean([r['win_delay_mean'] for r in rs]) / 100:.2f} | {max(r['win_delay_max'] for r in rs) / 100:.2f} | "
                       f"{max(r['decision_delay'] for r in rs) / 100:.2f} | {max(r['in_peak'] for r in rs)} | {max(r['ring_peak'] for r in rs)} |")
        out.append(f"\nWindow length 3,000 µs → worst window uses {max(r['win_delay_max'] for r in sens) / 100 / WIN_US * 100:.2f} % of it.\n")
    sw = load(RT / "stream_sweep.jsonl")
    if sw:
        n = len({r["sample"] for r in sw})
        out += [f"## (b) Replay faster than real time — the {n} test recordings with the most input events\n",
                "Same buffer for every design: ring of 1,024 events (one RAMB18) + 64-entry input FIFO. A run passes if",
                "nothing is dropped and every result is bit-exact. Delay = output layer done for a window − its marker.\n",
                "| Design | Speed × | Passing | Max window delay µs | Mean window delay µs | Ring peak |", "|---|---|---|---|---|---|"]
        g = defaultdict(list)
        for r in sw:
            g[(r["design"], r["speed"])].append(r)
        best = {}
        for (d, s), rs in sorted(g.items()):
            ok = sum(r["ok"] for r in rs)
            out.append(f"| {d} | {s:g} | {ok}/{len(rs)} | {max(r['win_delay_max'] for r in rs) / 100:.2f} | "
                       f"{np.mean([r['win_delay_mean'] for r in rs]) / 100:.2f} | {max(r['ring_peak'] for r in rs)} |")
            if ok == len(rs):
                best[d] = max(best.get(d, 0), s)
        out += ["", "| Design | Fastest speed with no drops on all of them | Sustained raw-event rate at that speed (test-set mean 13.97 k ev/s × speed) |",
                "|---|---|---|"]
        for d, s in best.items():
            out.append(f"| {d} | {s:g}× | {13.97e3 * s / 1e6:.1f} M events/s |")
    rows = []
    for d, (tag, mode) in NETS.items():
        p = ROOT / "results" / tag / "net_perf.json"
        if p.exists():
            c = json.load(open(p))[mode]["cycles"]
            rows.append(f"| {d} | {c:,.0f} | {T * WIN_US * 1e-6 * FCLK / c:,.0f}× |")
    if rows:
        out += ["", "## Average-load bound (no buffer limit): 300 ms of sensor time / mean cycles per recording\n",
                "| Design | Mean cycles per recording (500 samples) | Real-time factor |", "|---|---|---|"] + rows
    ed = RT / "early_decision.json"
    if ed.exists():
        e = json.load(open(ed))
        out += ["", f"## A9.7 — accuracy vs elapsed sensor time (class read from the chip after w windows; {e['n']} test samples)\n",
                "| Design | 30 ms | 60 ms | 99 ms | 150 ms | 201 ms | 300 ms |", "|---|---|---|---|---|---|---|"]
        for d, v in e.items():
            if d == "n":
                continue
            out.append(f"| {d} | " + " | ".join(f"{100 * v['acc'][w]:.2f}" for w in (9, 19, 32, 49, 66, 99)) + " |")
    (RT / "realtime.md").write_text("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
