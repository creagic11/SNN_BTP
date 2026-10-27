# Novelty check (T0.2) and baseline availability (T0.3)

Date: 2026-10-24. Full texts read through IEEE Xplore (IIT Kharagpur institutional access). All papers below are in the Zotero collection "HUSH – Literature".

## Verdict

HUSH is **not** the first accelerator to skip work for neurons predicted not to fire. Three papers already do output-side skipping: **SITRA** (ISLPED 2025) skips weight fetches for predicted silent outputs, **Early** (ICCD 2024) stops accumulation for neurons unlikely to fire, and **PS4** (ICCD 2024) fast-forwards time windows with no output spikes. All three are **heuristic** (tuned thresholds, accuracy loss 0.5–2%), **per neuron**, and evaluated on **ASIC simulation** (28 nm or 65 nm).

What remains new in HUSH, and what the paper must claim:

1. **A provable no-false-negative bound.** In exact mode the gate never removes a spike the ungated update would produce at that timestep (Theorem 1). None of the three gives a guarantee; all lose accuracy from mispredictions.
2. **A bound that carries membrane state across timesteps** (the R_c recursion with the leak), not a per-timestep or per-window score.
3. **Block granularity matched to BRAM words**, so a skip removes whole RAMB36 column reads and PE cycles on an FPGA.
4. **Measured FPGA silicon** (timing closure, SAIF and board power) instead of architecture simulation.

The claim to avoid: "first to exploit output sparsity" or "first to skip silent neurons". Reviewers who know SITRA or PS4 will reject that.

## Hardware comparison (newly read papers)

| Paper | SNN Model | FPGA Target | LUTs/DSPs/BRAM | Power | Key Innovation |
| --- | --- | --- | --- | --- | --- |
| [Early](https://doi.org/10.1109/ICCD63220.2024.00100) (ICCD 2024) | Temporal-coded SNNs (SNN-T, DCT-SNN, TSC-SNN, MTC-SNN); MNIST, CIFAR-100, ImageNet, DVS-Gesture | None: 28 nm ASIC, PE synthesized with Design Compiler at 200 MHz, architecture simulator | Not reported for FPGA | Relative only: 25.2× energy saving vs SpinalFlow, 3.2× vs SATO; 0.54% mean accuracy loss | Weights sorted offline by magnitude; early fire when V crosses V_th; early exit when V < V_sth after N_th spikes. Heuristic, per neuron |
| [SITRA](https://doi.org/10.1109/ISLPED65674.2025.11261761) (ISLPED 2025) | Spiking transformers (Spikformer, SpikingBERT), T = 4, IF neurons | None: 65 nm digital SIMD + 8T-SRAM PIM array, simulated | 27.32 mm² total area | Relative: 6.4× energy efficiency vs ANN transformer; 1–2% accuracy loss from silent-output detection | Weight-MSB dot product in a PIM array scores each output; score above a tuned τ marks it silent and its weight fetches are skipped. Detection for token n overlaps compute for token n−1 |
| [PS4](https://doi.org/10.1109/ICCD63220.2024.00022) (ICCD 2024) | Rate-coded conv SNNs (ResNet-18 etc.); CIFAR10-DVS, DVS-Gesture, ImageNet | None: systolic-array simulator, 28 nm synthesis of added logic | Not reported for FPGA | Relative: 3.8× performance vs PTB at similar energy | Popcount over a time window of TW steps, one speculative pass predicts whether each neuron fires in the window; failed speculations are recomputed step by step |
| [SPARSH](https://doi.org/10.1109/ICCAD66269.2025.11240985) (ICCAD 2025) | Seven SNNs (image, audio, text) trained in SpikingJelly; IF neurons | Virtex UltraScale, built on FireFly hardware | Area table only; "marginal" overhead vs a 256×256 systolic array | Not reported (left to future work) | Hashed buckets for nonzero weights; Bloom filter skips zero weights, zero spikes and neurons in the **refractory** state. 77% lower access latency than CSR |
| [Event-driven DVS SNN accelerator](https://doi.org/10.1109/TCSI.2025.3560666) (TCAS-I 2025) | FC SNNs up to 1M synapses, modified LIF; N-MNIST, DVS128-Gesture | Zynq UltraScale+ ZCU104, 250 MHz | Resource table is an image, not extracted | Vivado SAIF estimate over ~1 ms; idle-PE low-power mode saves 10.3% | Raw AER event input; reconfigurable structured weight sparsity; **early-stop** = end inference early once output spike counts are confident (temporal exit, not neuron skipping) |
| [C-STEP](https://doi.org/10.23919/DATE69613.2026.11539306) (DATE 2026) | Spiking transformers (SDTv1/v2, QKFormer), ImageNet-1K, T = 4, INT8 | None: accelerator model | Not reported | Synaptic ops cut to 0.356× of baseline on QKFormer | Confidence-based temporal exit after half the timesteps; channels silent in the first two timesteps are pruned for the rest; spike sharing across neighbouring tokens |
| [GustavSNN](https://doi.org/10.1109/HPCA68181.2026.11408587) (HPCA 2026) | SNN workloads, tick-batch | Not stated in abstract | Not read in full | 1.43× energy efficiency vs prior SNN accelerators | Gustavson-product dataflow; membrane state kept in local registers; skips inactive spike rows. Input-side only |

## How HUSH differs, mechanism by mechanism

| Property | Early | SITRA | PS4 | HUSH v2 |
| --- | --- | --- | --- | --- |
| What is predicted | Neuron will not fire this step | Output silent over all T steps | Neuron silent over a time window | Sub-block cannot fire this step |
| Predictor | Partial sum of largest weights vs V_sth | Weight-MSB dot product vs τ | Window popcount × weights | Integer proxy envelope Ê_c from per-block max weights and carried state bound R_c |
| Guarantee | None (tuned V_sth, N_th) | None (tuned τ) | Spikes found via error recovery; no bound stated | Exact mode: no spike removed (Theorem 1) |
| Accuracy cost | 0.54% mean | 1–2% | Not reported as loss | Measured; zero gating error by construction, but dropped sub-threshold drive changes later state |
| Granularity | Per neuron, per spike | Per output | Per neuron per window | 8-neuron sub-block, 32-neuron block = BRAM column / word |
| Uses membrane state | Within one step | No | Yes, at window start | Yes, bound carried across steps |
| Platform evidence | 28 nm simulation | 65 nm simulation | 28 nm simulation | Artix-7 post-route + board measurement (planned) |

## Implications for the design and the paper

- **Cite SITRA, Early and PS4 as the closest prior art** in the introduction and in a "related work: output-side skipping" paragraph. SITRA's overlap of detection with the previous token's compute is the same scheduling idea as HUSH's decoupled envelope; credit it.
- **Make the guarantee the headline.** The experiment that sells it: run SITRA-style and Early-style heuristic gates in the same Python model at equal skip rate and report their false-negative spikes and accuracy loss next to HUSH's zero false negatives. This is a cheap, convincing table (added as T1.5 in progress.md).
- **PS4 is composable with HUSH** (time-window merging vs neuron-block gating). Mention as future work rather than compete.
- **SPARSH's refractory skip is a special case** of state-driven skipping: a neuron that just reset with V = 0 and weak drive is exactly what the envelope catches, and more.

## T0.3 Spiker+ availability

The Spiker+ framework is public at [github.com/smilies-polito/Spiker](https://github.com/smilies-polito/Spiker) and on PyPI as `spikerplus`, with tutorials for MNIST (`Tutorials/5_mnist`), SHD (`Tutorials/6_shd`) and a Vivado flow (`Tutorials/7_vivado`). It generates VHDL for Xilinx parts, so it can be regenerated for the XC7A100T with our exact topologies. No LICENSE file was found in the repository, so we use it only to build the baseline and do not copy its code into this repo.

## SHD hardware landscape (added 26 Oct 2026, P1.2)

| Paper | SNN Model | FPGA Target | LUTs/DSPs/BRAM | Power | Key Innovation |
| --- | --- | --- | --- | --- | --- |
| Spiker+ (Carpegna et al., 2024, arXiv 2401.01141) | RSNN, SHD 72.99% | Zynq Z7-20 | 18,268 logic cells / – / 51 BRAM | 0.43 W, 540 µs | HDL generator framework for edge SNN accelerators |
| Matinizadeh et al. | configurable SNN core, SHD 87.80% | Zynq ZCU104 | ≈149.8k LUT / – / 75 BRAM | 1.63 W (peak) | fully configurable neuromorphic core |
| Chen et al. (SJTU), arXiv 2511.01158 | FF + synaptic delays (140)-256-256-20, SHD 93.4% deployed (94.7% train) | PYNQ-Z2 (Zynq-7020) | 40,521 LUT / 17 DSP / 77 BRAM | 282 mW processor (1.71 W SoC), 9.6 ms | hardware delay emulation, high-throughput SNN processor |
| Event-graph GNN, arXiv 2602.16442 | event-graph NN (not SNN), SHD 88.8–92.3% | Zynq ZCU104 | 34.5k–91.6k LUT / 106–330 DSP / 28–84.5 BRAM | 0.78–1.08 W PL | graph-based event audio classification |
| ReckOn (ISSCC 2022) | RNN 256 (ASIC 28 nm), 90.7% on a 10-class subset | ASIC | 138 kB SRAM | 79 µW | on-chip e-prop learning |
| **HUSH (ours, 26 Oct)** | recurrent adLIF 700-256r-20 INT8, SHD 83.1% (val protocol) | XC7A100T (target) | v1 layer: 10.9k LUT / 1 DSP / 36 RAMB36 + 33 RAMB18 (FF, Yosys) | – | provable block hibernation (Theorem 1′) |

Reading: credible SHD FPGA work now reports 88–93%, and the strongest SNN result uses delays. At 83% we beat Spiker+ (73%) but trail the delay-based designs by about 10 points. Accuracy alone would draw a reviewer's objection.

## N-MNIST and MNIST-class FPGA landscape (added 27 Oct 2026, comparison report v1)

Energy marked * is power × latency computed by us from the paper's own numbers.

| Paper | SNN Model | FPGA Target | LUTs/DSPs/BRAM | Power | Key Innovation |
| --- | --- | --- | --- | --- | --- |
| [Wu, Song & So](https://web.ece.hku.hk/~hso/Publications/wu_fpt2023.pdf), FPT 2023 | event-driven SNN, N-MNIST 95.76% (also Poker-DVS, DVS-Gesture); 50 ms per sample | ZCU102 (UltraScale+) | 39.7k–165k / 0 / 0 | 0.33–0.37 W (≈ 17.5 mJ*) | asynchronously triggered neurons |
| Row "[9]" in Wu et al.'s Table I | N-MNIST 82.32% | XC7Z045 | 10.1k / 32 / 131 | 0.94 W | (as reported by Wu et al.; label ambiguous in source) |
| [Ansari & Wielgosz](https://arxiv.org/abs/2608.00595), arXiv 2026 | 784-64-10 LIF, MNIST 96.70%, T = 16; 82 µs | Artix-7 XC7A200T | 16.0k / 0 / 0 | 0.336 W (≈ 27.6 µJ*) | time-multiplexed neurons, pipelined readout |
| [Spiker-LL](https://arxiv.org/abs/2605.18003), arXiv 2026 | 784-200-10, MNIST 90% (8-bit); 120 µs | PYNQ-Z2 | 8.5k / 0 / 46 | 0.326 W (39 µJ) | on-chip adaptive local learning |
| [Spiker+](https://arxiv.org/abs/2401.01141), 2024 | MNIST 96.83%, 780 µs; SHD 72.99%, 540 µs | Xilinx 7-series (Z7-20 for SHD) | 7.6k logic cells / – / 18 (MNIST); 18.3k / – / 51 (SHD) | 0.18 W (≈ 140 µJ*); 0.43 W (≈ 232 µJ*) | Python-to-VHDL SNN generator |
| **HUSH-MF (ours)**, 27 Oct 2026 | 578-256-10 integer LIF, N-MNIST 95.32% (gentle) / 92.72% (aggressive); 149 / 95 µs | Artix-7 XC7A100T, 100 MHz met | 10,960 / 0 / 54 RAMB36 + 3 RAMB18 | 0.190 W vectorless (28.4 / 18.1 µJ) | provably safe block hibernation (0 suppressed spikes) |
| BASE (ours, gate off) | same network, 97.59%; 294 µs | XC7A100T, 100 MHz met | 1,314 / 0 / 20 + 2 | 0.113 W vectorless (33.2 µJ) | identical datapath without HUSH |

Reading: on N-MNIST, HUSH's gentle point matches the best reported FPGA accuracy at ≈ 335× lower latency and ≈ 600× lower energy, with fewer LUTs. The designs and devices differ widely, so only the BASE-vs-HUSH rows isolate HUSH's own contribution. Surveys used to find rows: arXiv 2502.20415 and 2407.08356; the TCAS-I 2025 DVS accelerator (N-MNIST) still needs its resource table extracted.
