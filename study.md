# HUSH v2 — Study Checklist for Defense and Conference

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
- [ ] Derive the cycle model C_HUSH = Σ max(n_{t+1}, A_t·n_t) + c and the speedup min(G, 1/ρ).
- [ ] Explain why HUSH is never slower in cycles than BASE but can cost more energy at ρ ≈ 1.
- [ ] Walk through `rtl/hush_layer.sv`: ETU 3-stage pipeline and double-buffered banks; combine; block loop states SEL/LOAD/RUN/FIN and the 2-cycle asleep pass; why accumulators are 26 bits and the clip happens once.
- [ ] How the RTL is checked bit-exact: `rtl/sim/run_case.py` compares every block write-back (spikes + state) and the counters with the golden model.
- [ ] Explain bounded model checking vs k-induction, and what the SymbiYosys proof covers.

## Phase 3 — Power methodology (added at T3.x)
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
- [ ] Readouts: mean-U vs max-over-time (Cramer et al.); why max-over-time is a one-register-per-class integer decision and trained smoothly (82.5 → 87.0%).
- [ ] Recurrent envelope drain: why spikes are final only at BLK_FIN (input-serial dataflow, signed weights, 0.40 false crossings per spike), why a wrong negative proxy row is unsafe, and the overlap + dual-port + awake-first schedule (tail 6.6% → 0.46%).
- [ ] Why HUSH fails on recurrent adLIF: the gate exploits hyperpolarisation headroom (FF: 9.7θ; recurrent adLIF: 0.09θ); subthreshold adaptation and recurrent excitation keep the top neuron of each sub-block near threshold. Quote the gated co-training table (reads 0.98).
- [ ] Axonal delays: why per-input delays keep Theorem 1 unchanged (delay line on the event stream) while per-synapse delays (DCLS) expand the envelope inputs to (input, delay) taps; hardware cost = dmax-slot event ring buffer per layer input.
- [ ] Training delays: hard integer forward + soft (Gaussian → triangular) backward; why the forward must stay hard (golden equivalence).
- [ ] Folding BatchNorm into INT8 weights + bias current + per-layer θ; why the bias current is drive-free (part of B) and keeps the HUSH proof.
- [ ] Headroom model (`docs/headroom_model.md`): steady headroom ≈ θ + 2^k·|b|; HUSH sleeps when headroom exceeds n_t·E[P⁺]; why fast leaks (delay nets) and subthreshold adaptation (adLIF) defeat gating while the slow-leak FF net gated well.
- [ ] The four-network headroom table and the k = 4 controls (gate alone −6.7 pt vs rate reg alone −0.5 pt): be ready to say exactly when HUSH pays and when it does not.
- [ ] SHD reference numbers: SE-adLIF 1 layer 37.5k params 94.6%, 2 layers 95.8%, LIF 90.3% (float, no hardware).

## Presentation drills
- [ ] 3-minute elevator pitch with one figure.
- [ ] Answer: "Isn't this just SnaPEA for SNNs?"
- [ ] Quote the T1.5 table (`results/heuristic_gates.md`) and its two caveats.
- [ ] Answer: "SITRA already skips weight fetches for silent outputs. What is new?" (guarantee, carried state bound, BRAM-matched blocks, FPGA silicon)
- [ ] Answer: "Your gated network is not the network you trained — so what is your accuracy claim?"
- [ ] Answer: "Why should energy fall if the envelope unit runs every timestep?"
- [ ] Answer: "Did you try clustering neurons into better groups?" (yes: no gain after co-training, and why)
