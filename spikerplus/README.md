# Spiker+ on our network and chip (task A4)

Spiker+ (Carpegna et al. 2024; `spikerplus` 2.0.3 from PyPI, github.com/smilies-polito/Spiker) generates VHDL for
LIF networks. Its generated files carry the Unlicense (public domain) header. Nothing from Spiker+ is copied here;
`gen_spiker.py` calls the installed package.

| File | Purpose |
|---|---|
| `gen_spiker.py` | generate Spiker+ VHDL for our INT8 weights (fp_dec 6 → weight w as w/64, θ = 1.0 = 64; 16-bit state; β = 0.9375 = our k = 4; subtract reset) |
| `spiker_model.py` | bit-exact Python model of the generated datapath (read from the VHDL) |
| `tb_network.vhd`, `ghdl_run.sh`, `check_small.py` | GHDL testbench; compares the generated hardware with the model on random nets and inputs |
| `accuracy.py` | N-MNIST test-set accuracy of our weights on Spiker+'s neuron semantics |

Spiker+ neuron semantics (differ from ours): at each step start, fire if V > θ (strict) → V − θ without leak, else
leak V − (V >>> 4); then add the weights of the active inputs (scanning all inputs serially), then the layer's own
recurrent weights (all zero for a feed-forward layer). Layer l+1 sees layer l's spikes of the same step (fixed by the full-size GHDL run).

Results so far (3 Nov 2026): model = GHDL on 25 random (net, input) cases; our ungated seed-0 weights reach
**97.53 %** on Spiker+ semantics (ours: 97.59 %), full 10,000-sample test set. Full 578-256-10 design in GHDL on the 20 power samples: all bit-exact to the model, mean **81,422 cycles** (814 µs at 100 MHz; ours: BASE 302.9 µs, HUSH gentle 153.0 µs).

## FPGA harness (A4.4) — `fpga/`

| File | Purpose |
|---|---|
| `top_spiker.vhd` | same harness as our `fpga/top_hush.sv`: 20 N-MNIST samples on chip (one 578-bit word per step, `spk.mem`), back-to-back autorun, every output spike XOR-folded into the LEDs |
| `tb_top_spiker.vhd` | GHDL check of the harness (2 inferences: output spikes at every step = model, bit-exact) |
| `build_spiker.tcl`, `nexys_spiker.xdc` | Vivado non-project flow (same steps and reports as `fpga/build.tcl`) |
| `tb_spk_net.sv` | gate-level testbench for the routed netlist (SAIF run) |

Note for fairness: Spiker+ stores weights in ROMs (VHDL constants), as generated. Synthesis may trim constant
weight bits, which can only favour Spiker+ in area and power; our HUSH/BASE use writable RAMs.
