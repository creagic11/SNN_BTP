# HUSH v2 — Progress Log

This file is the resume point. If a session ends, start from the task marked **IN PROGRESS**, then the first **TODO** below it.

- Proposal: `docs/proposal_v2.md` (live copy: Claude Doc "HUSH v2 — Revised BTP Research Proposal")
- Study checklist for the defense: `study.md`
- Zotero collection: "HUSH – Literature" (user library 22138861, collection key FA5TR3KP)
- Compute available in the cloud workspace: 2 CPU cores, 7 GB RAM, no GPU

Status keys: DONE · IN PROGRESS · TODO · BLOCKED

## Current state

- **Last updated:** 2026-10-24
- **Now working on:** waiting on user for Vivado run (T3.1); T1.6 seeds running in background
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
