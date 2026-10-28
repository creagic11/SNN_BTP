"""Bit-exact check of the multi-sample power builds against the golden model, for every sample and block.

    python rtl/sim/check_power_build.py            # all three cases in fpga/pwr/
"""
import subprocess, sys, tempfile, shutil
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT)]
from golden.hush import LIFParams, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402

cases = {"base": ("nmnist_T100", 0, 0, 2), "mf_gentle": ("nmnist_T100_mf_e05_d025", 1, 1, 3), "mf_aggr": ("nmnist_T100_mf_e2_d1", 1, 1, 4)}
exp = [l.split(",") for l in (ROOT / "fpga/pwr/expected.csv").read_text().splitlines()[1:]]
NS = len(exp)
ok_all = True
for case, (tag, g, m, col) in cases.items():
    z = np.load(ROOT / "results" / tag / "weights.npz")
    W0, _, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
    k, th = int(z["k"]), int(z["theta"])
    R, _ = test_rasters(np.load(ROOT / "results/nmnist_T100/weights.npz"), NS)
    with tempfile.TemporaryDirectory() as td:
        for f in (ROOT / "fpga/pwr" / case).glob("*.hex"):
            shutil.copy(f, td)
        exe = Path(td) / "sim.vvp"
        cp = subprocess.run(["iverilog", "-g2012", "-o", str(exe), "-s", "tb_pwr", "-P", f"tb_pwr.GATE={g}", "-P", f"tb_pwr.MF={m}",
                        "-P", f"tb_pwr.NSMP={NS}", str(ROOT / "rtl/hush_arith.sv"), str(ROOT / "rtl/hush_layer.sv"),
                        str(ROOT / "fpga/uart_loader.sv"), str(ROOT / "fpga/top_hush.sv"), str(ROOT / "rtl/sim/tb_pwr.sv")],
                       check=True, capture_output=True, text=True)
        assert "error" not in cp.stderr.lower(), cp.stderr
        subprocess.run(["vvp", "-n", str(exe)], cwd=td, check=True, capture_output=True)
        lines = (Path(td) / "pwr_out.txt").read_text().splitlines()
    mism = 0; cyc_diff = []
    for i, S in enumerate(R):
        S = S.astype(np.int64)
        tr = (run_ref(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32)) if not g else
              run_gated(W0, S, LIFParams(k=k, theta=th, b_env=8, b_blk=32, asleep_drive="mean"), shadow=False))
        rows = [l.split() for l in lines if l.startswith(f"S {i} ")]
        assert len(rows) == 100 * 8, (case, i, len(rows))
        for _, _, ts, bs, spk, vhex in rows:
            t, b = int(ts), int(bs)
            sp = np.array([(int(spk, 16) >> l) & 1 for l in range(32)], np.uint8)
            vi = int(vhex, 16)
            v = np.array([(vi >> (16 * l)) & 0xFFFF for l in range(32)], np.int64); v = np.where(v >= 1 << 15, v - (1 << 16), v)
            if not (np.array_equal(sp, tr.spikes[t, 32 * b:32 * b + 32]) and np.array_equal(v, tr.V[t, 32 * b:32 * b + 32])):
                mism += 1
        cyc = int([l.split() for l in lines if l.startswith(f"I {i} ")][0][2])
        cyc_diff.append(cyc - int(exp[i][col]))
    ok = mism == 0
    ok_all &= ok
    print(f"{case}: {NS} samples, block mismatches {mism}/{NS * 800}, sim-minus-model cycles {cyc_diff} -> {'PASS' if ok else 'FAIL'}")
sys.exit(0 if ok_all else 1)
