# HUSH v2 — Progress Log

This file is the resume point. If a session ends, start from the task marked **IN PROGRESS**, then the first **TODO** below it.

- Proposal: `docs/proposal_v2.md` (live copy: Claude Doc "HUSH v2 — Revised BTP Research Proposal")
- Study checklist for the defense: `study.md`
- Zotero collection: "HUSH – Literature" (user library 22138861, collection key FA5TR3KP)
- Compute available in the cloud workspace: 2 CPU cores, 7 GB RAM, no GPU

Status keys: DONE · IN PROGRESS · TODO · BLOCKED

## Current state

- **Last updated:** 2026-10-24
- **Now working on:** T0.4 integer golden kernel and property tests
- **Blocker:** pushes to GitHub are refused (Claude GitHub App not installed on `creagic11/SNN_BTP`). Work is committed locally in the cloud workspace and pushed once access is granted.

## Phase 0 — Setup, literature, feasibility (target gate G0: 8 Nov 2026)

| ID | Task | Status | Output |
| --- | --- | --- | --- |
| T0.1 | Repo scaffold, progress.md, study.md, proposal copy | DONE | this file, `study.md`, `docs/proposal_v2.md` |
| T0.2 | Novelty check: read Early (ICCD 2024), SPARSH (ICCAD 2025), C-STEP (DATE 2026); update literature table | DONE | `docs/literature/novelty_check.md` |
| T0.3 | Confirm Spiker+ source availability (external baseline) | DONE | note in `docs/literature/novelty_check.md` |
| T0.4 | Integer golden kernel: REF, GATED, ORACLE + property tests of Lemma 1 and Theorem 1 | IN PROGRESS | `golden/hush.py`, `tests/test_hush.py` |
| T0.5 | Dataset access in the workspace (MNIST, N-MNIST, SHD) | TODO | `scripts/get_data.py` |
| T0.6 | Train ungated INT8 baseline (MNIST 784-400-10 first), export integer weights | TODO | `train/`, `results/baseline_*` |
| T0.7 | Measure ρ before clustering: ORACLE vs HUSH-32 vs HUSH-8/32 | TODO | `results/rho_unclustered.md` |
| T0.8 | Co-inactivity clustering; re-measure ρ; write G0 report | TODO | `results/G0_report.md` |

### Subtask log

- 2026-10-24 · T0.1 · Cloned repo (was empty except README). Created folders `docs/ golden/ tests/ train/ rtl/ scripts/ results/`. Wrote progress.md, study.md, proposal copy. Push test: refused (no GitHub App access).
- 2026-10-24 · T0.2 · Read full texts via IEEE Xplore (IIT KGP access) in the browser pane: Early, SPARSH, C-STEP, plus newly found close prior art PS4 (ICCD 2024), SITRA (ISLPED 2025), TCAS-I 2025 DVS accelerator, GustavSNN (HPCA 2026). Added 4 items to Zotero. Verdict: output-side skipping exists (SITRA, Early, PS4) but all heuristic, per neuron, ASIC simulation; HUSH's claim narrows to provable bound + state carried across steps + BRAM-matched blocks + FPGA silicon. Written to docs/literature/novelty_check.md.
- 2026-10-24 · T0.3 · Spiker+ is public: github.com/smilies-polito/Spiker, PyPI `spikerplus`; MNIST, SHD and Vivado tutorials. No LICENSE file: use as baseline only.

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
