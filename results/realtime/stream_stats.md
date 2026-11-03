# A9.1 — N-MNIST stream at sensor timing (3 Nov 2026)

Script: `scripts/stream_stats.py results/nmnist_T100_mf_e05_d025/weights.npz --n_raw 10000 --n_work 500`
Raw data: `stream_stats.json`. Bin = 3 ms (300 ms window, T = 100). Clock 100 MHz → 300,000 cycles per bin.

## Input stream (all 10,000 test samples)

| Quantity per 3 ms bin | mean | p50 | p99 | p99.9 | max |
|---|---|---|---|---|---|
| raw DVS events (34×34×2) | 41.9 | 33 | 135 | 163 | 284 |
| active pooled inputs (578), what the ETU/PE see | 26.5 | 25 | 66 | 76 | 96 |

- Mean event rate ≈ 14 k events/s; peak bin ≈ 95 k events/s.
- Link (2 bytes per event + 1 end-of-bin byte, UART 10 bits/byte): 0.18 Mbaud mean, **0.64 Mbaud at the
  worst bin**. The Nexys A7 USB-UART at 1 Mbaud (or 921,600) covers it; 115,200 baud does not.

## Work per bin, whole network (500 samples, gentle weights)

Each bin is costed on its own (upper bound: the envelope pre-pass is counted per bin, not overlapped).

| Design | mean cycles | p99 | max | headroom at worst bin | streams per chip (mean) | clock needed for worst bin |
|---|---|---|---|---|---|---|
| BASE | 295 | 624 | 828 | 362× | ≈ 1,016 | 0.28 MHz |
| HUSH-MF gentle | 185 | 577 | 840 | 357× | ≈ 1,618 | 0.28 MHz |

## What this means (to settle before A9.3 is built)

1. **Both designs are real-time on N-MNIST by ~360×.** Real-time is not a differentiator on this dataset;
   N-MNIST (saccade recordings, ~14 k ev/s) is a very light stream.
2. **HUSH helps the average bin (−37% cycles), not the worst bin.** In busy bins the envelope wakes most
   blocks, so the worst-case cost equals BASE (840 vs 828, +ETU pre-pass). A worst-case-provisioned system
   (fixed low clock) gains nothing from HUSH; a work-conserving one (clock gating / race-to-idle, or shared
   among streams) gains the mean.
3. Since static power (~101 mW) dominates a 300 ms window at 100 MHz, energy per window at sensor rate is set by
   static power for both designs; HUSH's real-time claim must be framed as **capacity (≈ 1.6× more streams
   per chip) and dynamic energy**, or tested on a stream heavy enough to load the chip (full 34×34 input,
   or a higher-rate sensor dataset).
