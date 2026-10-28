# SNN_BTP — HUSH: provably safe block hibernation for SNN accelerators

B.Tech thesis project (IIT Kharagpur, EE; supervisor Prof. Rajat Shubhra Chakraborty).

HUSH puts a group of 8 neurons to sleep for a timestep only when an integer bound **proves** that none of them can fire. It then skips their weight reads on a Xilinx Artix-7 (XC7A100T).

**Status (28 Oct 2026):**

- Safety is formally proven on the RTL (SymbiYosys PDR) and property-tested on the golden models.
- RTL (v5: writable RAMs with a UART load port, per-sub-block weight-column enables) is bit-exact against the golden model, and all variants meet 100 MHz after Vivado place and route.
- On N-MNIST, HUSH runs 1.98–3.12× faster than the identical ungated design with 47–65% less energy per inference (gate-level activity-based power; `results/power_saif_v5/`).
- Current plan: Paper A (tier-2) now, Paper B (tier-1) when a GPU is available. See `progress.md`.

| Path | Contents |
| --- | --- |
| `progress.md` | Resume point: current state, decisions log, Paper A / B task tables, full subtask log |
| `study.md` | Defense / conference study checklist |
| `docs/` | Proposal, tier-1 plan (+ 27 Oct update), Theorem 1′, headroom model, design notes, literature notes |
| `golden/` | Integer golden models: FF LIF (`hush.py`), recurrent adLIF (`hush_rec.py`), axonal delays (`hush_delay.py`) |
| `tests/` | Hypothesis property tests of the safety invariants (`pytest -q tests/`) |
| `train/` | Integer-faithful trainers (FF, recurrent adLIF, delays; gate in the loop) |
| `rtl/` | SystemVerilog (`hush_arith.sv`, `hush_layer.sv`), testbench, exact cycle model, regression |
| `formal/` | SymbiYosys proofs of the safety arithmetic |
| `fpga/` | Vivado non-project flow, board top, constraints, build scripts |
| `scripts/`, `results/` | Experiment scripts and measured results (current hardware results: `results/power_saif_v5/`; `results/vivado_2024_1/` and `results/power_saif/` are superseded) |

Comparison report v2, 28 Oct (vs state-of-the-art FPGA SNN accelerators): https://claude.ai/artifact/PHRvGNYWhkn9HiMooEmfsR
