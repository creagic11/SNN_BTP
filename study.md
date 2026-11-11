# HUSH v2 — Study Checklist for Defense and Conference

> **State: 11 Nov 2026.** Current numbers are in `docs/primer.md` §0 and §7 (whole network on chip). Items below that still quote the 28 Oct "v5" hidden-layer numbers are marked *superseded*; learn the history (primer §8) but quote only the current numbers. Suggested order for a first full pass: primer §0 → Phases 0–2 here → Phase 4 → Phase 5 → Phase 6 → Presentation drills.

> Learn the project from `docs/primer.md` first; use this checklist after each primer section to test yourself and to go deeper (each item names the repo file with the detail).

Work through this in order. Each item says what you must be able to do at the board without notes. Items are added as the project reaches each phase; the repo file that holds the material is given in brackets.

## Phase 0 — Foundations and the core idea

### A. SNN basics
- [ ] Write the discrete-time LIF update with soft reset (reset by subtraction) and explain why soft reset preserves supra-threshold residue. [`docs/proposal_v2.md` § Formulation]
- [ ] Explain the shift-subtract leak L(x) = x − (x >> k): which λ it implements, why it needs no multiplier, and what floor rounding does to negative values.
- [ ] Explain rate coding vs event (DVS / cochlea) inputs: what MNIST, N-MNIST and SHD each look like as spike rasters.
- [ ] Explain surrogate-gradient training (BPTT, fast-sigmoid / arctan surrogates) in two minutes.
- [ ] Explain INT8 weight quantization and why the trained network and the hardware must share one integer kernel.

### B. The three sparsity axes (the positioning slide)
- [ ] Draw the taxonomy: static weight sparsity, dynamic input-spike sparsity, dynamic output-state sparsity. Name one paper per axis.
- [ ] Explain why pruning membrane-state *memory traffic* is useless (O(N) vs O(N·M)), and why using state to skip *weight fetch* is not.
- [ ] Explain why unstructured per-neuron skipping collapses at block level: ρ = 1 − (1 − q)^B, with a worked number.

### C. The HUSH envelope and its proof (the heart of the defense)
- [ ] Define the signed proxy P_{j,c} = max_{i∈c} W_ij and the envelope Ê_c(t) = sat(L(R_c(t−1)) + max(0, D_c(t))).
- [ ] Prove Lemma 1 (L is non-decreasing on integers) in two lines.
- [ ] Prove Theorem 1 (V_i ≤ R_c and U_i ≤ Ê_c) by induction, covering the awake case, the gated case and saturation.
- [ ] State precisely what "exact mode" guarantees and what it does **not** (gated model ≠ plain LIF; dropped sub-threshold drive).
- [ ] Prove Corollary 2: max(0, ΣP) ≤ Σ max(0, P), i.e. signed proxies are tighter than v1.
- [ ] Explain Corollary 3 (hierarchy, 8-neuron sub-blocks inside 32-neuron blocks).
- [ ] Explain the predictive mode (θ_h > θ) and its link to SnaPEA's predictive mode.
- [ ] Be ready for the reviewer question: "Why not gate per neuron?" (routing, BRAM word width, scheduler cost).

### D. Prior art you must be able to compare against
- [ ] Spiker / Spiker+: dense clock-driven LIF on Zynq-7020; numbers for MNIST and SHD; why clock-driven won at small scale.
- [ ] Cerebron: two-step spike-bitmap × weight masking; channel-wise workload scheduling.
- [ ] FireFly-S: bitmap dual-side sparsity detector; 4-bit weights.
- [ ] DeepFire2: dense, deeply pipelined, multi-die mapping; no sparsity.
- [ ] NPTD (Lew et al. 2023): membrane-threshold neuron pruning on a 65 nm ASIC; why it is lossy.
- [ ] SPARSH: hashed sparse weights, Bloom filter, refractory-neuron skipping.
- [ ] SnaPEA: sign-sorted early termination for ReLU CNNs; exact vs predictive.
- [ ] Early (ICCD 2024): magnitude-sorted weights, early fire and early exit against V_sth; heuristic, 0.54% loss. [`docs/literature/novelty_check.md`]
- [ ] SITRA (ISLPED 2025): weight-MSB PIM score predicts silent outputs and skips their weight fetch; detection overlapped with the previous token. **The closest prior art — know it cold.**
- [ ] PS4 (ICCD 2024): time-window popcount speculation plus error recovery; why it is composable with HUSH.
- [ ] C-STEP (DATE 2026) and the TCAS-I 2025 DVS accelerator: temporal early exit, i.e. stopping the whole inference, which is a different axis from neuron gating.
- [ ] Be able to fill the mechanism table (predictor, guarantee, granularity, state use, platform) for Early, SITRA, PS4 and HUSH from memory.

### E. Artix-7 hardware facts used in the design
- [ ] RAMB36 geometry: 36 Kb, aspect ratios, 512×72 SDP mode; why 8 INT8 weights + 8 spare bits fit one column.
- [ ] Why one 256-bit weight word = four RAMB36 columns = four 8-neuron sub-blocks.
- [ ] Count the BRAM budget for 784×400 INT8 weights (80 RAMB36) and the proxy table (12 RAMB36) on an XC7A100T (135 RAMB36).
- [ ] Explain BRAM enable gating vs clock-enable vs BUFGCE clock gating, and which saves dynamic power on Xilinx parts.
- [ ] Explain why Fmax drops with deep BRAM cascades and why 100 MHz is the target.

## Phase 0 — Feasibility results (added after T0.4–T0.8)
- [ ] How the golden models REF, GATED and ORACLE differ, and why ORACLE is a lower bound on ρ. [`golden/hush.py`]
- [ ] Why saturating (clipping) registers does not break Theorem 1: the same non-decreasing clip on U and Ê preserves ≤. [`tests/test_hush.py::test_saturation_never_wraps`]
- [ ] What property-based testing (Hypothesis) checks and why a mutation test (unsafe mean proxy → violations) shows the tests have teeth.
- [ ] Your measured ρ numbers before and after clustering, and what envelope efficiency ρ_ORACLE/ρ means. [`results/rho_unclustered.md`]
- [ ] Why the envelope failed on rate-coded MNIST: the drive gap Σ_{j∈S}(max_i W_ij − W_ij) grows linearly with active inputs per step (≈5.8 units × 90 inputs ≈ 8θ); and why the ORACLE itself keeps most 32-neuron blocks awake at an 18.7% hidden firing rate.
- [ ] The block-occupancy formula ρ_blk = 1 − (1 − q)^B applied to your own measured firing rate.

## Phase 0 — Regime study lessons (T0.9)
- [ ] Why awake fraction per (block, timestep) misleads and why savings must be weighted by active inputs (column reads, cycles). [`results/regime_study.md`]
- [ ] The cycle model with three overlapped engines: envelope of t+1, PE pass of t, leak sweep: max(n_{t+1}, A_t(n_t+1), G).
- [ ] Why dropping sub-threshold drive costs accuracy on temporal tasks (SHD: the oracle alone loses 11 points).
- [ ] Exact resync vs carried bound: why the carried v1 bound accumulates up to 2^k × the per-step drive error while asleep, and why the leak sweep makes the exact max V available for free.
- [ ] Mean-field hibernation: asleep neurons add the shared sub-block drive Q_jc = floor(mean_i W_ij) without fetching their own weights; prove Q ≤ P keeps U ≤ Ê < θ.
- [ ] The control experiment logic: an ungated network trained to the same low firing rate separates "sparser firing" from "gating" as the cause of accuracy loss.

- [ ] The G0 decision and its evidence: why rate-coded MNIST is a negative regime and SHD / N-MNIST are positive ones. [`results/G0_report.md`]

## Phase 1 — Training co-design (added at T1.x)
- [ ] Straight-through estimator for the gate; subgradient through max for P. How the trainer's gated forward pass was checked bit-exact against the golden model (`scripts/check_bitexact_gated.py`).
- [ ] The envelope-drive loss mean_c Σ_j r_j·relu(P_jc)/θ: what it penalises and why its gradient only reaches the arg-max neuron.
- [ ] The exceedance and dispersion losses: what each pushes and why it lowers ρ.
- [ ] Reading an accuracy-vs-ρ Pareto front.

## Phase 2 — Microarchitecture and verification (added at T2.x)
- [ ] Draw the datapath from memory, including the overlap of envelope(t+1) with PE(t).
- [ ] Derive the exact cycle model (`rtl/sim/cycle_model.py`): awake block 4 + (n_t + 4) since v5 (4 + (n_t + 3) before the 28 Oct event-index register), asleep block 3, COMBINE stalls until the envelope bank for t is ready; and the speedup bound min(G, 1/ρ).
- [ ] Explain why HUSH is never slower in cycles than BASE but can cost more energy at ρ ≈ 1.
- [ ] Walk through `rtl/hush_layer.sv`: ETU 3-stage pipeline and double-buffered banks; combine; block loop states SEL/LOAD/RUN/FIN/FIN2 (two-stage finalize since 27 Oct) and the 3-cycle asleep pass; the R refresh through a registered word and a balanced two-stage max tree; why accumulators are 18 bits (|D| ≤ 578 × 127 < 2^17) and the clip happens once.
- [ ] How the RTL is checked bit-exact: `rtl/sim/run_case.py` compares every block write-back (spikes + state) and the counters with the golden model.
- [ ] Explain bounded model checking vs k-induction, and what the SymbiYosys proof covers.

## Phase 3 — Power methodology (added at T3.x)
- [ ] Timing closure story: three critical paths found and fixed (lane + serial max in one cycle → pipelined R refresh → two-stage finalize → balanced two-stage max tree); why each change is bit-exact and why R's late write is safe (read ≥ 3 cycles later at COMBINE).
- [ ] Vectorless vs SAIF vs board power: why vectorless charges HUSH's extra logic and cannot credit skipped reads; why static power (~100 mW) makes energy track latency on the XC7A100T.
- [ ] Our numbers by heart (**current, 11 Nov, whole network**): BASE 98.21 % / 7,745 LUT / 80 BRAM / 279.5 µs / 152 mW / 42.5 µJ; HUSH 13,885 LUT / 95 BRAM; gentler 96.54 % / 159.8 µs (1.75×) / 23.7 µJ (−44 %); gentle 95.74 % / 114.9 µs (2.44×) / 18.4 µJ (−57 %); aggressive (6 ep) 92.32 % / 82.9 µs (3.39×) / 14.4 µJ (−66 %); Spiker+ 818.4 µs / 311 mW / 254.5 µJ; 100 MHz met. (*Superseded, never quote:* v5 hidden-layer numbers 3.8k LUT / 303 µs / 44 µJ and 9.8k / 153 µs / 23 µJ; v1's pruned 1.3k-LUT BASE.) [`docs/primer.md` §7, §8]
- [ ] SAIF-based power estimation: what it captures, what it misses.
- [ ] Differential board measurement: why static power cancels; error bars.

## Tier-1 P1 — recurrence, adaptation and the generalised proof (added 26 Oct)
- [ ] Integer adLIF equations (V, w, a, b, k, kw, sa) and what each costs in hardware per neuron per step.
- [ ] Theorem 1' in four lines: B = L(V) − w is known before inputs; z ≥ 0 so z·W ≤ z·P; monotone clip; saturation flag (`docs/theorem1_prime.md`).
- [ ] Why recurrence costs the proof nothing: recurrent spikes are just extra input rows of Wc.
- [ ] Why the saturation flag is needed once D can be negative (and not with the v1 rule).
- [ ] Lemma 2: Jury criterion for the (V, w) map; why a < 0 explodes; why our update is symplectic Euler (Baronig et al. 2025).
- [ ] Negative results you can quote: signed-D gate gives no gain on co-trained FF nets; learned grouping is absorbed by co-training (tied maxima 11% → 54%).
- [ ] Lemma 3: the reset-path BPTT factor 1 − θσ′, and why bounding it (θ/2) still trained worse than θ/4: a stability bound is not a learning recipe. Be ready to show the round-1 ablation table.
- [ ] Clamped hibernation: why min(A_i, D_c) makes any asleep-drive approximation safe; why a better post-hoc approximation can lower accuracy (the trained net is the gated net).
- [ ] Readouts: mean-U vs max-over-time (Cramer et al.); why max-over-time is a one-register-per-class integer decision and trained smoothly. Honest numbers: recurrent adLIF 83.1% under the validation protocol (the 87.0% seen once was a best-*test* epoch and is not admissible — know why).
- [ ] Recurrent envelope drain: why spikes are final only at BLK_FIN (input-serial dataflow, signed weights, 0.40 false crossings per spike), why a wrong negative proxy row is unsafe, and the overlap + dual-port + awake-first schedule (tail 6.6% → 0.46%).
- [ ] Why HUSH fails on recurrent adLIF: the gate exploits hyperpolarisation headroom (FF: 9.7θ; recurrent adLIF: 0.09θ); subthreshold adaptation and recurrent excitation keep the top neuron of each sub-block near threshold. Quote the gated co-training table (reads 0.98).
- [ ] Axonal delays: why per-input delays keep Theorem 1 unchanged (delay line on the event stream) while per-synapse delays (DCLS) expand the envelope inputs to (input, delay) taps; hardware cost = dmax-slot event ring buffer per layer input.
- [ ] Training delays: hard integer forward + soft (Gaussian → triangular) backward; why the forward must stay hard (golden equivalence).
- [ ] Folding BatchNorm into INT8 weights + bias current + per-layer θ; why the bias current is drive-free (part of B) and keeps the HUSH proof.
- [ ] Headroom model (`docs/headroom_model.md`): steady headroom ≈ θ + 2^k·|b|; HUSH sleeps when headroom exceeds n_t·E[P⁺]; why fast leaks (delay nets) and subthreshold adaptation (adLIF) defeat gating while the slow-leak FF net gated well.
- [ ] The four-network headroom table and the k = 4 controls (gate alone −6.7 pt vs rate reg alone −0.5 pt): be ready to say exactly when HUSH pays and when it does not.
- [ ] SHD reference numbers: SE-adLIF 1 layer 37.5k params 94.6%, 2 layers 95.8%, LIF 90.3% (float, no hardware).

## Comparison against the state of the art (added 27 Oct — Paper A)
- [ ] The four levels of comparison and what each proves: internal ablation (BASE vs HUSH), competing ideas in the same setting (SITRA-inspired / Early-style predictors, exploratory), same-device external baseline (Spiker+, done: 818 µs, 254.5 µJ), published SOTA table.
- [ ] Normalised metrics and why raw LUT/power numbers across papers mislead: energy per inference, energy per (dense-equivalent) SOP, throughput per kLUT, latency.
- [ ] *Superseded by the Phase 3 item above and primer §7.2 (kept for history).* Hardware table (v5, Vivado 2024.1, XC7A100T, 100 MHz met): BASE 3,821 LUT / 2,643 FF / 43 RAMB36 / 0 DSP / 145 mW (45 dynamic) / 302.9 µs / 43.9 µJ; HUSH-MF 9,800 LUT / 6,284 FF / 57 RAMB36 + 2 RAMB18 / 0 DSP; gentle 95.32% / 151 mW / 153.0 µs / 23.1 µJ (1.98×, −47%); aggressive 92.72% / 157 mW / 97.2 µs / 15.3 µJ (3.12×, −65%). Whole network, 500 samples; power = gate-level SAIF on the hidden-layer build.
- [ ] The N-MNIST SOTA rows (paper Table VII): Cheng et al. (ZCU104, 98.11 %, 81.3k LUT), FeNN-DMA (KV260, 98.46 %, 55.0k), Surrogates (xcvu9p, 96.4 %, 5.9 ms, 0.31 W ≈ 1.83 mJ), Wu, Song & So (ZCU102, 95.76 %, 50 ms, 0.33–0.37 W ≈ 17.5 mJ). Ours: 37–435× lower latency, 77–950× lower active energy, 3.8–5.6× fewer LUTs than Cheng / FeNN-DMA (2.7–11.3× vs Wu) — and why those ratios reflect different networks, devices and methods, not HUSH alone.
- [ ] MNIST-class rows for scale: Ansari & Wielgosz 2026 (Artix-7 200T, 96.7%, 82 µs, ≈ 27.6 µJ), Spiker-LL 2026 (39 µJ), Spiker+ 2024 (780 µs, ≈ 140 µJ). SHD rows: Chen et al. 2025 93.4% (delays, 9.6 ms), Spiker+ 72.99%.
- [ ] Our honest weak points and the answer to each: accuracy (−1.7 to −5.9 pt vs the equally trained BASE); area (+79 % LUT, +19 % BRAM; LUT × latency gains only 3 / 26 / 44 %); power is a gate-level activity-based estimate → board when available; one dataset, one small network, one sub-block size; real time by RTL replay of 4 recordings.
- [ ] Why the GPU and the Nexys A7-100T are needed, in one sentence each (accuracy gap / measured power).

## Presentation drills
- [ ] 3-minute elevator pitch with one figure.
- [ ] Answer: "Isn't this just SnaPEA for SNNs?"
- [ ] Quote the T1.5 table (`results/heuristic_gates.md`) and its two caveats.
- [ ] Answer: "SITRA already skips weight fetches for silent outputs. What is new?" (guarantee, carried state bound, BRAM-matched blocks, FPGA silicon)
- [ ] Answer: "Your gated network is not the network you trained — so what is your accuracy claim?"
- [ ] Answer: "Why should energy fall if the envelope unit runs every timestep?"
- [ ] Answer: "Did you try clustering neurons into better groups?" (yes: no gain after co-training, and why)
- [ ] Answer: "Your HUSH design has 79 % more LUTs than BASE — where is the win?" (latency 1.75–3.39×, active energy −44 to −66 %; LUT × latency still improves 26 % for gentle and 44 % for aggressive, but only 3 % for gentler — say so; the design uses 22 % of the device)
- [ ] Answer: "Your energy numbers are estimates." (yes: gate-level activity-based, 100% nets matched, but Vivado's model without glitch power; the board measurement A7 replaces it — say exactly what each adds)

## A3 power results (28 Oct) — method still valid, numbers superseded by Phase 4
- Why the earlier numbers were thrown away: (1) the LED fold only observed lanes 0-5/26-31, so synthesis deleted most of BASE; (2) ROM tables let synthesis trim INT8 weights to 6 bits; (3) the sub-block column gating existed only in a counter; (4) a test-harness ROM added 10k LUTs to HUSH only. A reviewer finding any one of these would reject the comparison.
- How power is measured: post-route functional netlist simulated in xsim over 20 N-MNIST samples → SAIF of every net → read_saif (100% nets matched, confidence High) → report_power. Zero-delay activity, so glitch power is not included; it is an estimate, not a board measurement.
- Why BRAM dynamic power is only 11-14 mW: each read enables one BRAM (ram_decomp = "power" splits deep RAMs by address) and HUSH reads only the weight columns of awake sub-blocks.
- Headline (current): at +3–8 % power, HUSH cuts latency 1.75–3.39× and active energy per inference by 44–66 % (dynamic energy alone 41–62 %) against the same-chip baseline. Costs: +79 % LUTs, +19 % BRAM (P/Q tables, envelope unit, sub-block control).
- Static power (~101 mW) is the XC7A100T's and dominates total power; the energy gain comes from finishing sooner as well as from switching less.

## Phase 4 — Whole network, real time, paper (added 11 Nov 2026)

- [ ] Explain how the output layer runs one timestep behind the hidden layer through a spike FIFO and a drain, and why the output layer then costs only ≈ 0.3 µs extra. [`rtl/hush_net.sv`, `rtl/sim/net_cycle_model.py`]
- [ ] Explain the stream front-end: 2×2 pooling, per-window de-duplication, ring of 1,024 events, end-of-window marker, and why markers need reserved FIFO space. [`rtl/hush_net.sv`, progress.md 10 Nov]
- [ ] State the real-time guarantee in sensor time (worst window 4.5–6.6 µs of 3 ms) and the separate throughput metric (750× BASE vs 1,000× HUSH on the heaviest recordings). Explain why HUSH helps the average window but not the busiest one. [`results/realtime/realtime.md`]
- [ ] Explain why the fair baseline is the 22-epoch ungated net (98.21 %), and what the control fine-tune showed about early decisions. [`results/net_latency.md`, `results/realtime/early_decision.json`]
- [ ] Explain why HUSH draws 3–8 % more power but 44–66 % less energy per inference, and why Spiker+ spends 140 mW in BRAM. [`results/power_l1/README.md`]
- [ ] Explain what Theorem 1 does and does not guarantee end to end ("from the same state"). [`paper/hush_paperA.tex` § III]
- [ ] Explain why energy at sensor speed is ≈ 30 mJ per recording for both designs (static power) and where HUSH's energy gain appears instead. [`paper/hush_paperA.tex` § VII]

## Phase 5 — Answers to the external review (added 11 Nov 2026)

- [ ] State the two properties exactly: (A) per-timestep spike equality with the ungated update from HUSH's own state (proved); (B) trajectory equivalence with an ungated run (not guaranteed). Quote the measured numbers (0 violations of A; divergence from window 4; 90–96 % same class; ungated run of the same weights emits 553 vs 304 hidden spikes for gentle; gentle 94.8 % gated vs 93.5 % ungated). [`results/drift.json`, paper § III]
- [ ] Explain the two formal checks: full-width inductive step (VB 16, AB 18) and reduced-width sequential PDR; why "no wrap-around" needs the 8-bit-wider reference. Derive the 18-bit accumulator bound 2¹⁵ + 128·578. [`formal/README.md`]
- [ ] Explain why the power and stream builds differ in BRAM (20 stored recordings vs a 1,024-event ring) and what HUSH adds in both. [`results/resources.md`]
- [ ] Explain why HUSH's weight-memory traffic is 0.32–0.45 of BASE while its column reads are 0.07–0.20 (2 B of P/Q per sub-block and input). [paper Table II note]
- [ ] Explain "active energy per inference" vs always-on energy at sensor speed (< 0.03 % saving). [paper § VII]
- [ ] Describe Early, SITRA and PS4 each by its own mechanism and accuracy cost. [paper § II]

## Phase 6 — Second review and final strict pass (added 11 Nov 2026, night)

- [ ] Say which point was trained for 6 epochs (aggressive) and which for 12 (gentler, gentle), and why BASE is the 22-epoch net. [`docs/primer.md` §4.1–4.2]
- [ ] Explain why the gated network is "a network in its own right", not an approximation of an ungated one, using the drift table (spike counts, and gentle / aggressive accuracy *falling* when the gate is removed). [`results/drift.json`, primer §3.4]
- [ ] State exactly what the full-width formal check assumes (V_i ≤ R_c; drive ≤ D_c; q_c ≤ D_c; bounded drives), how the drive assumption is discharged (construction of P and Q + bit-exact simulation), and what is outside the proof (R max tree, second finalise stage, memories, sequencing). Explain why F5 is only a sanity check and why the m256 task matters only for no-wrap. [`formal/README.md`]
- [ ] Derive the real-time energy at a common speed: 750× → 0.40 ms per recording → BASE 101 mW × 0.40 ms + 14.3 µJ = 54.7 µJ; HUSH 102 mW × 0.40 ms + 6.7 µJ = 47.5 µJ (−13 %); HUSH at 1,000×: 37.3 µJ. Explain why comparing the designs at different speeds was wrong. [primer §7.6]
- [ ] Explain the energy split: two thirds of BASE's 42.5 µJ is static power × latency; dynamic energy falls 41–62 %; so most of the saving is "finish sooner". [paper Fig. 5, primer §7.2]
- [ ] Compute LUT × latency for each point and explain why gentler gains only 3 %. [primer §7.2]
- [ ] Read each new figure aloud in one sentence: Fig. 3 schedule, Fig. 4 accuracy vs latency, Fig. 5 energy split, Fig. 6 cycles per window vs activity, Fig. 7 replay sweep. [`scripts/fig_paper.py`]
- [ ] Explain the speedup-vs-activity table (2.22× at 1–9 active inputs → 1.59× at ≥ 60) and what it predicts for a denser sensor. [`results/realtime/stream_stats.md`]
- [ ] Explain how SnaPEA's exact mode differs from HUSH (per neuron vs per sub-block; reads weights until the stop vs decides before any read; no state vs carried maximum; CNN vs SNN). [paper §II]
- [ ] Give the three caveats of the heuristic-predictor table (trained for HUSH; one seed; Early-style charge is a lower bound and the SITRA-inspired one is not SITRA's predictor and not matched exactly). [`results/heuristic_gates.md`]
- [ ] Explain "column reads" (0.07–0.20) vs "weight-memory traffic" (0.32–0.45) and which one to quote when. [primer §7.1]
- [ ] List the superseded numbers and why each was dropped. [primer §8]
- [ ] Use the paper → repo map to find, for any number in the paper, the script and result file behind it. [primer §12]
