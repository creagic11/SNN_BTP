# SNN_BTP — HUSH: provably safe block hibernation for SNN accelerators

B.Tech thesis project (IIT Kharagpur, EE; supervisor Prof. Rajat Shubhra Chakraborty).

HUSH puts a group of 8 neurons to sleep for a timestep only when an integer bound **proves** that none of them can fire. It then skips their weight reads on a Xilinx Artix-7 (XC7A100T).

**Status (11 Nov 2026):**

- Safety is formally proven on the RTL arithmetic (SymbiYosys PDR) and property-tested on the golden models.
- The whole 578-256-10 network runs on chip (hidden layer → output layer → integer class, `rtl/hush_net.sv`), also in a live-stream mode that takes raw DVS events; RTL is bit- and cycle-exact against the golden model; all builds meet 100 MHz on the XC7A100T.
- On N-MNIST, against the same hardware with the gate off trained equally long (98.21 %): HUSH gentle 95.74 %, 2.44× faster, 57 % less energy per inference; gentler 96.54 %, 1.75×, 44 % (gate-level activity-based power, `results/power_l1/`, `results/power_l2/`). Spiker+ on the same chip and weights: 818 µs, 254.5 µJ.
- Real time: every 3 ms sensor window processed within 4.5 µs (HUSH) in RTL simulation (`results/realtime/realtime.md`).
- Safety arithmetic proved formally at the implementation's widths (`formal/fv_width.sv`); per-timestep guarantee vs whole-recording drift measured (`results/drift.json`).
- Paper A draft: `paper/hush_paperA.tex` (IEEEtran, 5 pages, revised after an external review). See `progress.md` and `docs/plan_nov2026.md`.

| Path | Contents |
| --- | --- |
| `progress.md` | Resume point: current state, decisions log, Paper A / B task tables, full subtask log |
| `study.md` | Defense / conference study checklist |
| `docs/` | Proposal, tier-1 plan (+ 27 Oct update), Theorem 1′, headroom model, design notes, literature notes |
| `golden/` | Integer golden models: FF LIF (`hush.py`), recurrent adLIF (`hush_rec.py`), axonal delays (`hush_delay.py`) |
| `tests/` | Hypothesis property tests of the safety invariants (`pytest -q tests/`) |
| `train/` | Integer-faithful trainers (FF, recurrent adLIF, delays; gate in the loop) |
| `rtl/` | SystemVerilog (`hush_arith.sv`, `hush_layer.sv`, `hush_net.sv` whole network + stream front-end), testbenches, exact cycle models, regression |
| `formal/` | SymbiYosys proofs of the safety arithmetic |
| `fpga/` | Vivado non-project flow, board top, constraints, build scripts |
| `scripts/`, `results/` | Experiment scripts and measured results (current hardware results: `results/power_l1/`, `results/power_l2/`, `results/net_latency.md`; hidden-layer-only `results/power_saif_v5/`; `results/vivado_2024_1/` and `results/power_saif/` are superseded) |

Comparison report v3, 11 Nov (vs state-of-the-art FPGA SNN accelerators): https://claude.ai/artifact/PHRvGNYWhkn9HiMooEmfsR
