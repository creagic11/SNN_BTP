# Resource accounting of the four whole-network builds (review point "LUT/BRAM figures need reconciliation", 11 Nov 2026)

XC7A100T-1CSG324C, Vivado 2024.1, 100 MHz. From `util_hier.rpt` of each routed build (`results/power_l1/netpwr/*`,
`results/power_l2/netstream/*`). "BRAM" = Vivado's *Block RAM Tile* count = RAMB36 + ½·RAMB18 (one tile = 36 Kb).

| Build | Used for | Hidden layer LUT / BRAM | Output layer LUT / BRAM | Network glue¹ LUT | Board harness² LUT | **Total LUT** | **Total BRAM** | DSP | WNS |
|---|---|---|---|---|---|---|---|---|---|
| BASE, power build (20 recordings on chip) | power, energy, latency (Table II) | 3,874 / 74 | 3,117 / 6 | 640 | 125 | **7,745** | **80** | 2 | +0.956 ns |
| HUSH, power build (20 recordings on chip) | power, energy, latency (Table II) | 9,922 / 89 | 3,150 / 6 | 638 | 187 | **13,885** | **95** | 2 | +0.450 ns |
| BASE, stream build (sensor input) | real-time configuration | 4,482 / 41.5 | 3,142 / 7 | 949 | 174 | **8,736** | **48.5** | 0 | +0.252 ns |
| HUSH, stream build (sensor input) | real-time configuration | 10,365 / 56.5 | 3,122 / 6 | 947 | 181 | **14,606** | **62.5** | 0 | +0.256 ns |

¹ spike FIFO + drain + classifier; in stream builds also the sensor front-end (pooling, de-duplication bitmap of
578 FFs, 128-entry input FIFO). ² UART loader, LED fold, autorun / pseudo-random sensor. Module rows can sum to
a few LUTs more or less than the total (≤ 11 here) because Vivado optimises across module boundaries.

Why the two pairs differ:
- **Block RAM:** a power build stores the events of 20 test recordings on chip (53,094 events in a 64 K × 16 b
  memory plus their 2,020 window boundaries: 32.5–33 tiles) so that power can be simulated over 20 inferences
  without a host. A stream build has instead a ring of 1,024 events (one RAMB18) fed by the sensor port. Hence
  80 → 48.5 (BASE) and 95 → 62.5 (HUSH) tiles: the weight, proxy and mean memories are identical.
- **LUTs:** the stream builds add the sensor front-end (≈ 310 LUTs of glue) and ring addressing (≈ 450–600 LUTs in
  the hidden layer); the power builds add sample-store addressing (2 DSPs for the per-recording offset).
- **HUSH − BASE** is the same in both pairs: +6.1 k / +5.9 k LUTs and +15 / +14 tiles (envelope unit, P and Q
  tables, sub-block control). The paper's power, energy and latency come from the power builds; the stream
  builds give the real-time configuration's area and timing.
