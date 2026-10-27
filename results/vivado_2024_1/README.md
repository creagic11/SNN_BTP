# Vivado 2024.1 results — XC7A100T-1CSG324C, 100 MHz (27 Oct 2026)

N-MNIST hidden layer (578×256, T = 100, k = 4), built with `fpga/run_all.tcl` / `fpga/run_hush.tcl` on the user's laptop. RTL = commit "Timing fix 3" (two-stage finalize + balanced two-stage max tree).

| Variant | LUT | FF | RAMB36 + RAMB18 | DSP | WNS | Power (vectorless) | dynamic |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BASE | 1,314 | 722 | 20 + 2 | 0 | +2.103 ns | 113 mW | 15 mW |
| HUSH-drop | 8,797 | 4,364 | 50 + 3 | 0 | +0.276 ns | 167 mW | 67 mW |
| HUSH-MF | 10,960 | 6,177 | 54 + 3 | 0 | +0.451 ns | 190 mW | 90 mW |

Per-inference figures (cycle model, 500 samples; accuracy on the full test set): BASE 97.59% / 294.0 µs / 33.2 µJ; HUSH-MF gentle 95.32% / 149.3 µs / 28.4 µJ; HUSH-MF aggressive 92.72% / 95.2 µs / 18.1 µJ (energy = vectorless total power × latency; conservative for HUSH, see the comparison report).

Timing history: the first HUSH build failed at WNS −12.9 ns (lane update + serial 8-input max in one cycle); fix 1 (pipelined R refresh) did not reach the laptop (stale transfer); fix 2 (two-stage finalize) gave −4.0 to −4.3 ns; fix 3 (balanced two-stage max tree) closed timing.
