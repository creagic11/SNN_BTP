# A9.4 — real-time operation on a live N-MNIST stream (RTL simulation, 100 MHz)

## (a) True sensor timing: events presented at their recorded times (3 ms windows)

| Design | Recordings | Bit-exact, no drops | Window delay mean µs | Window delay max µs | Decision after last window µs | Input FIFO peak | Ring peak (of 1,024) |
|---|---|---|---|---|---|---|---|
| BASE | 4 | 4/4 | 3.04 | 6.64 | 2.03 | 1 | 127 |
| HUSH gentle 12ep | 4 | 4/4 | 1.47 | 4.50 | 0.89 | 1 | 127 |

Window length 3,000 µs → worst window uses 0.22 % of it.

## (b) Replay faster than real time — the 20 test recordings with the most input events

Same buffer for every design: ring of 1,024 events (one RAMB18) + 64-entry input FIFO. A run passes if
nothing is dropped and every result is bit-exact. Delay = output layer done for a window − its marker.

| Design | Speed × | Passing | Max window delay µs | Mean window delay µs | Ring peak |
|---|---|---|---|---|---|
| BASE | 250 | 20/20 | 8.83 | 4.32 | 185 |
| BASE | 500 | 20/20 | 23.65 | 5.54 | 369 |
| BASE | 750 | 20/20 | 65.97 | 20.96 | 826 |
| BASE | 1000 | 0/20 | 96.99 | 48.19 | 1024 |
| BASE | 1500 | 0/20 | 100.31 | 53.26 | 1024 |
| BASE | 2000 | 0/20 | 93.86 | 49.10 | 1024 |
| HUSH gentle 12ep | 250 | 20/20 | 8.68 | 2.18 | 197 |
| HUSH gentle 12ep | 500 | 20/20 | 14.10 | 2.21 | 278 |
| HUSH gentle 12ep | 750 | 20/20 | 40.76 | 2.94 | 602 |
| HUSH gentle 12ep | 1000 | 20/20 | 59.18 | 4.88 | 836 |
| HUSH gentle 12ep | 1500 | 15/20 | 75.34 | 12.85 | 1024 |

| Design | Fastest speed with no drops on all of them | Sustained raw-event rate at that speed (test-set mean 13.97 k ev/s × speed) |
|---|---|---|
| BASE | 750× | 10.5 M events/s |
| HUSH gentle 12ep | 1000× | 14.0 M events/s |

## Average-load bound (no buffer limit): 300 ms of sensor time / mean cycles per recording

| Design | Mean cycles per recording (500 samples) | Real-time factor |
|---|---|---|
| BASE | 27,954 | 1,073× |
| HUSH gentle 12ep | 11,020 | 2,722× |
| HUSH gentler 12ep | 15,248 | 1,967× |

## A9.7 — accuracy vs elapsed sensor time (class read from the chip after w windows; 10000 test samples)

| Design | 30 ms | 60 ms | 99 ms | 150 ms | 201 ms | 300 ms |
|---|---|---|---|---|---|---|
| BASE | 49.63 | 76.04 | 86.06 | 91.78 | 95.37 | 97.58 |
| HUSH gentler 12ep | 62.27 | 87.68 | 92.60 | 94.20 | 95.39 | 96.61 |
| HUSH gentle 12ep | 61.00 | 84.88 | 90.89 | 93.14 | 94.28 | 95.73 |
| HUSH aggressive | 53.92 | 79.74 | 86.89 | 89.75 | 91.85 | 92.72 |
