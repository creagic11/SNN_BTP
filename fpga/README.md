# FPGA flow (Phase 3) — XC7A100T-1CSG324C (Nexys A7-100T), Vivado 2024.1

Status (27 Oct 2026): BASE, HUSH-drop and HUSH-MF all **meet timing at 100 MHz** after place and route. Results are in `results/vivado_2024_1/`.

## Steps

1. Generate the memory images for a network and one test sample (from the repo root). This writes `fpga/hex/{w,p,q,ev,ts}.hex`; the N-MNIST sample has 2,669 events, under NEV = 4096.

        python -c "import sys; sys.path[:0]=['.','rtl/sim']; import numpy as np; from pathlib import Path; from run_case import write_mems; from scripts.measure_rho import pad_hidden, test_rasters; z=np.load('results/nmnist_T100_mf_e05_d025/weights.npz'); W,_,_=pad_hidden(z['W0'].astype('int64'),z['W1'].astype('int64'),32); r,_=test_rasters(z,1); Path('fpga/hex').mkdir(exist_ok=True); print(write_mems(Path('fpga/hex'),W,r[0].astype('int64')))"

2. Copy `rtl/hush_arith.sv`, `rtl/hush_layer.sv` and the `fpga/` folder (with `hex/`) to the build machine, keeping the `rtl/` and `fpga/` layout. On the user's laptop this is `C:\Users\Anubhav\hush_fpga`. **Check the RTL checksum after copying** (`md5sum rtl/hush_layer.sv`): one transfer once delivered a stale file.

3. Build, from the `fpga/` folder in the Vivado Tcl Shell:

        vivado -mode batch -source run_all.tcl     # BASE, HUSH-drop, HUSH-MF (~45 min)
        vivado -mode batch -source run_hush.tcl    # HUSH-drop and HUSH-MF only (~30 min)

   `build.tcl` is the per-variant non-project flow: synth, opt, place, phys_opt, route, reports, bitstream. Its arguments are `<hexdir> <outdir> GATE MF [M N T K]`.

4. Reports land in `../out_<variant>/`: `util.rpt`, `util_hier.rpt`, `timing.rpt` (WNS at 100 MHz) and `power_vectorless.rpt`. `../out_summary.txt` lists OK/FAILED per variant.

`top_hush.sv` runs inferences back to back on the stored sample (autorun), so the board draws steady power. LEDs show a heartbeat and an XOR of output spikes, so nothing is optimised away.

## Timing closure history (27 Oct)

| Run | Change | HUSH-MF WNS |
| --- | --- | --- |
| 1 | original RTL (lane update + serial 8-input max into R in one cycle, 33 levels) | −14.8 ns |
| 2 | two-stage finalize: register saturated U + awake bits; FIN2 applies spike/reset (+1 cycle per block; cycle model updated) | −4.0 ns |
| 3 | R refresh from a registered word through a balanced two-stage max tree (R is next read ≥ 3 cycles later) | **+0.45 ns** |

Every change was bit-exact against the golden model: 40/40 random regression cases, and N-MNIST in all three modes, 800/800 block write-backs with cycles equal to the model.

## Next

- **T3.2:** SAIF power from an xsim run over ≥ 100 samples.
- **T3.3:** board ΔP (BASE vs HUSH bitstreams) once a Nexys A7-100T and a power meter are available.
