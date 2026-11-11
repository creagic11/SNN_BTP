# Execution plan, 3 Nov 2026 → Paper A draft (no GPU, no board)

Decisions behind this plan (3 Nov, with the user):
- GPU work is deferred, not dropped: everything below is reused when a GPU arrives (same trainer, same RTL).
- Paper A uses simulation and Vivado activity-based power only; board measurement (A7) stays open.
- Professor: results must clearly beat the state of the art on some axes and be comparable on others, and
  inference must keep up with a **live sensor stream** (real time).

Status of every item is tracked in `progress.md` (table "Paper A track" + dated log). A task is DONE only when
every check in its "Done when" column passes; the evidence (file, log line, number) is written into the log.

## Update, 10 Nov 2026 (status + decision on real time)

**Done since 3 Nov:** S0, A5 (3 seeds), A10.1–A10.3, A4.1–A4.4 (Spiker+ bit-exact in GHDL, 814 µs), A6.1–A6.2 and the
3-seed runs of the two new points (gentle 12 ep: 95.74 ± 0.06 %, 2.38×, reads 0.118; gentler 12 ep: 96.55 ± 0.07 %,
1.75×, reads 0.204 → A6 target met), A9.1 (+ A9.1b: speedup vs bin activity, multi-stream memory bound).
**Not done on time:** laptop run L1 (planned 6–7 Nov), so A4.5/A4.6/A6.3/A9.5/A9.6 wait; draft date 12 Nov moved.

**Real-time decision (10 Nov):**
- The paper's real-time guarantee is stated in **sensor time**: every 3 ms window is processed, and the decision
  updated, before the next window closes. Measured worst window ≈ 8.4 µs (0.3 % of 3 ms) for both BASE and HUSH.
  Input = one window double-buffered (≤ 2 × 284 events × 16 b, under one RAMB36).
- Throughput is a **separate** metric: the fastest replay (time-compressed N-MNIST) at which a one-RAMB36 input
  buffer never overflows, with its p99 decision delay; BASE and HUSH at the same buffer (HUSH ≈ 1.9×, to measure).
- Dropped: many-streams-per-chip (state memory binds first: ≈ 730 BASE vs ≈ 600 HUSH streams, so BASE would win).
  Heavier sensor stream → Paper B (GPU); the speedup-vs-activity table (2.2× sparse → 1.6× busy) goes into the
  limitations.
- Correction to A9.3 below: HUSH does **not** need one window of look-ahead. The envelope for window t uses only
  window t's events, so it runs when window t closes (the ETU overlap is lost: +n+4 cycles per window, already in
  the per-window costs above). No 3 ms decision delay.
- New A9.7: accuracy vs elapsed sensor time (decision after 50/100/…/300 ms), golden model only.

**Status at end of 10 Nov:** A9.2 DONE (whole network on chip, 4 × 50 samples bit- and cycle-exact; latency table
`results/net_latency.md`), A9.3 DONE (stream mode, bit-exact at sensor timing and 1,000–2,000× replay), L1 package
delivered and md5-verified (whole-network power ×4 replaces the planned A6.3 single-layer runs; 2 stream builds;
Spiker+), A8.1 outline (`paper/outline.md`). Running: A9.4 sweep + sensor-timing runs, A9.7 curve.

---

## Status, 11 Nov 2026 01:30

DONE: S0, A5, A6 (+ fair-baseline control, 3 seeds: 98.21 %), A4.1–A4.6 (Spiker+ same chip: 818 µs, 254.5 µJ;
meets 100 MHz with high effort), A9.1–A9.7 (whole network on chip, stream mode, real-time tables, energy at
sensor rate, early-decision curve), laptop runs L1 and L2, A10, A8.1 (outline), A8.2 (draft, 4 pages, IEEEtran),
A8.3 (internal review applied), A8.4 (comparison report v3: "Update v3" section in the Claude Doc).
OPEN: two reference entries (Early authors, SPARSH co-authors); venue and author-name spelling (questions for the
user at the end); A7 board measurement (blocked: board + power meter); Paper B (GPU).

## Status, 11 Nov 2026 evening (after two external reviews)

Both review rounds applied to Paper A (`paper/hush_paperA.tex`, 6 pages): scope of the guarantee (per-timestep
safety proved; trajectory drift measured: ungated run of the same weights emits 1.8–1.9× the hidden spikes, gentle
94.8 % gated vs 93.5 % ungated), full-width formal check of the envelope/lane arithmetic (assumption drive ≤ D_c
discharged by table construction), aggressive point labelled 6 epochs, heuristic comparison with charged reads
(exploratory), real-time energy at a common 750× speed (BASE 54.7 µJ vs HUSH 47.5 µJ), references completed.
OPEN: venue (6 pages fits FCCM; TCAS-II brief needs cuts) and author-name spelling/affiliation (to ask at the end);
A7 board measurement (blocked); Paper B (GPU).

## Status, 11 Nov 2026 night (final review pass)

Author line set (Rajat Subhra Chakraborty; IIT Kharagpur, departments still to add). Venue left open by the user;
limit 8 pages without references, paper is ≈ 6.5. Final strict pass applied: area cost (+79 % LUT, +19 % BRAM) in
the abstract, energy attribution (two thirds of BASE's active energy is static), LUT × latency (3 / 26 / 44 %),
SnaPEA in related work, limitations extended, five new figures (schedule, accuracy vs latency, energy split,
cycles vs activity, replay sweep). `docs/primer.md` rewritten for the current state, `study.md` Phase 6 added,
README and `paper/outline.md` rewritten.
OPEN: venue; departments; optional 12-epoch aggressive point; A7 (board); Paper B (GPU).

## Stage 0 — housekeeping (3 Nov, ~30 min, Claude)

| ID | Step | Done when |
|---|---|---|
| S0.1 | This plan committed; progress.md table extended with A4.x, A5, A9.x, A6, A8.x | both files on GitHub |
| S0.2 | Tier-1 plan Claude Doc: short "v5 numbers, 28 Oct" note | note visible in the doc |
| S0.3 | Start A5 trainings in the background (CPU queue, see A5) | first run's log shows epoch 1 |

---

## A5 — three seeds per N-MNIST point (CPU background, starts 3 Nov, ~5 h compute)

Seed 0 exists. Add seeds 1 and 2 for each of: ungated (10 epochs, ~18 min), gentle (exceedance 0.5, drive 0.25,
6 epochs from that seed's ungated net), aggressive (2, 1, 6 epochs). 6 runs, two at a time (2 cores).

| ID | Step | Done when |
|---|---|---|
| A5.1 | `scripts/sweep_seeds.sh` (or a new `seeds_nmnist.sh`) runs the 6 trainings | 6 `results/nmnist_T100*_s{1,2}/metrics.json` exist, each with 10 / 6 epochs logged |
| A5.2 | `rtl_perf.py --n 500` per seed (cycle-exact latency, column reads) | 9 `rtl_perf.json` (3 seeds × 3 points) |
| A5.3 | Table: mean ± std of accuracy (full test set), column reads, latency, energy (seed-0 SAIF power × latency) | `results/seeds_nmnist.md`; std of accuracy reported to 0.01 pt |

Risk: a seed lands far from seed 0 (e.g. gentle < 94%). Then report it as is; the error bars are the point.

---

## A4 — Spiker+ on the same chip, same network (the fair external baseline)

Why: our SOTA ratios (≈330× latency, ≈760× energy) compare different chips and designs. A reviewer will ask
for a like-for-like test. Spiker+ (Carpegna et al. 2024, github.com/smilies-polito/Spiker, PyPI `spikerplus`
2.0.3) generates VHDL for LIF networks with **β = 0.9375 = 1 − 2⁻⁴ and subtract reset — exactly our neuron
(k = 4, soft reset)**, so our trained weights can run on it unchanged in principle. No LICENSE file: used as a
baseline only, not redistributed.

| ID | Step | Who | Done when |
|---|---|---|---|
| A4.1 | Install `spikerplus`; run its VHDL-generation tutorial unchanged; compile the generated VHDL (GHDL here) | Claude | tutorial VHDL compiles and its testbench runs |
| A4.2 | Build the 578-256-10 net in Spiker+ (β 0.9375, threshold, subtract reset), load **our ungated INT8 weights** (`results/nmnist_T100`); readout = its output voter | Claude | its Python quantised model reaches ≥ 97.0 % on the N-MNIST test set (ours: 97.59 %), or the gap is explained (readout/quantiser) |
| A4.3 | Generate VHDL; simulate 20 test samples (the A3 samples); compare its spikes/classes with its Python model; record cycles per inference | Claude | 20/20 classes equal to its Python model; cycles/inference logged |
| A4.4 | Wrapper: on-chip store of the same 20 samples (spike rasters), autorun, every output observed on LEDs (the lesson of 28 Oct); writable weight memory if Spiker+ allows, else noted | Claude | iverilog/GHDL run of the wrapper = A4.3 result |
| A4.5 | Vivado build on XC7A100T at 100 MHz + gate-level SAIF power over the 20 samples (same flow as run_v5) | **User** (one command, part of laptop run L1) | WNS ≥ 0 (else report its Fmax and energy at that clock); nets matched ≥ 99 %; netlist cycles = A4.3 |
| A4.6 | Add a "same chip" row to the report and the paper table: accuracy, LUT/FF/BRAM/DSP, latency, power, energy, energy per SOP | Claude | row in report v3 + `results/spikerplus_a100t/README.md` |

Risks and fallbacks:
- Spiker+ may not scale cleanly to 578 inputs × 256 neurons (its neurons are clock-driven, inputs processed
  serially). Fallback 1: build it anyway and report its resource use (that is a result too). Fallback 2: compare at
  a size it supports (e.g. 578-128-10) for both designs.
- Its quantiser may not accept our integer weights directly. Fallback: train the same network with its own
  trainer on CPU (≈ 20 min per epoch estimated) and report both accuracies.

---

## A9 — real-time inference on a live sensor stream (new, from the professor)

What "real time" means here: N-MNIST events arrive over 300 ms in 3 ms bins (measured on 200 test samples:
**27 events per bin on average, 84 at most; 2,719 per sample on average, 3,810 at most**). The chip must finish
each bin before the next bin's events are complete, and give the class shortly after the stream ends.

Two facts to state honestly in the paper (they shape the claim):
1. **Both BASE and HUSH are real-time by a wide margin.** Worst case per bin is ~8 blocks × (8 + 84) ≈ 740 cycles
   ≈ 7.4 µs for BASE, against a 3 ms budget. So real-time capability is *not* HUSH's differentiator.
2. **In real-time operation the FPGA idles >99 % of the time, and static power (~101 mW) cannot be switched off on
   an Artix-7.** Energy per 300 ms window ≈ 30 mJ for either design; HUSH saves only its dynamic share there. HUSH's
   gains appear as **capacity**: one chip serves 1.98–3.12× more sensor streams (or more bins per second) for the
   same hardware, at the per-inference energies we report.
   The paper will report all three: real-time margin, energy per window at sensor rate, and stream capacity.

| ID | Step | Who | Done when |
|---|---|---|---|
| A9.1 | Stream statistics: events per bin (mean, p99, max), events/s, required input bandwidth; interface choice (AER-style event port; UART needs ≥ 1 Mbaud at the peak rate, 115,200 baud is too slow) | Claude | `results/realtime/stream_stats.md` |
| A9.2 | **Full network on chip**: output layer as a second `hush_layer` (gate off, 256 → 32 padded) fed by hidden spikes, plus the integer class decision (most output spikes, tie → larger summed U, then lower index — `golden.hush.predict`) | Claude | regression 80/80 still passes; 50 N-MNIST samples: predicted class = golden for all, both layers' write-backs bit-exact |
| A9.3 | **Stream mode** in the RTL (revised 10 Nov): events written by an input port into a double-buffered window store; a window is closed by an end-of-window marker; the ETU for window t starts when t closes (no look-ahead) | Claude | stream-mode simulation bit-exact to batch mode on 20 samples; cycle model extended with the stream-mode costs |
| A9.4 | Streaming testbench, two modes: (a) events at true sensor times → worst per-window busy time, slack, decision delay after window close; (b) replay speed swept → fastest speed with no buffer overflow for a one-RAMB36 buffer, p99 decision delay; BASE and HUSH. Plus `scripts/stream_queue.py` (queue model) predicting (b) over all 10,000 samples | Claude | (a) worst window ≪ 3 ms for both; (b) RTL = queue model on the simulated samples; table in `results/realtime/` |
| A9.7 | Accuracy vs elapsed sensor time (class decided after 50, 100, …, 300 ms), golden model, BASE and HUSH points | Claude | `results/realtime/early_decision.md` |
| A9.5 | Vivado: full-network stream-mode build for BASE and HUSH-MF (timing + area) | **User** (part of laptop run L1) | WNS ≥ 0 at 100 MHz |
| A9.6 | Energy in real-time operation = static × window + dynamic energy (from A3 SAIF), and stream capacity per chip; report section "Real-time operation" | Claude | numbers in report v3 and paper |

---

## A10 — published FPGA results on our dataset (Claude, 3–4 Nov, ~2 h, alongside A5)

Gap: only one published FPGA design in our table reports N-MNIST (Wu, Song & So, FPT 2023). The other rows are
MNIST or SHD (context only).

| ID | Step | Done when |
|---|---|---|
| A10.1 | Targeted search (arXiv, IEEE/ACM venues, surveys arXiv 2502.20415 and 2407.08356, Zotero): FPGA SNN accelerators evaluated on **N-MNIST** or **DVS-Gesture**, 2021–2026 | candidate list with links |
| A10.2 | For each: open the paper, extract FPGA, network, accuracy, LUT/FF/BRAM/DSP, clock, power, latency, energy (computed as power × latency only when not reported, marked *), and whether power is measured or estimated | table in the project format [Paper / SNN model / FPGA target / LUTs-DSPs-BRAM / Power / Key innovation] + latency, energy, accuracy columns, in `docs/literature/nmnist_dvs_fpga.md` |
| A10.3 | Include the TCAS-I 2025 DVS accelerator (resource table still missing) | its row filled or marked "not reported" |
| A10.4 | Add the rows to Zotero ("HUSH – Literature") and to comparison report v3 | ≥ 3 N-MNIST rows (or every one found, if fewer exist) |

## Laptop run L1 (one command for the user, ~3–4 h unattended, target 6–7 Nov)

Contents: A4.5 (Spiker+ build + netlist simulation + SAIF), A6.3 (SAIF power for the gentle-12ep and gentler-12ep
weights, same flow as run_v5) and A9.5 (two full-network stream-mode builds).
Delivered as one `.bat` with md5-checked files, the same command form as before:

    cd C:/Users/Anubhav/hush_fpga/fpga
    exec -ignorestderr cmd /c run_l1.bat

Checks Claude runs on the outputs before any number is used: WNS ≥ 0 for every build; all outputs observable
(no pruned lanes: lane and BRAM counts as expected); nets matched ≥ 99 %; netlist cycles = model.

---

## A6 — raise gated N-MNIST accuracy (CPU background, after A5, ~1–2 days compute, outcome uncertain)

Target: gated ≥ 96.5 % at column reads ≤ 0.25 (gentle is 95.32 % at 0.168 now).

| ID | Step | Done when |
|---|---|---|
| A6.1 | Gentler losses: exceedance 0.25 / drive 0.1, and 12 instead of 6 fine-tune epochs | accuracy/reads pair logged |
| A6.2 | Wider hidden layer 384 (BRAM still fits: weights 578 × 384 B ≈ 1.8 Mbit) — ungated + gentle | pair logged; area estimate noted |
| A6.3 | If a point beats gentle on the accuracy–reads front: rtl_perf + one SAIF power run (laptop run L2) | point added to the tables with its own hardware numbers |

If nothing beats the current front, report the sweep as the Pareto front and stop (no further CPU spend).

---

## A8 — Paper A draft (8–12 Nov, Claude; professor review after)

| ID | Step | Done when |
|---|---|---|
| A8.0 | Venue with the professor. ISCAS 2027 closed (13 Oct 2026). Open: **IEEE TCAS-II** (journal brief, rolling); **FCCM 2027** (deadline ≈ 10 Jan 2027 per conference listing — confirm on the official site); FPL 2027 (spring) | venue chosen; page limit and template known |
| A8.1 | Outline + figure list: datapath, gate/theorem, headroom table, safety-vs-heuristics table, hardware table, SOTA + same-chip table, real-time table, accuracy–reads front with error bars | outline in `paper/` |
| A8.2 | Full draft in the venue template (LaTeX), every number traced to a results file | draft PDF; a script checks each number in the text against `results/` |
| A8.3 | Internal review pass (fresh-eyes reviewer agent), fix list applied | review notes + changes logged |
| A8.4 | Comparison report v3 (same link) with A4, A5, A9, A10 | report updated |

---

## Calendar (re-dated 10 Nov)

| Date | Claude | User |
|---|---|---|
| 10 Nov | plan update; A9.2 | — |
| 11 Nov | A9.3; A9.7 | confirm venue with the professor |
| 12 Nov | A9.4 + queue model; prepare and deliver L1 | run L1 (~4 h) |
| 13 Nov | check L1; A4.6, A6.3, A9.6; A8.1 | — |
| 14–16 Nov | A8.2–A8.4; report v3 + draft to the professor | review |

## Calendar (original, 3 Nov — superseded)

| Date | Claude | User |
|---|---|---|
| 3 Nov | S0; A5 starts; A10.1–A10.2; A4.1–A4.2 | — |
| 4–5 Nov | A10.3–A10.4; A4.3–A4.4; A9.1–A9.3 | — |
| 6 Nov | A9.4; prepare and deliver laptop run L1 | run L1 (~3–4 h) |
| 7 Nov | check L1; A4.6, A9.6; A5.3 table; A6 starts in background | — |
| 8–11 Nov | A8.0–A8.3 | confirm venue with the professor |
| 12 Nov | report v3 + draft to the professor | review |

After the draft (no GPU needed): B1 (convolutional layers: golden model, Theorem 1 extension, property tests,
RTL) and B3 (multi-array engine). When a GPU arrives: B2 (DVS-Gesture) and a faster A6.
