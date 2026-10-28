> **Superseded (27 Oct 2026)** by the Vivado 2024.1 results, now `results/power_saif_v5/` (v5: BASE 3,821 LUT, HUSH-MF 9,800 LUT, 0 DSP, all at 100 MHz). Kept for history.

# T2.5 Resource estimate with open-source synthesis (Yosys 0.70 `synth_xilinx -family xc7`)

Layer: N-MNIST hidden layer, M = 578 inputs, N = 256 neurons, T = 100, event buffer 4,096 entries, INT8 weights, INT16 state, 26-bit accumulators. Script: `synth/synth_nmnist_hush_mf.ys` (run with `yowasp-yosys`; needs the .hex files in the working directory). These are pre-Vivado estimates (no retiming, no LUTRAM mapping of the state array); Vivado numbers will replace them.

| Configuration | LUT | FF | CARRY4 | DSP48E1 | RAMB36 | RAMB18 |
| --- | --- | --- | --- | --- | --- | --- |
| BASE (GATE = 0) | 6,617 | 6,241 | 697 | 1 | 36 | 3 |
| HUSH, drop (GATE = 1, MF = 0) | 12,093 | 8,510 | 1,528 | 1 | 36 | 18 |
| HUSH, mean-field (GATE = 1, MF = 1) | 16,076 | 11,006 | 1,976 | 1 | 36 | 33 |
| XC7A100T capacity | 63,400 | 126,800 | — | 240 | 135 | 270 |

HUSH-MF uses 25% of the LUTs and 8.7% of the FFs of an XC7A100T. The envelope unit is the main overhead (+5.5k LUT, +2.3k FF for the proxy path; +4k LUT, +2.5k FF more for mean-field): it holds two banks × 32 sub-blocks × 26-bit accumulators for each of D and Qs, plus 32 parallel adders each. The proxy and mean tables add 15 RAMB18 each.

Planned reductions before Vivado: accumulator width 26 → 18 bits (|D| ≤ 578 × 127 < 2^17); state array mapped to LUTRAM (now 4,096 FFs); optional time-multiplexed envelope adders (8 adders × 4 cycles per event) when the overlap budget allows.

## After T2.6 (accumulator width from M = 18 bits, state in LUTRAM via valid bits)

| Configuration | LUT | FF | CARRY4 | LUTRAM cells | DSP48E1 | RAMB36 | RAMB18 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BASE | 3,859 | 1,897 | 475 | 64 | 1 | 36 | 3 |
| HUSH, drop | 8,229 | 3,654 | 1,052 | 64 | 1 | 36 | 18 |
| HUSH, mean-field | 10,877 (17.2%) | 5,382 (4.2%) | 1,370 | 64 | 1 | 36 | 33 |

Accumulators shrank from 26 to 18 bits and the 4,096-FF state array moved to distributed RAM (the reset loop that blocked RAM inference was replaced by per-block valid bits). Envelope overhead vs BASE: +4.4k LUT / +1.8k FF (drop), +7.0k LUT / +3.5k FF (mean-field). Bit-exact regression re-run: 40/40 random + N-MNIST network pass.
