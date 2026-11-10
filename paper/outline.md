# Paper A — outline and figure/table list (A8.1, 10 Nov 2026)

Working title: **HUSH: Provably Safe Sub-Block Hibernation for Real-Time Event-Driven SNN Inference on FPGAs**

Venue (A8.0, to confirm with the professor): IEEE TCAS-II brief (5 pages) or FCCM 2027 (≈ 10 Jan 2027, 8 pages
+ refs). The outline below fits the long form; the brief drops §5.4, §6.5 and merges §2 into §1.

Rule for every number: it comes from a file in `results/` (column "Source"); A8.2 adds a script that checks each
number in the LaTeX against these files.

## Claims (what the paper must support, in order of strength)

1. **Safety:** HUSH skips weight reads only where a proven upper bound on every membrane in the sub-block is below
   threshold → zero suppressed spikes (Theorem 1; formal proof on the RTL; bit-exact RTL = golden model).
2. **Same-chip efficiency:** on one Artix-7 XC7A100T, same network, same RTL with the gate off (BASE):
   2.44× lower latency and ≈ half the energy per inference at −1.9 pt accuracy (gentle 12 ep); 1.75× at −1.1 pt
   (gentler 12 ep); 3.39× at −5.3 pt (aggressive). Spiker+ (an open SNN generator) on the same chip and the same
   weights: 814 µs, i.e. HUSH is 7× faster.
3. **Versus published N-MNIST FPGA designs:** 51–435× lower latency (gentle 12 ep, 115 µs, vs 5.9–50 ms), two to
   three orders of magnitude lower energy per inference where computable, 4–17× fewer LUTs; accuracy: gentler
   12 ep (96.55 %) is above the two designs at 96.4 % and 95.76 %, and 1.6–1.9 pt below the two newest, larger
   designs (98.11 %, 98.46 %).
4. **Real time:** the whole network runs on chip on a live event stream: each 3 ms window is processed within
   3.3 µs of its close (both designs), the class is available 0.9 µs after the last window, and the stream can be
   replayed ≈ N× faster than real time with a 1-RAMB18 input buffer (HUSH ≈ 1.9× the throughput of BASE).
5. **Honest limits:** speedup shrinks with stream activity (2.2× sparse → 1.6× busy windows); the gate costs
   accuracy; power is activity-based Vivado estimation (gate-level SAIF), not a board measurement.

## Sections

| § | Content | Figures / tables | Source |
|---|---|---|---|
| 1 Introduction | weight fetches dominate SNN layer cost; prior skipping is heuristic (can drop spikes) or input-side only; contributions list = claims 1–4 | — | — |
| 2 Background & related work | integer LIF; input-side event-driven designs; output-side skipping (SITRA-style, early-termination); N-MNIST FPGA designs | Tab. I (related work, short) | `docs/literature/nmnist_dvs_fpga.md` |
| 3 HUSH | sub-blocks of 8; proxy tables P (max) and Q (mean); envelope E = sat(L(R) + max(0, D)); Theorem 1 (safety) + proof sketch; mean-field (MF) drive for asleep sub-blocks; training with the gate in the loop (exceedance and drive losses) | Fig. 1 gate concept; Alg. 1 | `docs/theorem1_prime.md`, `golden/hush.py` |
| 4 Architecture | hidden layer: ETU (envelope unit) overlapped with the block loop, 32-lane PE, per-sub-block weight-column RAM enables; output layer + spike FIFO + on-chip class; stream front-end (pooling, de-dup, ring, end-of-window) | Fig. 2 block diagram; Tab. II cycle model | `rtl/hush_layer.sv`, `rtl/hush_net.sv`, `rtl/sim/cycle_model.py`, `rtl/sim/net_cycle_model.py` |
| 5 Verification | bit-exact golden model; randomized regression (80/80); 4 × 50 N-MNIST samples bit-exact and cycle-exact; formal proof (SymbiYosys) of the gate; gate-level simulation equals model ± restart cycle | Tab. III verification summary | `results/net/`, `formal/`, `rtl/sim/regress.py` |
| 6 Results | 6.1 setup (XC7A100T, Vivado 2024.1, 100 MHz, gate-level SAIF); 6.2 accuracy–savings front (3 seeds); 6.3 hardware: area, timing, power, energy (whole network); 6.4 same chip: BASE, Spiker+; 6.5 vs safety-agnostic gates (heuristics) | Fig. 3 accuracy vs reads front with error bars; Tab. IV hardware; Tab. V heuristics | `results/seeds_nmnist.md`, `results/net_latency.md`, `out_l1/energy_l1.csv` (L1), `results/spikerplus/`, `results/heuristic_gates.md` |
| 7 Real-time operation | stream statistics; sensor-timing results; replay sweep; average-load bound; accuracy vs elapsed time; energy per 300 ms window = static + dynamic | Tab. VI real time; Fig. 4 accuracy vs elapsed time | `results/realtime/stream_stats.md`, `results/realtime/realtime.md` |
| 8 Comparison with the state of the art | N-MNIST FPGA designs with comparability caveats (device, network, power method) | Tab. VII SOTA | `docs/literature/nmnist_dvs_fpga.md` |
| 9 Limitations & conclusion | speedup vs activity; accuracy cost; estimation vs board; DVS-Gesture / conv layers as future work (Paper B) | — | `results/realtime/stream_stats.md` (A9.1b) |

## Open inputs before the draft is final

- L1 results (laptop): whole-network power for the four points, stream-build area/timing, Spiker+ power.
- A9.4 sweep + sensor-timing tables (running), A9.7 curve (running).
- Venue → template and page budget (A8.0).
