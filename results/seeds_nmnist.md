# A5 — N-MNIST, three seeds (0, 1, 2): mean ± sample std

Accuracy on the full 10,000-sample test set; latency and weight-column reads for the whole 578-256-10 network over
500 test samples (exact v5 cycle model, matches gate-level simulation within 3–8 cycles); speedup vs the ungated
net of the same seed; energy = gate-level SAIF power of the seed-0 builds × latency.

| Network | Accuracy % | Latency µs | Speedup vs BASE | Weight-column reads | Energy µJ | per-seed accuracy |
|---|---|---|---|---|---|---|
| BASE (ungated) | 97.66 ± 0.06 | 302.9 ± 0.0 | 1.00 ± 0.00× | 1.000 ± 0.000 | 43.9 ± 0.0 | 97.59, 97.71, 97.69 |
| HUSH-MF gentle | 95.37 ± 0.04 | 155.4 ± 10.8 | 1.96 ± 0.13× | 0.167 ± 0.001 | 23.5 ± 1.6 | 95.32, 95.40, 95.38 |
| HUSH-MF aggressive | 92.32 ± 0.68 | 94.7 ± 7.9 | 3.21 ± 0.28× | 0.070 ± 0.003 | 14.9 ± 1.2 | 92.72, 92.70, 91.54 |

BASE latency has no spread by construction: with the gate off every block is awake, so its cycle count depends only
on the input events, which are the same 500 test samples for every seed.
