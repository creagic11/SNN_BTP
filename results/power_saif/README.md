> **Superseded (28 Oct 2026)** by `results/power_saif_v5/`. These builds pruned BASE lanes 6-25 (too-narrow LED fold), stored weights as trimmed ROMs and had no per-column weight enables; do not quote these numbers.

# A3: activity-based (SAIF) power, XC7A100T-1CSG324C, 100 MHz, Vivado 2024.1 (28 Oct 2026)

Flow: routed power build per weight set (20 N-MNIST test samples, 53,094 events, stored on chip) →
`write_verilog -mode funcsim` → xsim of the routed netlist (20 back-to-back inferences, SAIF of every net) →
`scripts/fix_saif_names.py` (xsim escaped names → read_saif form; drops 32 bits named `(null)` that read_saif
cannot parse) → `read_saif` on the routed checkpoint → `report_power`. Scripts: fpga/run_power.tcl,
fpga/run_power2.bat, fpga/annotate_power3.tcl / annotate3.bat.

Checks: netlist-simulation cycles = cycle model (+4/+5 per inference) for all 60 inferences; SAIF duration =
20 × mean latency; nets matched 100% (3,317/3,317; 43,441/43,473; 43,052/43,084); confidence High; only
warning Power 33-330 (clock-net activity ignored; benign). Timing met in all power builds (WNS +1.580 /
+0.055 / +0.175 ns).

| Case | Build | Mean cycles (hidden layer) | Latency µs | Total mW | Dynamic mW | Static mW | E_total µJ/inf | E_dyn µJ/inf |
|---|---|---|---|---|---|---|---|---|
| base | BASE (no gating) | 27,135 | 271.3 | 167 | 68 | 99 | 45.3 | 18.5 |
| mf_gentle | HUSH-MF | 14,268 | 142.7 | 283 | 182 | 101 | 40.4 | 26.0 |
| mf_aggr | HUSH-MF | 8,445 | 84.4 | 298 | 197 | 101 | 25.2 | 16.6 |

Caveats (must accompany any use of these numbers):
1. **Harness bias against HUSH.** To hold 20 samples, the timestamp table grew from 101 to 2,020 entries.
   In the HUSH builds synthesis implemented the ETU's two reads of it as 2,048×16 LUT ROMs
   (+~10.2k LUTs, +2 DSP: 21,222 LUT vs 10,960 in the timing build). BASE has no ETU and does not pay this.
   HUSH dynamic power here is therefore an over-estimate. Fix pending (A3b).
2. Power builds hold a 64K-entry event store (both BASE and HUSH); BRAM counts differ from the timing builds.
3. Energy is for the hidden layer only (578→256, T = 100), at 100 MHz, vendor estimate (not board-measured).
4. HUSH's total-energy gain comes from shorter latency (static power × time); per-inference dynamic energy is
   higher than BASE for mf_gentle and only 1.11× lower for mf_aggr. BRAM is the largest dynamic component
   (HUSH 79–95 mW vs BASE 56 mW).
