# Spiker+ baseline on the same network and device

Spiker+ (Carpegna, Savino and Di Carlo, 2024; Python package `spikerplus` 2.0.3, github.com/smilies-polito/Spiker)
generates VHDL accelerators for leaky integrate-and-fire networks. It is used here as a same-device external
baseline: the 578-256-10 network with BASE's 10-epoch INT8 weights (`results/nmnist_T100`), implemented on the
XC7A100T at 100 MHz with the same 20 test recordings as the HUSH power builds.

## Provenance

The VHDL in `fpga/gen/` was produced by the installed `spikerplus` package through `gen_spiker.py`. The generated
files carry the Unlicense (public-domain dedication) header of the Spiker+ project and are included unmodified so
that the build can be reproduced without the generator. All other files in this directory were written for this
project.

## Files

| File | Purpose |
| --- | --- |
| `gen_spiker.py` | Generates the Spiker+ VHDL for our INT8 weights: 6 fractional bits (weight w represented as w/64), threshold 1.0 (= 64), 16-bit state, β = 0.9375 (our k = 4), subtractive reset |
| `spiker_model.py` | Bit-exact Python model of the generated datapath, derived from the VHDL |
| `tb_network.vhd`, `ghdl_run.sh`, `check_small.py` | GHDL testbench comparing the generated hardware with the model on random networks and inputs |
| `check_full.py` | Full 578-256-10 network in GHDL on the 20 power-measurement recordings |
| `accuracy.py` | N-MNIST test accuracy of our weights under Spiker+ neuron semantics |
| `fpga/top_spiker.vhd` | Board harness equivalent to `fpga/top_net.sv`: 20 recordings on chip (one 578-bit word per timestep, `fpga/gen/spk.mem`), back-to-back operation, every output spike folded into the LEDs |
| `fpga/tb_top_spiker.vhd` | GHDL check of the harness |
| `fpga/build_spiker.tcl`, `fpga/build_spiker_hi.tcl`, `fpga/nexys_spiker.xdc` | Vivado builds with default and high-effort directives |
| `fpga/tb_spk_net.sv` | Gate-level testbench of the routed netlist for the switching-activity (SAIF) run |

## Neuron semantics

Spiker+ differs from our neuron in the order of operations. At the start of each timestep a neuron fires if
V > θ (strict) and is reset to V − θ without leak; otherwise it leaks, V − (V >>> 4). The weights of the active
inputs are then added, scanning all inputs serially, followed by the layer's recurrent weights (all zero for a
feed-forward layer). Layer l + 1 sees the spikes of layer l from the same timestep.

## Results

| Measure | Value | Source |
| --- | --- | --- |
| Accuracy of our 10-epoch weights under Spiker+ semantics (10,000 test samples) | 97.53 % (our integer model: 97.59 %) | `results/spikerplus/accuracy_nmnist_T100.json` |
| GHDL, 20 recordings: bit-exact to the model | 20 / 20 | `results/spikerplus/ghdl_20.json` |
| Cycles per inference | 81,422 (814 µs at 100 MHz) | same |
| Vivado, default directives | 13,564 LUT, 70.5 BRAM tiles, WNS −0.241 ns | `results/power_l1/README.md` |
| Vivado, high-effort directives | 13,548 LUT, 70.5 BRAM tiles, WNS +0.005 ns | `results/power_l2/README.md` |
| Gate-level power, latency, energy (default-effort netlist) | 311 mW, 818.4 µs, 254.5 µJ | `results/power_l1/README.md` |

Spiker+ stores its weights as ROMs (VHDL constants), as generated. Synthesis may trim constant weight bits, which
can only favour Spiker+ in area and power; HUSH and BASE use writable block RAMs.
