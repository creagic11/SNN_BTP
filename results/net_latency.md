# Whole network on chip: latency per inference (task A9.2; 3 seeds × 500 test samples)

hush_net: hidden layer → spike FIFO → output layer (overlapped, one timestep behind) → integer class on chip.
Exact cycle model (`rtl/sim/net_cycle_model.py`), equal to the RTL cycle for cycle on 8 random nets and
200 N-MNIST runs (`results/net/`). 100 MHz. 'Before' = hidden + output layer run one after the other
(the model used in the A5 tables). Speedup vs the ungated net of the same seed.

Accuracy: full 10,000-sample test set, hardware integer decision rule (`results/acc_integer.json`).

| Network | Accuracy % | Latency µs (on chip) | Before (sequential) µs | Max µs | Speedup vs BASE | Peak spike-FIFO |
|---|---|---|---|---|---|---|
| BASE (ungated, 10 ep) | 97.66 ± 0.07 | 279.5 ± 0.0 | 302.9 ± 0.0 | 386.2 | 1.00 ± 0.00× | 1 |
| BASE + 12 ep fine-tune, no gate (control) | 98.21 ± 0.13 | 279.5 ± 0.0 | 302.9 ± 0.0 | 386.2 | 1.00 ± 0.00× | 1 |
| HUSH-MF gentler, 12 ep | 96.54 ± 0.07 | 159.8 ± 8.1 | 173.7 ± 8.1 | 288.9 | 1.75 ± 0.09× | 3 |
| HUSH-MF gentle, 12 ep | 95.74 ± 0.07 | 114.9 ± 7.0 | 127.7 ± 6.9 | 227.4 | 2.44 ± 0.14× | 4 |
| HUSH-MF gentle, 6 ep | 95.37 ± 0.04 | 142.0 ± 10.9 | 155.4 ± 10.8 | 257.1 | 1.98 ± 0.15× | 3 |
| HUSH-MF aggressive | 92.32 ± 0.68 | 82.9 ± 7.8 | 94.7 ± 7.9 | 149.2 | 3.39 ± 0.34× | 4 |
