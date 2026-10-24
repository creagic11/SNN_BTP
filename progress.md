# HUSH v2 — Progress Log

This file is the resume point. If a session ends, start from the task marked **IN PROGRESS**, then the first **TODO** below it.

- Proposal: `docs/proposal_v2.md` (live copy: Claude Doc "HUSH v2 — Revised BTP Research Proposal")
- Study checklist for the defense: `study.md`
- Zotero collection: "HUSH – Literature" (user library 22138861, collection key FA5TR3KP)
- Compute available in the cloud workspace: 2 CPU cores, 7 GB RAM, no GPU

Status keys: DONE · IN PROGRESS · TODO · BLOCKED

## Current state

- **Last updated:** 2026-10-24
- **Now working on:** T0.9 regime study — ρ vs active inputs per timestep (MNIST low-rate, SHD, N-MNIST)
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
| T0.9 | Regime study: ρ and envelope gap vs active inputs per timestep; SHD and N-MNIST at fine time bins; firing-rate regularisation | IN PROGRESS | `results/regime_study.md` |
| T0.10 | G0 report and go / pivot decision | TODO | `results/G0_report.md` |

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

## Phase 1 — Gated training (gate G1: 29 Nov 2026)

| ID | Task | Status |
| --- | --- | --- |
| T1.1 | Gate-in-the-loop trainer (STE on g_c, exceedance + dispersion losses) | TODO |
| T1.2 | θ_h sweep, accuracy vs ρ Pareto per dataset | TODO |
| T1.3 | N-MNIST and SHD feed-forward baselines | TODO |
| T1.4 | G1 report | TODO |
| T1.5 | Heuristic-gate comparison: SITRA-style and Early-style gates at equal skip rate, count false-negative spikes vs HUSH | TODO |

## Phase 2 — RTL and verification (gate G2: 27 Dec 2026)

| ID | Task | Status |
| --- | --- | --- |
| T2.1 | RTL: ETU, combine, scheduler, PE array, max trees, leak sweep | TODO |
| T2.2 | cocotb + Verilator testbench against GATED golden model | TODO |
| T2.3 | SymbiYosys proof of the invariant at small sizes | TODO |
| T2.4 | Performance counters, cycle model match within 1% | TODO |

## Phase 3 — Implementation and power (gate G3: 24 Jan 2027)

| ID | Task | Status |
| --- | --- | --- |
| T3.1 | Vivado synthesis and P&R at 100 MHz on XC7A100T (needs your machine) | TODO |
| T3.2 | SAIF power over ≥100 samples per dataset | TODO |
| T3.3 | Board ΔP measurement, BASE vs HUSH | TODO |

## Phase 4–5 — Baselines, sweeps, writing (draft: 21 Feb 2027)

| ID | Task | Status |
| --- | --- | --- |
| T4.1 | Spiker+ on same topologies, same device | TODO |
| T4.2 | Sweeps: activity, B_env, θ_h, T | TODO |
| T5.1 | TCAS-II brief draft | TODO |
