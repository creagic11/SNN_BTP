# FPGA flow (Phase 3) — XC7A100T-1CSG324C, Nexys A7-100T

1. Generate the memory images for a network and one test sample (from the repo root):

        python -c "import sys; sys.path[:0]=['.','rtl/sim']; import numpy as np; from pathlib import Path; from run_case import write_mems; from scripts.measure_rho import pad_hidden, test_rasters; z=np.load('results/nmnist_T100_mf_e05_d025/weights.npz'); W,_,_=pad_hidden(z['W0'].astype('int64'),z['W1'].astype('int64'),32); r,_=test_rasters(z,1); Path('fpga/hex').mkdir(exist_ok=True); print(write_mems(Path('fpga/hex'),W,r[0].astype('int64')))"

2. Build HUSH-MF and BASE (Vivado 2020.2 or newer, batch mode):

        vivado -mode batch -source fpga/build.tcl -tclargs fpga/hex fpga/out_hush_mf 1 1
        vivado -mode batch -source fpga/build.tcl -tclargs fpga/hex fpga/out_base 0 0

3. Reports land in `fpga/out_*`: `util.rpt`, `util_hier.rpt`, `timing.rpt` (WNS at 100 MHz), `power_vectorless.rpt`. SAIF-based power and the board measurement follow in T3.2/T3.3.

`top_hush.sv` runs inferences back to back on the stored sample (autorun) so the board draws steady power; LEDs show a heartbeat and an XOR of output spikes so nothing is optimised away.
