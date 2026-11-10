# Laptop run L1 (10 Nov 2026, 09:58–22:42 IST): whole-network power, stream builds, Spiker+

Vivado 2024.1, XC7A100T-1CSG324C, 100 MHz. Power: gate-level SAIF of 20 back-to-back test inferences on the routed
netlist (functional simulation in xsim), `read_saif` + `report_power`; nets matched 99.95 % (HUSH, BASE) / 100 %
(Spiker+), confidence High in every case. Latency = mean of inferences 1–19 in the gate-level simulation; every
inference took exactly the cycle-model count + 3 (restart), the first + 7 (reset). Energy = total power × latency.
Files: `energy_l1.csv`, `summary.txt`, per case `power_saif*.rpt`, `util*.rpt`, `timing.rpt`, `ram_util.rpt`, `sim_try1.log`.

## Whole network (578-256-10, hidden + output layer + class on chip)

| Design | LUT | BRAM | WNS ns | Latency µs | Total mW | Dynamic mW | Energy µJ | Dyn. energy µJ | vs BASE |
|---|---|---|---|---|---|---|---|---|---|
| BASE (gate off) | 7,745 | 80 | +0.956 | 279.5 | 152 | 51 | 42.49 | 14.26 | 1.00× |
| HUSH gentler 12 ep | 13,885 | 95 | +0.450 | 151.2 | 157 | 56 | 23.74 | 8.47 | −44.1 % |
| HUSH gentle 12 ep | 13,885 | 95 | +0.450 | 115.3 | 160 | 58 | 18.44 | 6.69 | −56.6 % |
| HUSH aggressive | 13,885 | 95 | +0.450 | 87.7 | 164 | 62 | 14.39 | 5.44 | −66.1 % |
| Spiker+ (same weights) | 13,564 | 70.5 | **−0.241** | 818.4 | 311 | 210 | 254.5 | 171.9 | +499 % |

Dynamic power by component (W): BASE clocks 0.016 / logic 0.008 / signals 0.012 / BRAM 0.014; HUSH gentle
0.021 / 0.009 / 0.015 / 0.012; Spiker+ 0.033 / 0.014 / 0.023 / **0.140** (its weight memories are read every
cycle; ours only for awake sub-blocks).

Notes:
- The 20 samples are seed-0 weights on the A3 power samples; latency here is over those 20 (500-sample means are in
  `results/net_latency.md`: BASE 279.5, gentler 159.8 ± 8.1, gentle 114.9 ± 7.0, aggr 82.9 ± 7.8 µs).
- BASE power was measured with the 10-epoch BASE weights; the paper's BASE accuracy (98.21 %) is the 22-epoch control
  network, whose latency is identical (279.5 µs); its power is taken as equal (weights change only switching
  activity in the output layer and the hidden lanes; not measured).
- Spiker+ misses 100 MHz by 0.241 ns (Fmax ≈ 97.6 MHz): at 97.6 MHz its latency is 838.6 µs and its energy
  ≈ 256 µJ (dynamic power scaled with the clock). A high-effort rebuild is in laptop run L2.
- Stream-mode builds (`netstream/`): BASE 8,730 LUT / 48.5 BRAM / +0.309 ns; HUSH gentle 14,593 / 62.5 / +0.269 ns
  (built before the end-of-window marker fix; rebuilt in L2).
