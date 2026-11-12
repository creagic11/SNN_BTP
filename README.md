# SNN_BTP — HUSH: provably safe sub-block hibernation for SNN accelerators

B.Tech thesis project, IIT Kharagpur (Anubhav Jha; supervisor Prof. Rajat Subhra Chakraborty).

HUSH puts a group of 8 neurons to sleep for a timestep only when an integer bound **proves** that none of them can fire, and then skips their weight reads. Target: Xilinx Artix-7 XC7A100T, 100 MHz.


## Status (11 Nov 2026)

Whole 578-256-10 network on chip, N-MNIST, three training seeds:

| Design | Accuracy | Latency | Speedup | Active energy / inference | LUT / BRAM |
| --- | --- | --- | --- | --- | --- |
| BASE (same RTL, gate off, trained equally long) | 98.21 ± 0.13 % | 279.5 µs | 1.00× | 42.5 µJ | 7,745 / 80 |
| HUSH gentler | 96.54 ± 0.07 % | 159.8 µs | 1.75× | 23.7 µJ (−44 %) | 13,885 / 95 |
| HUSH gentle | 95.74 ± 0.07 % | 114.9 µs | 2.44× | 18.4 µJ (−57 %) | 13,885 / 95 |
| HUSH aggressive (6 epochs) | 92.32 ± 0.68 % | 82.9 µs | 3.39× | 14.4 µJ (−66 %) | 13,885 / 95 |
| Spiker+ (same chip, BASE's 10-epoch weights) | 97.53 % | 818.4 µs | 0.34× | 254.5 µJ | 13,548 / 70.5 |

- **Safety:** at every timestep the gated layer emits exactly the spikes of the ungated update from its own state (Theorem 1). The envelope and lane arithmetic is proved formally at the implementation's bit widths (`formal/fv_width.sv`). Trajectories over a whole recording do differ from an ungated run; this is measured (`results/drift.json`) and is why the gate is trained into the network.
- **Verification:** RTL bit- and cycle-exact against the integer golden model (random regressions, N-MNIST, stream mode).
- **Power:** Vivado estimate from gate-level switching activity of the routed netlist (`results/power_l1/`, `results/power_l2/`); not a board measurement. Energy is active energy (power × latency).
- **Real time:** in RTL replay at recorded sensor timing every 3 ms window is processed within 4.5 µs (HUSH) / 6.6 µs (BASE); with the same 1,024-event buffer BASE keeps up to 750× real time, HUSH gentle to 1,000× (`results/realtime/realtime.md`).
- **Cost:** 1.7–5.9 points of accuracy, +79 % LUTs, +19 % block RAM.
- **Paper A:** `paper/hush_paperA.tex` / `.pdf` (IEEEtran, 7 pages with references, 8 figures, 7 tables), revised after three review rounds. Venue not yet chosen.
- **Open:** board power measurement (needs the board and a power meter); Paper B on convolutional layers and DVS-Gesture (needs a GPU).

## Layout

| Path | Contents |
| --- | --- |
| `docs/primer.md` | The project from scratch: idea, proof, training, hardware, verification, results, history, hard questions, paper → repo map |
| `study.md` | Defense / conference study checklist (Phases 0–6) |
| `progress.md` | Dated log of every step and decision; task tables |
| `docs/` | Plan (`plan_nov2026.md`), proposal, Theorem 1′, headroom model, design notes, literature tables |
| `paper/` | Paper A source, bibliography, figures, outline with the source of every figure and table |
| `golden/` | Integer golden models: feed-forward LIF (`hush.py`), recurrent adLIF (`hush_rec.py`), axonal delays (`hush_delay.py`) |
| `tests/` | Hypothesis property tests of the safety invariants (`pytest -q tests/`) |
| `train/` | Integer-faithful trainers with the gate in the loop |
| `rtl/` | SystemVerilog: `hush_arith.sv`, `hush_layer.sv`, `hush_net.sv` (whole network + stream front-end), testbenches, exact cycle models, regression |
| `formal/` | SymbiYosys proofs: full-width inductive step (`fv_width`), reduced-width sequential (`fv_hush`), mutants |
| `fpga/` | Vivado non-project flow, board top, constraints, laptop run scripts (`run_l1.bat`, `run_l2.bat`) |
| `spikerplus/` | Spiker+ baseline: generated VHDL, wrapper, build scripts |
| `scripts/` | Experiment, analysis and figure scripts (`fig_paper.py`, `fig_early.py`, `drift.py`, `heuristic_gates.py`, …) |
| `results/` | Measured results. Current: `net_latency.md`, `power_l1/`, `power_l2/`, `resources.md`, `realtime/`, `drift.json`, `heuristic_gates.md`, `acc_integer.json`. Superseded: `power_saif_v5/` (hidden layer only), `vivado_2024_1/`, `power_saif/` |

Comparison report (vs state-of-the-art FPGA SNN accelerators): https://claude.ai/artifact/PHRvGNYWhkn9HiMooEmfsR
