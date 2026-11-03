# A10 — Published FPGA SNN results on N-MNIST and DVS-Gesture (3 Nov 2026)

Purpose: give the comparison more than one row on our actual dataset. Every number below was read from the
paper (or from a comparison table in a later paper, marked "via"). **≈ = computed by us as power × latency**,
only where both are reported. "Vivado" = tool estimate; "measured" = board measurement; "?" = not stated.

## N-MNIST

| Paper | SNN model | FPGA target | LUTs / DSPs / BRAM | Power | Key innovation | Accuracy | Latency / inference | Energy / inference |
|---|---|---|---|---|---|---|---|---|
| **HUSH-MF gentle (ours, v5)** | 578-256-10 integer LIF, INT8, T = 100 | Artix-7 XC7A100T, 100 MHz | 9.8k / 0 / 57 + 2 | 151 mW total, 49 mW dynamic (gate-level SAIF, Vivado) | provably safe sub-block hibernation | 95.32 % | 153 µs | 23.1 µJ |
| **HUSH-MF aggressive (ours, v5)** | same | same | same | 157 mW total, 56 mW dynamic | same | 92.72 % | 97.2 µs | 15.3 µJ |
| [Cheng et al., TCAS-I 2025](https://doi.org/10.1109/TCSI.2025.3560666) (via [FeNN-DMA Table 3](https://arxiv.org/html/2511.00732v2)) | event-driven SNN, structured sparsity + early stop (also DVS-Gesture) | ZCU104, 250 MHz | 81,299 / ? / 258.5 (47,768 FF) | 0.808 W dynamic | structured weight sparsity, temporal early stop | 98.11 % dense, 96.88 % at 75 % sparsity | not in the table we could read | – |
| [FeNN-DMA, arXiv 2511.00732 (2025)](https://arxiv.org/html/2511.00732v2) | 512 recurrent LIF (99 % sparse recurrence, 95 % sparse input), 34×34×2 input | Kria KV260 (Zynq US+), 175 MHz | 54,984 / ? / 99 (+16 URAM per core; 47,759 FF) | 0.53 W dynamic (vectorless, PS removed) | programmable RISC-V SNN SoC with DMA | 98.46 ± 0.02 % | not reported | – |
| [Surrogates, Spikes, and Sparsity, arXiv 2603.24891 (2026)](https://arxiv.org/html/2603.24891v1) | VGG9-variant conv SNN | Virtex/Kintex US+ xcvu9p, 100 MHz | not reported | 0.31 W | training hyper-parameters tuned for hardware sparsity | 96.4 % | 5.9 ms | ≈ 1.83 mJ |
| [Wu, Song & So, FPT 2023](https://web.ece.hku.hk/~hso/Publications/wu_fpt2023.pdf) | asynchronously triggered SNN | ZCU102 | 39,709–165,071 / 0 / 0 | 0.33–0.37 W total (≤ 1 mW dynamic) | asynchronously triggered neurons | 95.76 % | 50 ms | ≈ 17.5 mJ |
| Row "[9]" in Wu et al.'s Table I (cited as Triplebrain, TBioCAS 2022; citation inconsistent in the source) | ? | XC7Z045, 250 MHz | 10,052 / 32 / 131 | 0.94 W | – | 82.32 % | not reported | – |

## DVS-Gesture (context: we have no DVS-Gesture result yet; that is Paper B, needs a GPU)

| Paper | SNN model | FPGA target | LUTs / DSPs / BRAM | Power | Key innovation | Accuracy | Latency / throughput | Energy / inference |
|---|---|---|---|---|---|---|---|---|
| [FireFly-S, arXiv 2408.15578](https://arxiv.org/pdf/2408.15578v3) | SCNN7 (2×48×48, T = 4) | KV260 (xczu5ev), 333 MHz | 55,234 / 0 / 11 | 1.821 W (Vivado) | dual-side (weight + spike) sparsity, reconfigurable spatial array | 92.05 % | 3,683 FPS | ≈ 0.49 mJ |
| FireFly v2 (via FireFly-S Table VI) | conv SNN | xczu5ev, 500 MHz | ? | ? | spatiotemporal dataflow | 89.29 % | 282 FPS | – |
| Liu et al., IJCNN 2023 (via [arXiv 2603.24891 Table II](https://arxiv.org/html/2603.24891v1)) | MP4-32C3-MP2-32C3-MP2-FC512-FC256-FC11 | FPGA (device not stated there), 100 MHz | ? | 0.42 W | low power, low latency | 86.3 % | 0.46 ms | ≈ 0.19 mJ |
| [arXiv 2603.24891 (2026)](https://arxiv.org/html/2603.24891v1) | VGG9-variant | xcvu9p, 100 MHz | ? | 1.35 W | as above | 95.4 % | 11.2 ms | ≈ 15.1 mJ |
| Cheng et al., TCAS-I 2025 | as above | ZCU104 | as above | as above | as above | DVS-Gesture reported; value not in the table we could read | ? | – |

## Reading (N-MNIST)

- **Where HUSH is far ahead:** latency (153 µs vs 5.9–50 ms, 39–330×), energy per inference (23 µJ vs ≈ 1.8–17.5 mJ,
  80–760×), dynamic power (49 mW vs 0.53–0.81 W, 11–16×), logic (9.8k LUT vs 39.7k–165k, 4–17×).
- **Where HUSH is behind:** accuracy. Two newer designs reach 98.1–98.5 % (larger or recurrent networks); we are
  at 95.3 % (gentle) and 97.6 % ungated. This is the gap a wider network / the GPU is meant to close (A6, B2).
- **Comparability caveats (must be stated in the paper):** different devices (Artix-7 vs Zynq UltraScale+),
  networks (fully connected vs conv/recurrent) and power methods (our activity-based estimate vs vectorless or
  board numbers); two of the strongest rows report no latency, so no energy can be computed for them. The
  same-chip Spiker+ build (A4) is the like-for-like check.
- Not FPGA, for context only: SNE (DATE 2022, ASIC) 97.8 % on N-MNIST at 11 mW.

Still open: Cheng et al.'s latency and DVS-Gesture accuracy (IEEE paywall; the full text could not be read here).
