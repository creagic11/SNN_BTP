# HUSH: Provably Safe Sub-Block Hibernation for Event-Driven SNN Inference on FPGAs

B.Tech project, Indian Institute of Technology Kharagpur.
Author: Anubhav Jha. Supervisor: Prof. Rajat Subhra Chakraborty.

## Overview

In an event-driven spiking neural network (SNN) accelerator, most of the time and energy of a layer is spent
reading synaptic weights from block RAM. HUSH groups the neurons of a layer into sub-blocks of eight. Before the
weights of a timestep are read, it computes for each sub-block an integer upper bound (the *envelope*) on the
membrane potential that any of its neurons can reach. If the bound is below the firing threshold, the sub-block
*hibernates*: its weight reads are skipped and its neurons receive a shared mean-field drive instead.

Because the envelope is an upper bound, no spike is suppressed relative to the ungated update from the same state
(Theorem 1). The envelope and lane arithmetic is verified formally at the implementation's bit widths. The network
is trained with the gate in the forward pass.

The repository contains the integer golden models, the trainers, the SystemVerilog RTL of the complete network
(including a front-end for event-camera streams), the formal proofs, the Vivado implementation flow for a Xilinx
Artix-7 XC7A100T, all measured results, and the paper.

## Results

578-256-10 network, N-MNIST, whole network on chip, XC7A100T at 100 MHz. Accuracy is the mean ± standard deviation
over three training seeds. Power is estimated by Vivado from gate-level switching activity of the routed netlist;
energy is active energy per inference (power × latency).

| Design | Accuracy | Latency | Speedup | Energy per inference | LUT | BRAM tiles |
| --- | --- | --- | --- | --- | --- | --- |
| BASE (same RTL, gate disabled, trained for the same number of epochs) | 98.21 ± 0.13 % | 279.5 µs | 1.00× | 42.5 µJ | 7,745 | 80 |
| HUSH, gentler training | 96.54 ± 0.07 % | 159.8 µs | 1.75× | 23.7 µJ | 13,885 | 95 |
| HUSH, gentle training | 95.74 ± 0.07 % | 114.9 µs | 2.44× | 18.4 µJ | 13,885 | 95 |
| HUSH, aggressive training (6 epochs) | 92.32 ± 0.68 % | 82.9 µs | 3.39× | 14.4 µJ | 13,885 | 95 |
| Spiker+ (Carpegna et al., 2024), same device, BASE's 10-epoch weights | 97.53 % | 818.4 µs | 0.34× | 254.5 µJ | 13,548 | 70.5 |

- **Real-time operation.** In cycle-accurate RTL simulation that replays recorded N-MNIST event streams at their
  recorded timing, every 3 ms window is processed within 4.5 µs (HUSH) and 6.6 µs (BASE) of its end. With the same
  1,024-event input buffer, BASE sustains replay at 750× real time and HUSH (gentle) at 1,000×.
- **Cost of the gate.** 1.7–5.9 accuracy points, 79 % more LUTs and 19 % more block RAM than BASE.
- **Limitations.** Power is a tool estimate, not a board measurement; one dataset and one fully connected network
  are evaluated; real-time operation is shown by RTL replay, not with a physical sensor.

The paper (`paper/hush_paperA.pdf`) gives the full evaluation, including the scope of the safety guarantee and
comparisons with heuristic gating predictors and with published FPGA accelerators.

## Repository structure

| Path | Contents |
| --- | --- |
| `paper/` | Paper source (`hush_paperA.tex`), bibliography, figures and compiled PDF |
| `golden/` | Integer golden models: feed-forward LIF (`hush.py`), recurrent adaptive LIF (`hush_rec.py`), axonal delays (`hush_delay.py`); dataset loaders |
| `train/` | Integer-faithful surrogate-gradient trainers with the gate in the forward pass |
| `tests/` | Property-based tests of the safety invariants (Hypothesis) |
| `rtl/` | SystemVerilog RTL: arithmetic (`hush_arith.sv`), gated layer (`hush_layer.sv`), whole network and stream front-end (`hush_net.sv`); testbenches; cycle models and simulation drivers in `rtl/sim/` |
| `formal/` | SymbiYosys proofs of the safety arithmetic and their results |
| `fpga/` | Vivado non-project implementation and power-estimation flow, top levels, constraints, memory images |
| `spikerplus/` | Spiker+ baseline: generation scripts, generated VHDL, bit-exact model, FPGA harness |
| `synth/` | Open-source (Yosys) synthesis script used for early resource estimates |
| `scripts/` | Experiment, analysis and figure scripts |
| `results/` | Trained networks, measurements and reports; index in `results/README.md` |
| `docs/` | Technical notes: generalised safety theorem, headroom model, design decisions, literature survey |
| `notes/` | Project working documents: proposal, plans, development log, study material |

## Reproducing the results

Tested with Python 3.13 (NumPy 2.5, PyTorch 2.14, Hypothesis 6.170, Matplotlib 3.11), Icarus Verilog 12,
Yosys 0.33 with SymbiYosys and ABC, and Xilinx Vivado 2024.1. Datasets are downloaded by `scripts/get_data.py`.

```
python scripts/get_data.py nmnist                    # N-MNIST (via tonic)
pytest -q tests/                                     # safety invariants of the golden models
python rtl/sim/regress.py --n 40                     # randomised RTL-vs-golden regression
python rtl/sim/run_net.py --weights results/nmnist_T100_mf_e05_d025_ep12/weights.npz --mf 1 --n 50
cd formal && sby -f fv_width.sby m578                # full-width proof of the gate arithmetic
python scripts/fig_paper.py                          # paper figures from the result files
```

Training commands for every network are in `scripts/seed_run.sh`. The Vivado flow is described in
`fpga/README.md`. `results/README.md` maps every figure and table of the paper to the script and result file that
produce it.

## License

No license has been granted. All rights are reserved by the author.
