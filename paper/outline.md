# Paper A — outline and figure/table list (state: 11 Nov 2026, after three review rounds)

Title: **HUSH: Provably Safe Sub-Block Hibernation for Real-Time Event-Driven SNN Inference on FPGAs**
Authors: Anubhav Jha and Rajat Subhra Chakraborty, Indian Institute of Technology Kharagpur (departments to add).
Format: IEEEtran conference, 7 pages with references (≈ 6.5 without). Limit set by the user: 8 pages without
references. Venue not chosen (a TCAS-II brief would need cuts).

Rule for every number: it comes from a file in `results/` (column "Source").

## Claims, in order of strength

1. **Safety (scoped).** At every timestep the gated layer emits exactly the spikes of the ungated update from its
   own state (Theorem 1). The envelope and lane arithmetic is proved at the real bit widths under the assumption
   drive ≤ D_c, which holds by construction of the proxy table. Trajectory equivalence with an ungated run is
   *not* claimed; the difference is measured.
2. **Same-chip efficiency.** Against the same RTL with the gate off, trained equally long (98.21 %): gentler
   96.54 %, 1.75×, −44 % active energy; gentle 95.74 %, 2.44×, −57 %; aggressive (6 epochs) 92.32 %, 3.39×, −66 %.
   Cost: +79 % LUT, +19 % BRAM. Spiker+ on the same chip with BASE's 10-epoch weights: 818 µs, 254.5 µJ.
3. **Real time.** RTL replay of four recordings at recorded timing: every 3 ms window within 4.5 µs. Same
   1,024-event buffer: BASE to 750×, HUSH gentle to 1,000× real time. Energy at a common 750×: 54.7 vs 47.5 µJ.
4. **Published designs.** 37–435× lower latency, 77–950× lower active energy, 3.8–5.6× fewer LUTs; not like for
   like, and the paper says so.
5. **Limits.** Accuracy and area cost; speedup falls with activity (2.2× → 1.59×); estimated power; one dataset,
   one small network, one sub-block size; replay, not a live sensor.

## Sections, figures and tables

| § | Content | Figures / tables | Source |
|---|---|---|---|
| I Introduction | weight fetches dominate; output-side skipping is hard; three contributions | — | — |
| II Background and related work | integer LIF; clock-driven FPGA designs (Spiker, Spiker+, FireFly); Early, SITRA, PS4; SPARSH, C-STEP, Cheng; SnaPEA exact mode | — | `docs/literature/` |
| III The HUSH gate | sub-blocks, P and Q, envelope, Theorem 1, mean-field drive q_c, (A) vs (B) with drift numbers, training penalties | Fig. 1 scope of the guarantee | `golden/hush.py`, `results/drift.json` |
| IV Architecture | hidden layer and cycle cost, whole network, stream front-end | Fig. 2 datapath (two-column), Fig. 3 schedule of one timestep | `rtl/hush_layer.sv`, `rtl/hush_net.sv`, `rtl/sim/net_cycle_model.py` |
| V Verification | bit-exact RTL, two formal checks and their scope, gate-level cycle check | Table I widths and ranges | `formal/README.md`, `results/net/` |
| VI Results | setup; accuracy–savings front; same chip (resources, energy split, area × time, Spiker+); heuristic predictors (exploratory) | Table II training, Table III accuracy/latency, Fig. 4 accuracy vs latency, Table IV hardware, Table V resources, Fig. 5 energy split, Table VI predictors | `results/acc_integer.json`, `results/net_latency.md`, `results/power_l1/`, `results/power_l2/`, `results/resources.md`, `results/heuristic_gates.md` |
| VII Real-time operation | stream statistics; sensor timing; energy at sensor speed and at a common replay speed; replay sweep; early decisions | Fig. 6 cycles per window vs activity, Fig. 7 replay sweep, Fig. 8 accuracy vs elapsed time | `results/realtime/stream_stats.md`, `results/realtime/realtime.md`, `results/realtime/early_decision.json` |
| VIII Comparison with the state of the art | four published N-MNIST FPGA designs with comparability caveats | Table VII | `docs/literature/nmnist_dvs_fpga.md` |
| IX Limitations and conclusion | limits listed above; code availability | — | — |

Figures 4–7: `python scripts/fig_paper.py`. Fig. 8: `python scripts/fig_early.py`. Figs. 1–3 are TikZ in the source.

## Review history (details in `progress.md`)

1. 10 Nov — internal fresh-eyes review, 20 items (number audit, objections).
2. 11 Nov — external review: scope of the safety claim, full-width proof, resource reconciliation, traffic
   including P/Q reads, heuristic comparison with charged reads, energy and real-time wording, reproducibility.
3. 11 Nov — second fresh-eyes review: aggressive point is 6 epochs, drift reported in full, proof scope narrowed,
   real-time energy at a common speed, 6-epoch-derived figures replaced, references completed.
4. 11 Nov — final strict pass: area cost up front, energy attribution, area × time, SnaPEA, limitations, five new
   figures, TrueType fonts in figures.

## Open before submission

- Venue, template and page limit; departments in the author block.
- Check the SnaPEA entry in `paper/refs.bib` (authors, pages, DOI) against the published record.
- Optional: aggressive point at 12 epochs (training here, power on the laptop).
- Not in Paper A: board power (A7), convolutional layers and DVS-Gesture (Paper B).
