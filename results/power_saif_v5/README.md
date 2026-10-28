# A3b: SAIF power and area, hush_layer v5, XC7A100T-1CSG324C @ 100 MHz, Vivado 2024.1 (28 Oct 2026, run out_v5c)

**This supersedes results/vivado_2024_1 and results/power_saif** (those builds pruned BASE lanes 6-25 through a
too-narrow LED fold, stored weights as trimmed ROMs, had no per-column weight enables and carried a +10k-LUT
harness ROM in HUSH only; see progress.md 28 Oct).

Design (v5): every table is a writable BRAM with a UART host load port; weights in four 64-bit column RAMs read
only when the sub-block is awake; ts pairs in TDP BRAM; `ram_decomp = "power"` on the deep event and weight RAMs;
event index registered before the weight address (timing fix 4); all 32 spikes + 512 state bits folded into LEDs.
Verified in simulation: 80/80 random regressions cycle-exact (incl. 20 loading every RAM via the load port);
20 N-MNIST samples bit-exact for all three weight sets; gate-level netlist cycles = model + 3..8 per inference.

## Timing / area (1 sample on chip, NEV = 4,096; the paper's area table)

| Build | WNS ns | LUT | FF | RAMB36 + RAMB18 | DSP | Vectorless total / dynamic mW |
|---|---|---|---|---|---|---|
| BASE | +1.441 | 3,821 | 2,643 | 43 + 0 | 0 | 136 / 36 |
| HUSH-drop | +0.198 | 7,618 | 4,528 | 50 + 1 | 0 | 168 / 68 |
| HUSH-MF | +0.496 | 9,800 | 6,284 | 57 + 2 | 0 | 185 / 85 |

## Activity-based power (20 N-MNIST test samples on chip, 53,094 events, gate-level SAIF)

Power builds: WNS base +0.270, mf_gentle +0.491, mf_aggr +0.491 ns. Nets matched 100%, confidence High; only
warning Power 33-330 (clock-net activity ignored, benign). Latency = mean of inferences 1-19 (inference 0
includes reset), hidden layer 578→256, T = 100, includes ~4 cycles of autorun handshake.

| Case | Latency µs | Total mW | Dynamic mW | Static mW | E_total µJ/inf | E_dyn µJ/inf | vs BASE (latency / E_total / E_dyn) |
|---|---|---|---|---|---|---|---|
| BASE (dense) | 279.2 | 145 | 45 | 101 | 40.49 | 12.57 | 1 / 1 / 1 |
| HUSH-MF gentle | 146.4 | 151 | 49 | 101 | 22.11 | 7.17 | 1.91× / 1.83× / 1.75× |
| HUSH-MF aggressive | 87.5 | 157 | 56 | 101 | 13.74 | 4.90 | 3.19× / 2.95× / 2.57× |

Dynamic breakdown (mW, clocks / logic / signals / BRAM): BASE 12 / 7 / 11 / 14; gentle 16 / 8 / 13 / 11;
aggressive 17 / 9 / 15 / 13.

Caveats: vendor power estimate from zero-delay gate-level activity (no glitch power), not a board measurement
(A7 pending); hidden layer only; the 64K-entry event store is test harness (both BASE and HUSH carry it);
static power is the device's (XC7A100T, typical, 25 °C) and identical for all builds. Full Vivado reports
(timing, utilisation, RAM mapping, power, simulation logs) are in `reports/`.

## Whole network (578-256-10), 500 test samples — the numbers used in the comparison report v2

Latency from the exact cycle model (`scripts/rtl_perf.py --n 500`, v5 model: PE_STAGES = 4, ETU +1), which
gate-level simulation matches within 3–8 cycles; accuracy on the full test set; energy = the activity-based
power above (hidden-layer build) × whole-network latency.

| Variant | Accuracy | Latency µs | Throughput /s | Weight-column reads | Energy µJ | per dense-equivalent SOP (683,055) |
|---|---|---|---|---|---|---|
| BASE | 97.59% | 302.9 | 3,301 | 1.00 | 43.9 | 64.3 pJ |
| HUSH-MF gentle | 95.32% | 153.0 (1.98×) | 6,537 | 0.168 | 23.1 (−47%) | 33.8 pJ |
| HUSH-MF aggressive | 92.72% | 97.2 (3.12×) | 10,284 | 0.067 | 15.3 (−65%) | 22.4 pJ |
