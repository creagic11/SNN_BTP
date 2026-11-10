# A5 + A6 — N-MNIST, three seeds (0, 1, 2): mean ± sample std

Accuracy on the full 10,000-sample test set with the hardware's integer decision rule (results/acc_integer.json); latency and weight-column reads for the whole 578-256-10 network over
500 test samples (exact v5 cycle model, matches gate-level simulation within 3–8 cycles); speedup vs the ungated
net of the same seed; energy = gate-level SAIF power of the seed-0 builds × latency.

| Network | Accuracy % | Latency µs | Speedup vs BASE | Weight-column reads | Energy µJ | per-seed accuracy |
|---|---|---|---|---|---|---|
| BASE (ungated) | 97.66 ± 0.07 | 302.9 ± 0.0 | 1.00 ± 0.00× | 1.000 ± 0.000 | 43.9 ± 0.0 | 97.58, 97.71, 97.69 |
| HUSH-MF gentle | 95.37 ± 0.04 | 155.4 ± 10.8 | 1.96 ± 0.13× | 0.167 ± 0.001 | 23.5 ± 1.6 | 95.32, 95.40, 95.38 |
| HUSH-MF aggressive | 92.32 ± 0.68 | 94.7 ± 7.9 | 3.21 ± 0.28× | 0.070 ± 0.003 | 14.9 ± 1.2 | 92.72, 92.70, 91.54 |
| HUSH-MF gentler, 12 ep (A6)* | 96.54 ± 0.07 | 173.7 ± 8.1 | 1.75 ± 0.08× | 0.204 ± 0.003 | 26.2 ± 1.2 | 96.61, 96.48, 96.54 |
| HUSH-MF gentle, 12 ep (A6)* | 95.74 ± 0.07 | 127.7 ± 6.9 | 2.38 ± 0.12× | 0.118 ± 0.002 | 19.3 ± 1.0 | 95.73, 95.81, 95.68 |

\* Energy of the A6 rows uses the gentle build's SAIF power (0.151 W); their own SAIF power is pending (laptop run L1).
