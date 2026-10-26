# HUSH v2 — Progress Log

This file is the resume point. If a session ends, start from the task marked **IN PROGRESS**, then the first **TODO** below it.

- Proposal: `docs/proposal_v2.md` (live copy: Claude Doc "HUSH v2 — Revised BTP Research Proposal")
- Study checklist for the defense: `study.md`
- Zotero collection: "HUSH – Literature" (user library 22138861, collection key FA5TR3KP)
- Compute available in the cloud workspace: 2 CPU cores, 7 GB RAM, no GPU

Status keys: DONE · IN PROGRESS · TODO · BLOCKED

## Current state

- **Last updated:** 2026-10-26
- **Now working on:** Tier-1 P1 (GA, 22 Nov). P1.1 done. P1.2: SHD recurrent adLIF baseline 87.0% (`results/shd_rec_umax`); augmentation run `shd_rec_umax_aug` in progress; then gated co-training (`scripts/sweep_rec_gated.sh`, set INIT to the best baseline and add `--readout umax`). Seed sweep T1.6 paused (SHD-FF seeds deprioritised; N-MNIST seeds to re-run when CPU is free).
- **GitHub:** pushes to `creagic11/SNN_BTP` work (enabled 2026-10-24).

## Phase 0 — Setup, literature, feasibility (target gate G0: 8 Nov 2026)

| ID | Task | Status | Output |
| --- | --- | --- | --- |
| T0.1 | Repo scaffold, progress.md, study.md, proposal copy | DONE | this file, `study.md`, `docs/proposal_v2.md` |
| T0.2 | Novelty check: read Early (ICCD 2024), SPARSH (ICCAD 2025), C-STEP (DATE 2026); update literature table | DONE | `docs/literature/novelty_check.md` |
| T0.3 | Confirm Spiker+ source availability (external baseline) | DONE | note in `docs/literature/novelty_check.md` |
| T0.4 | Integer golden kernel: REF, GATED, ORACLE + property tests of Lemma 1 and Theorem 1 | DONE | `golden/hush.py`, `tests/test_hush.py` |
| T0.5 | Dataset access in the workspace (MNIST, N-MNIST, SHD) | DONE | `scripts/get_data.py` |
| T0.6 | Train ungated INT8 baseline (MNIST 784-400-10 first), export integer weights | DONE | `train/`, `results/baseline_*` |
| T0.7 | Measure ρ before clustering: ORACLE vs HUSH-32 vs HUSH-8/32 | DONE (MNIST) | `results/rho_unclustered.md` |
| T0.8 | Co-inactivity clustering; re-measure ρ; write G0 report | DONE (MNIST); G0 report after T0.9 | `results/rho_unclustered.md` |
| T0.9 | Regime study: ρ and envelope gap vs active inputs per timestep; SHD and N-MNIST at fine time bins; firing-rate regularisation | DONE | `results/regime_study.md` |
| T0.10 | G0 report and go / pivot decision | DONE — GO, narrowed scope | `results/G0_report.md` |

### Subtask log

- 2026-10-24 · T0.1 · Cloned repo (was empty except README). Created folders `docs/ golden/ tests/ train/ rtl/ scripts/ results/`. Wrote progress.md, study.md, proposal copy. Push test: refused (no GitHub App access).
- 2026-10-24 · T0.2 · Read full texts via IEEE Xplore (IIT KGP access) in the browser pane: Early, SPARSH, C-STEP, plus newly found close prior art PS4 (ICCD 2024), SITRA (ISLPED 2025), TCAS-I 2025 DVS accelerator, GustavSNN (HPCA 2026). Added 4 items to Zotero. Verdict: output-side skipping exists (SITRA, Early, PS4) but all heuristic, per neuron, ASIC simulation; HUSH's claim narrows to provable bound + state carried across steps + BRAM-matched blocks + FPGA silicon. Written to docs/literature/novelty_check.md.
- 2026-10-24 · T0.3 · Spiker+ is public: github.com/smilies-polito/Spiker, PyPI `spikerplus`; MNIST, SHD and Vivado tutorials. No LICENSE file: use as baseline only.
- 2026-10-24 · T0.4 · `golden/hush.py`: REF, GATED (signed-proxy envelope, per-sub-block gates, monotone clip to vbits), ORACLE, layer-major `run_network`, integer `predict`. `tests/test_hush.py`: 13 tests, all pass (Lemma 1 exhaustive over ±65536 for k=1..8; Theorem 1, Corollary 1, oracle⇒envelope dominance, register range, gate-on ≡ REF, Corollaries 2–3, saturation) using Hypothesis with 200–400 random layers each. Mutation check: an unsafe mean-proxy gives 6,340 suppressed spikes over 200 layers, so the tests do detect broken gates. Proof note: the clip must be the same monotone function on U and Ê; added to the proof.
- 2026-10-24 · T0.5 · Workspace network reaches PyPI, PyTorch, Hugging Face, zenkelab, S3. Installed torch 2.14.1+cpu, snntorch 1.0.0, tonic 1.7.0. `scripts/get_data.py` downloads to `~/data` (= /root/data, not in git): MNIST 60k/10k; SHD 8,156/2,264, 700 channels, 20 classes; N-MNIST 60k/10k, 34×34×2 (keep the zip files: tonic re-downloads if they are missing).
- 2026-10-24 · T0.6 · `golden/encode.py` (deterministic integer IF rate encoder), `train/qsnn.py` (integer-unit LIF: INT8 STE weights, floor-STE leak, soft reset, fast-sigmoid surrogate), `train/train_mnist.py`. Smoke test: 6k samples, 1 epoch, 76.5% in 5 s. Full run 15 epochs launched; log in `results/train_mnist_400.log`.
- 2026-10-24 · T0.6 · MNIST 784-400-10 INT8: 97.53% test (PyTorch); golden REF bit-exact on 2,000 images (0 mismatches), max |U| 3,415. Input activity 11.8% (~90 inputs/step), hidden rate 18.7%.
- 2026-10-24 · T0.7/T0.8 · `scripts/measure_rho.py`, `scripts/cluster.py` (balanced k-means by weight or co-activity), `scripts/envelope_gap.py`. Result: HUSH gates nothing on rate-coded MNIST (awake every step except t=0). ORACLE ρ_blk 0.80–0.95. Drive gap ≈ 8θ (5.8 units per active input × 90 inputs). G0 FAILS on this workload; see `results/rho_unclustered.md`. Next: regime study (T0.9).
- 2026-10-24 · T0.9 (in progress) · Design fix: with the eager leak sweep the exact V of asleep neurons is known, so R_c = exact max V every step (`LIFParams.resync=True`, default); the v1 carried bound accumulated drive error up to 2^k× while asleep. Tests: 14 pass (new: exact resync never looser than carried bound). `golden/datasets.py` (MNIST, SHD, N-MNIST rasters); `train/train_snn.py` generic trainer with firing-rate regulariser, envelope-drive loss (`--env_lam`), warm start (`--init`). `scripts/measure_rho.py` rewritten: multi-layer, datasets, cycle model with leak sweep, column-read fraction. SHD input stats: distinct active channels per step 88/62/31/16/8 at T = 50/100/250/500/1000. Trained MNIST proxies: mean P8 = 6.7 ≈ 1.4σ_W (σ_W = 4.8). Running: SHD 700-256-20, T=250, k=5, rate target 5% (`results/train_shd_T250.log`).
- 2026-10-24 · T0.9 · SHD baseline 70.8%. Vanilla HUSH-8/32: read frac 0.97, 1.01×; ORACLE costs 11 pts accuracy (drop semantics). Gate-in-the-loop training (`QLinearLIF.gate_benv`, exceedance + envelope-drive losses, `scripts/check_bitexact_gated.py` passes): HUSH-8/32 64.9% full test, read frac 0.26, 1.70× cycles. Sweep running: `scripts/sweep_shd.sh` (4 runs: λ variants, ungated at 1.3% rate, gate without losses). See `results/regime_study.md`.
- 2026-10-24 · T0.9 · Sweep done: reads 0.86/0.68/0.26 at 68.8/68.7/64.9%; gate alone 70.5% at 0.97; control ungated 2.2% rate 69.5% → loss is from gating. Mean-field hibernation (`LIFParams.asleep_drive='mean'`, Q=floor(mean W) ≤ P, test added, trainer bit-exact) does not help at inference only; training runs launched (`scripts/sweep_shd_mf.sh`).
- 2026-10-24 · T0.9 · Mean-field results: mf_e05_d025 70.8% at reads 0.64 (no loss vs baseline); mf_e2_d1 64.4% at reads 0.18, 2.05× cycles. Next: N-MNIST baseline + gated runs (hidden 256, T=100 over 300 ms), then G0 report.
- 2026-10-24 · T0.9/T0.10 · N-MNIST 578-256-10 T=100 k=4: baseline 97.59%; mean-field gentle 95.32% reads 0.155, 2.17× cycles; aggressive 92.72% reads 0.058, 3.86×; vanilla HUSH on baseline 0.98 reads. Gated bit-exact check passes. G0 report written: GO with narrowed scope (`results/G0_report.md`).
- 2026-10-24 · T1.5 · Heuristic gates at equal reads: N-MNIST HUSH 95.5%/0 FN, SITRA-style 66.0%/15,121 FN, Early-style 93.5%/36 FN; SHD HUSH 70.7%/0, SITRA 48.0%/7,576, Early 65.3%/2. Caveats (Early predictor read cost uncharged; nets co-trained with HUSH) recorded.
- 2026-10-24 · T2.1/T2.2 · Tools installed in workspace: iverilog 12, verilator 5.020, yosys 0.33, cocotb 2.1, z3, boolector, SymbiYosys (from source, /usr/local/bin/sby). RTL v1 `rtl/hush_layer.sv` (GATE/MF params; double-buffered ETU overlapped with block loop; 4 sub-block column enables; counters). Bit-exact vs golden: 40/40 random regression cases (GATE/MF/k/θ/rates/partial gating) and real nets — N-MNIST mf (3 samples) and BASE, SHD mf — all PASS including counters (word reads, column reads, awake sub-blocks). RTL cycles N-MNIST sample: HUSH 7.9k–14.3k vs BASE 26.5k.
- 2026-10-25 · T2.1 · Regression found a bug: event-pointer width EAW = clog2(NEV) truncated the end pointer when NEV is a power of two; fixed to clog2(NEV+1); 60/60 new random cases pass. Safety arithmetic factored into `rtl/hush_arith.sv` (hush_envelope, hush_lane), used by both hush_layer and the formal harness `formal/fv_hush.sv`. SMT engines failed (boolector unroll crash, z3 4.8.12 stalls); ABC PDR proves the mean-field variant unbounded (PASS, 1,128 s); mutation with an unsafe mean proxy fails BMC immediately (non-vacuous); drop variant also PASS. User's laptop (Windows, `~/.Xilinx` present) likely has Vivado for Phase 3.
- 2026-10-25 · T2.4 · Exact RTL cycle model (fitted ETU constants n+3 / 1, start +1, ETU0 +2; 0 mismatches on 30 fresh random cases and N-MNIST). Whole-network RTL latency at 100 MHz (300 test samples): N-MNIST baseline BASE 286 µs; mf gentle HUSH 140 µs (2.04× vs baseline net), column reads 0.167; mf aggressive 86.7 µs (3.3×), reads 0.066. SHD baseline 815 µs; mf gentle 745 µs, reads 0.64; aggressive 402 µs (2.0×), reads 0.19.
- 2026-10-25 · T2.5 · Yosys 0.33 cannot parse the SV; yowasp-yosys 0.70 can (changed `parameter string` to untyped). N-MNIST layer: BASE 6.6k LUT/6.2k FF/36 RAMB36+3 RAMB18; HUSH-drop 12.1k/8.5k/+15 RAMB18; HUSH-MF 16.1k/11.0k/+30 RAMB18; 1 DSP (address multiply).
- 2026-10-25 · T2.6 · AB = clog2(2^15 + 128M + 1) + 1 (18 bits for M=578); state array to LUTRAM via st_valid bits (reset loop removed); state and R also cleared on every start. Yosys: BASE 3.9k/1.9k, drop 8.2k/3.7k, MF 10.9k/5.4k LUT/FF. Regression 40/40 + N-MNIST pass.
- 2026-10-25 · T3.1 prep · Board top with autorun, Nexys A7-100T XDC, non-project Vivado TCL (synth, place, phys_opt, route, utilization, timing, vectorless power, bitstream). iverilog compile and Yosys synth of the top pass.

## Phase 1 — Gated training (gate G1: 29 Nov 2026)

| ID | Task | Status |
| --- | --- | --- |
| T1.1 | Gate-in-the-loop trainer (STE on g_c, exceedance + envelope-drive losses, mean-field option) | DONE |
| T1.2 | θ_h sweep, accuracy vs ρ Pareto per dataset | TODO |
| T1.3 | N-MNIST and SHD feed-forward baselines | DONE (SHD 70.8%, N-MNIST 97.59%) |
| T1.6 | 3 seeds per Pareto point (SHD, N-MNIST); gentler N-MNIST points | IN PROGRESS (`scripts/sweep_seeds.sh`, resumable: re-run it to continue) |
| T1.7 | Bin-size sweep (SHD T=500/1000, N-MNIST T=200) | TODO |
| T1.8 | Energy model: reads + cycles + envelope overhead → dynamic energy estimate | TODO |
| T1.4 | G1 report | TODO |
| T1.5 | Heuristic-gate comparison: SITRA-style and Early-style gates at equal skip rate, count false-negative spikes vs HUSH | DONE (`results/heuristic_gates.md`) |

## Phase 2 — RTL and verification (gate G2: 27 Dec 2026)

| ID | Task | Status |
| --- | --- | --- |
| T2.1 | RTL: ETU, combine, scheduler, PE array, max trees, leak sweep | DONE v1 (`rtl/hush_layer.sv`; asleep pass 2 cycles/block, not yet a parallel sweep engine) |
| T2.2 | Testbench against GATED golden model | DONE (Icarus: `rtl/sim/run_case.py`, `rtl/sim/regress.py`) |
| T2.3 | SymbiYosys proof of the invariant at small sizes | DONE — PDR PASS for mean-field and drop; mutation FAIL as expected (`formal/README.md`) |
| T2.5 | Yosys synth_xilinx resource estimate before Vivado | DONE (`results/synth_yosys.md`) |
| T2.6 | Area optimisation: 18-bit accumulators, LUTRAM state, optional multiplexed ETU | DONE (first two; MF 10.9k LUT / 5.4k FF) |
| T2.4 | Performance counters, cycle model match within 1% | DONE — exact (0 mismatches, 30 random + real nets), `rtl/sim/cycle_model.py`, `scripts/rtl_perf.py` |

## Phase 3 — Implementation and power (gate G3: 24 Jan 2027)

| ID | Task | Status |
| --- | --- | --- |
| T3.1 | Vivado synthesis and P&R at 100 MHz on XC7A100T (needs your machine) | READY TO RUN (`fpga/build.tcl`, `fpga/top_hush.sv`, `fpga/nexys_a7_100t.xdc`); waiting for folder access / Vivado version |
| T3.2 | SAIF power over ≥100 samples per dataset | TODO |
| T3.3 | Board ΔP measurement, BASE vs HUSH | TODO |

## Phase 4–5 — Baselines, sweeps, writing (draft: 21 Feb 2027)

| ID | Task | Status |
| --- | --- | --- |
| T4.1 | Spiker+ on same topologies, same device | TODO |
| T4.2 | Sweeps: activity, B_env, θ_h, T | TODO |
| T5.1 | TCAS-II brief draft | TODO |

## Tier-1 plan (25 Oct 2026)

See `docs/tier1_plan.md` and the Claude Doc. Phases P1–P6 with gates GA–GE replace Phases 3–5 above once approved.

## Tier-1 Phase P1 — competitive workloads and near-lossless gating (gate GA: 22 Nov 2026)

GA criterion: SHD recurrent adLIF ≥ 90% ungated; HUSH ≤ 0.5 pt loss at ≥ 2× fewer reads; 3 seeds.

| ID | Task | Status | Output |
| --- | --- | --- | --- |
| P1.1 | Golden model for recurrent adLIF + headroom envelope; Theorem 1' + property tests | DONE | `golden/hush_rec.py`, `tests/test_hush_rec.py`, `docs/theorem1_prime.md` |
| P1.2 | Integer adLIF trainer (QRecAdLIF, QRSNN), bit-exact check, SHD baselines | IN PROGRESS | `train/qsnn.py`, `scripts/check_bitexact_rec.py`, `scripts/sweep_rec.sh` |
| P1.3 | Learned grouping | DONE — negative result (absorbed by co-training) | `scripts/regroup.py` |
| P1.4 | Gated co-training of the recurrent model (mean-field), θ_h / λ sweep | TODO | |
| P1.5 | Clamped low-rank hibernation (any asleep drive, clamped to D_c) | IN PROGRESS — golden + proof done; post-hoc study shows it must be co-trained | `golden/hush_rec.py` (`lr<r>`, `exact`), `scripts/hibernation_ceiling.py` |
| P1.6 | Distillation from the ungated teacher into the gated student | TODO | |
| P1.7 | 3 seeds of the chosen points (SHD rec + N-MNIST) | TODO | |

### P1 subtask log

- 2026-10-26 · P1.1 · `golden/hush_rec.py`: recurrence as extra input rows z = [x_t; s_{t-1}], Wc = [Wff; Wrec]; integer adLIF w' = clip(L_kw(w) + (a·V') >> sa + b·s). Gate on the drive-free part B = L(V) − w: clip(max_c B) + z·P ≥ θ_h, forced awake if max B > vmax. 9 Hypothesis tests pass (reduces exactly to v1 golden; no suppressed spike incl. negative adaptation; gate-on ≡ REF; signed D never looser; mean-field asleep < θ; register ranges; saturation). Mutations (ignore −w, no saturation force, drop recurrent proxy rows) fail 5/2/6 of 9 tests.
- 2026-10-26 · P1.1 · Signed-D gate (allowed by the new proof) vs v1 max(0, D) on the 4 trained FF nets: identical reads and accuracy. No gain; recorded honestly.
- 2026-10-26 · P1.2 · `QRecAdLIF`/`QRSNN` integer-faithful (0 spike/U mismatches vs golden, ref/gated/mean). Gradient explosion (1e9–1e27) traced to a < 0: Lemma 2 (Jury criterion) — stable iff −a/2^sa < 2^−(k+kw). Our update is already symplectic Euler (Baronig et al., Nat. Commun. 2025, added to Zotero), so a ≥ 0 gives guaranteed stability. Constrained a ∈ [0, 32], rec init 0.1θ/√N. Non-spiking readout (`--readout u`, class = argmax ΣU, 24-bit accumulator; measured max |U| fits 15 bits).
- 2026-10-26 · P1.2 · 5-epoch probe (700-256r-20, T=250): 82.3% test (FF best was 70.8% after 25 epochs), hidden rate 15%. Golden check bit-exact (50 samples). Vanilla HUSH on it: reads 0.99 (not co-trained). Speed: ~95 s/epoch alone; an orphan run from the old sweep had slowed everything 10×: run one job at a time.
- 2026-10-26 · P1.3 · `scripts/regroup.py` (balanced start + best-pair swaps minimising J = Σ_c Σ_j r_j relu(P_jc)). Works on random (−8% J) and ungated N-MNIST (−5%), but 0 improvement on co-trained nets: co-training creates tied sub-block maxima (rows with tied positive max 11–12% → 36–54%), i.e., the weights adapt to the grouping. Post-hoc / learned grouping dropped from the plan.
- 2026-10-26 · P1.5 · New safety rule: asleep drive A_i may be any approximation if clamped to min(A_i, D_c) (D_c already computed by the envelope unit; one compare per neuron per step). Proof: U_sleep ≤ Bmax + D_c < θ_h. Golden `asleep_drive = lr<r>` (rounded mean + r−1 quantised SVD directions, 4-bit β per neuron, int8 tables) and `exact` (clamped exact drive). Property test added; all 25 tests pass. Fixed a test assumption: with signed D, θ_h = vmin no longer forces the gate on.
- 2026-10-26 · P1.5 · Post-hoc on the aggressive mf nets (300 samples), acc / reads: SHD ungated 54.0/1.00, drop 52.7/0.42, mean 59.3/0.18, lr1 64.0/0.23, lr2 60.0/0.30, lr3 57.7/0.33, exact 54.0/0.35; N-MNIST ungated 88.0, drop 88.0/0.17, mean 90.7/0.06, lr1 92.7/0.11, lr2 91.3/0.14, lr3 89.7/0.15, exact 88.0/0.17. Lesson: "exact" equals the ungated net, which is worse than the gated one because the co-trained net's function is the gated net. The asleep drive is a training-time design choice, not an approximation error; low-rank must be compared after co-training each variant. The floor-mean bias (towards sleep) is what buys the low read fraction.
- 2026-10-26 · P1.2 · 30-epoch baselines (700-256r-20, T=250, u readout, lr 0.02): plain best 82.4% (ep 6), final 78.1%, rate 18%; dropout 0.1 + rate 5% best 81.5%, final 79.1%, rate 9%. Not overfitting: training loss stuck ≥ 0.78 with a spike at epoch 8 (0.80 → 1.46).
- 2026-10-26 · P1.2 · Cause found (Lemma 3, `docs/theorem1_prime.md`): with surrogate scale θ/4 the reset-path factor 1 − θσ′ reaches −3, so near-threshold neurons amplify BPTT gradients (1e27–1e30 or NaN at init on 3/4 seeds once per-neuron leaks up to k = 7 are used). Scale θ/2 bounds it to [−1, 1] (3e−4–7e−4); detaching the reset also works. Default changed to θ/2. Added heterogeneous per-neuron leak shifts k ± 2, kw ± 2 (fixed; golden `RecLayer.kv/kwv`, bit-exact), dropout 0.15 (as in Baronig et al.), grad clip 2. Running: `shd_rec_het` (40 epochs, lr 0.01).
- 2026-10-26 · P1.2 · `shd_rec_het` (θ/2, het leaks, drop 0.15, clip 2, lr 0.01, 40 epochs): best 69.4% (ep 5), collapse at epoch 8 (loss 1.65 → 3.10), final 63.2%. Worse than homogeneous. Debug run with `--log_grad`: first spike at epoch 5 batch 98, dominated by the adaptation coupling a (‖∇a‖ 5.5 vs 0.07–0.39 others). Analysis: at a neuron on threshold the reset factor is −1; the spike-triggered adaptation path b·σ′ then gives the (V, w) loop det −λμ and trace μ − λ − bσ′, which is unstable once bσ′ > 1 − λμ ≈ 0.06 (b ≥ 2). Fix under test: `--detach_reset` (removes the reset and b·s paths, leaving Lemma 2's provably stable subthreshold dynamics). Running `shd_rec_het_det`.
- 2026-10-26 · P1.2 · `shd_rec_het_det` (detached reset): gradient → ∞ at epoch 3 (spike in w, wr, b ≈ 20 each), network frozen at chance (5.7%) for 40 epochs. Without the reset's damping the recurrent loop σ′·Wrec explodes. Conclusion: the surrogate peak is the common cause (θσ′ peak 4 at θ/4, 2 at θ/2; Bittar's SHD code uses a boxcar with θσ′ ≤ 0.5). Running `shd_rec_het_s1`: fast-sigmoid scale c = θ (peak θσ′ = 1, reset factor in [0, 1]).
- 2026-10-26 · P1.2 · `shd_rec_het_s1` (surrogate scale θ, het, drop, clip, lr 0.01): no collapse but plateau (train loss ≈ 1.45, best 72.1% by epoch 12); stopped. Too many simultaneous changes since the 82% run → controlled one-change ablation `scripts/ablate_rec.sh` (6 epochs each: base θ/4, θ/2, θ, het, dropout, lr 0.01) running.
- 2026-10-26 · P1.2 · Ablation round 1 (6 epochs, one change from the 82% recipe): base θ/4 82.1% (rate 16.8%); θ/2 59.8%; θ 79.4% peak → 64.9%; het leaks: network silent (4.5%); dropout 0.15 82.5% (rate 13.9%); lr 0.01 69.6%. My Lemma-3 θ/2 "fix" was wrong for accuracy: default reverted to θ/4, doc corrected. Recipe now: θ/4, dropout 0.15, lr 0.02, short schedule (accuracy peaks at epochs 5–6; long one-cycle runs degrade). Added SHD channel pooling (`--pool`, OR of adjacent channels). Round 2 running (`scripts/ablate_rec2.sh`): T=100, pool 5, T=100+pool 5, hidden 512.
- 2026-10-26 · P1.2 · Ablation round 2 (6 epochs, base = θ/4 + dropout): T=100 (k=4) 68.8%; T=250 pool 5 (140 ch) 74.8%; T=100 pool 5 71.6%; T=100 pool 5 hidden 512 59.4%. All worse than base 82.5%, losses 1.5–1.8 with epoch-to-epoch dips: the optimisation itself is unstable, not the input format. Round 3 running (`scripts/ablate_rec3.sh`): max-over-time readout (`--readout umax`, integer decision argmax_c max_t U, one running-max register per class), logit scale 0.0625 / 0.25, batch 128.
- 2026-10-26 · P1.2 · Ablation round 3 (6 epochs): max-over-time readout `umax` 81.1% with monotone curve, train loss 0.70 (vs 1.13), rate 10.8%; logit scale 0.0625 75.6%, 0.25 79.4%; batch 128 77.2%. umax is the first smooth, sparse configuration; remaining gap looks like generalisation (speaker shift), not optimisation. Running `shd_rec_umax` (20 epochs). Risk to GA: after 3 ablation rounds the CPU-trainable single-layer INT8 model sits at 81–83%; 90% may need augmentation, more epochs or a GPU.
- 2026-10-26 · P1.2 · **`shd_rec_umax` (20 epochs, θ/4, dropout 0.15, umax readout): best 87.0% (ep 13), final 86.4%, smooth, rate 14%.** Golden bit-exact on 200 test samples (0 mismatches; readout 15 bits; golden acc 88.0% on that subset). Train loss 0.17 → generalisation gap. Added SHD event augmentation (`--aug_shift/--aug_stretch/--aug_jitter`); running `shd_rec_umax_aug` (30 epochs, shift ±20 ch, stretch ±10%, jitter ±2).
