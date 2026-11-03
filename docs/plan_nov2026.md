# Execution plan, 3 Nov 2026 → Paper A draft (no GPU, no board)

Decisions behind this plan (3 Nov, with the user):
- GPU work is deferred, not dropped: everything below is reused when a GPU arrives (same trainer, same RTL).
- Paper A uses simulation and Vivado activity-based power only; board measurement (A7) stays open.
- Professor: results must clearly beat the state of the art on some axes and be comparable on others, and
  inference must keep up with a **live sensor stream** (real time).

Status of every item is tracked in `progress.md` (table "Paper A track" + dated log). A task is DONE only when
every check in its "Done when" column passes; the evidence (file, log line, number) is written into the log.

---

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
| A9.3 | **Stream mode** in the RTL: events written by an input port into a ring buffer; a bin is "closed" by an end-of-bin marker; the sequencer stalls before launching the envelope unit for bin t+1 until that bin is closed (HUSH needs one bin of look-ahead → 3 ms decision delay) | Claude | stream-mode simulation bit-exact to batch mode on 20 samples; cycle model extended with stalls |
| A9.4 | Streaming testbench: events released at their true times (3 ms bins); measure per-bin busy time, worst-case slack, input-buffer peak occupancy, decision latency after the last event — BASE and HUSH | Claude | table: worst per-bin time ≪ 3 ms for both; buffer size justified; decision latency in µs |
| A9.5 | Vivado: full-network stream-mode build for BASE and HUSH-MF (timing + area) | **User** (part of laptop run L1) | WNS ≥ 0 at 100 MHz |
| A9.6 | Energy in real-time operation = static × window + dynamic energy (from A3 SAIF), and stream capacity per chip; report section "Real-time operation" | Claude | numbers in report v3 and paper |

---

## Laptop run L1 (one command for the user, ~3–4 h unattended, target 6–7 Nov)

Contents: A4.5 (Spiker+ build + netlist simulation + SAIF) and A9.5 (two full-network stream-mode builds).
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
| A8.4 | Comparison report v3 (same link) with A4, A5, A9 | report updated |

---

## Calendar (target)

| Date | Claude | User |
|---|---|---|
| 3 Nov | S0; A5 starts; A4.1–A4.2 | — |
| 4–5 Nov | A4.3–A4.4; A9.1–A9.3 | — |
| 6 Nov | A9.4; prepare and deliver laptop run L1 | run L1 (~3–4 h) |
| 7 Nov | check L1; A4.6, A9.6; A5.3 table; A6 starts in background | — |
| 8–11 Nov | A8.0–A8.3 | confirm venue with the professor |
| 12 Nov | report v3 + draft to the professor | review |

After the draft (no GPU needed): B1 (convolutional layers: golden model, Theorem 1 extension, property tests,
RTL) and B3 (multi-array engine). When a GPU arrives: B2 (DVS-Gesture) and a faster A6.
