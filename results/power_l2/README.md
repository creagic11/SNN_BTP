# Laptop run L2 (10–11 Nov 2026, 23:09–01:10 IST)

| Build | Purpose | LUT | BRAM | WNS (ns) | Result |
|---|---|---|---|---|---|
| netpwr/base_ctrl | power of the paper's BASE (22-epoch control weights), gate-level SAIF, 20 inferences | 7,745 | 80 | +0.956 | **152 mW (51 dynamic), 279.5 µs, 42.49 µJ (14.26 dynamic)** — identical to the 10-epoch BASE in L1; nets matched 99.9 % (22,039/22,058), confidence High; every inference = model + 3 cycles (first + 7) |
| netstream/base | stream mode with the end-of-window marker fix | 8,736 | 48.5 | +0.252 | met |
| netstream/mf_gentle12 | stream mode with the marker fix | 14,606 | 62.5 | +0.256 | met |
| spiker_hi | Spiker+ with high-effort directives (PerformanceOptimized synth, Explore opt, ExtraTimingOpt place, AggressiveExplore phys_opt/route + post-route phys_opt) | 13,548 | 70.5 | **+0.005** | **meets 100 MHz** (L1 default effort: −0.241 ns) |

Spiker+ power: the SAIF numbers (311 mW, 254.5 µJ) were measured on the L1 default-effort netlist. The high-effort
netlist's vectorless estimate is 4.3 % higher than the default one's (0.555 vs 0.532 W), so its energy would be
≈ 265 µJ; we report the measured 254.5 µJ (favouring Spiker+) and note this.
