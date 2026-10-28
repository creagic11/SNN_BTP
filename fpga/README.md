# FPGA flow — XC7A100T-1CSG324C (Nexys A7-100T), Vivado 2024.1

Status (28 Oct 2026): **hush_layer v5**. All six builds (three timing/area builds, three 20-sample power builds)
meet timing at 100 MHz, and gate-level SAIF power is done. Results: `results/power_saif_v5/`. Everything earlier
(`results/vivado_2024_1/`, `results/power_saif/`) is superseded: see "Corrections" below.

## Commands that work on the laptop (C:\Users\Anubhav\hush_fpga)

Run them in the **Vivado 2024.1 Tcl Shell**. It is a Tcl prompt: use forward slashes in paths, and run .bat
files through `exec`.

    cd C:/Users/Anubhav/hush_fpga/fpga
    exec -ignorestderr cmd /c run_v5.bat

`run_v5.bat` runs unattended for about 2–2.5 hours. Progress goes to `..\out_v5c\summary.txt` and results to
`..\out_v5c\energy.csv`. (To rerun into a fresh folder, change `out_v5c` in prep_v5.tcl, annotate_v5.tcl and
run_v5.bat; an existing `routed.dcp` is reused.)

1. `prep_v5.tcl` (Vivado batch): builds `timing/{base,hush_drop,hush_mf}` with 1 sample on chip, then
   `pwr/{base,mf_gentle,mf_aggr}` with 20 N-MNIST samples. For each power build it writes the routed functional
   netlist (`write_verilog -mode funcsim`) and compiles it with glbl and unisims_ver (xvlog/xelab).
2. xsim runs **outside** Vivado (`run_v5.bat :sim`), logging SAIF for every net under `tb_net/u_top`. Launched
   from inside Vivado, xsim crashed on this laptop with EXCEPTION_ACCESS_VIOLATION.
3. `annotate_v5.tcl` (fresh Vivado): `fix_saif_names.tcl` rewrites xsim's escaped names into the form read_saif
   matches, then `read_saif -strip_path tb_net/u_top`, `report_power`, and energy = power × latency.

Memory images: `scripts/make_power_hex.py --nsmp 20` → `fpga/pwr/<case>/` (w0..w3, p, q, ev, ts2 + expected
cycles). The single-sample images in `fpga/hex/` come from `rtl/sim/run_case.py write_mems` + `rtl/sim/hexutil.py`.
After copying files to the laptop, **check md5 sums**: one transfer delivered a stale file.

Checks before trusting a run: every build has WNS ≥ 0; `util_hier.rpt` of BASE lists 32 lanes and `ram_util.rpt`
lists 4 weight columns; read_saif matches 100% of nets; netlist cycles = `expected.csv` + 3..8.

## Design changes in v5 (28 Oct), each verified bit-exact in simulation

| Change | Why |
| --- | --- |
| LEDs XOR-fold all 32 spikes and all 512 state bits | the old fold observed lanes 0-5 and 26-31 only, so synthesis deleted most of BASE |
| every table is a writable BRAM with a UART load port (`uart_loader.sv`, pin C4) | as ROMs, synthesis trimmed INT8 weights to 6 bits |
| four 64-bit weight-column RAMs, each read only when its sub-block is awake | the column gating existed only in a counter |
| ts stored as {ts[t+1], ts[t]} pairs in true-dual-port BRAM (ETU +1 cycle) | 4 read ports had become a 10k-LUT ROM in HUSH only |
| `ram_decomp = "power"` on the deep event and weight RAMs | each read enables one BRAM (both BASE and HUSH) |
| event index registered before the weight address (+1 cycle per awake block with events) | critical path, −2.26 ns in the power builds |
| named generate scopes in the max tree | unnamed scopes became "(null)" net names that read_saif rejects |

## Timing closure history

| Run | Change | HUSH-MF WNS |
| --- | --- | --- |
| 27 Oct, 1 | original RTL | −14.8 ns |
| 27 Oct, 2 | two-stage finalize | −4.0 ns |
| 27 Oct, 3 | balanced two-stage max tree for R | +0.45 ns |
| 28 Oct, v5 | writable RAMs, column enables, event-index register | +0.496 ns (power builds +0.491) |

## Next

- **A7:** board power (BASE vs HUSH bitstreams) once a Nexys A7-100T and a power meter are available.
