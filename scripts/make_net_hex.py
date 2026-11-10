"""L1 (10 Nov 2026): memory images for the whole-network power builds (fpga/top_net.sv, STREAM = 0).

    python scripts/make_net_hex.py --nsmp 20

fpga/netpwr/<case>/ : w0..w3, p, q (hidden layer), ev.hex + ts2.hex (NSMP samples, as make_power_hex.py),
o0..o3 (output layer, 10 classes padded to 32 with -128), expected.csv (per sample: class, golden class, model
cycles). Cases: base (ungated net, run ungated), mf_gentle12, mf_gentler12, mf_aggr (seed 0 weights).
Also fpga/netstream/<case>/ for the two stream-mode builds (no events; NEV = 1024 ring).
"""
import argparse
import sys
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / "rtl" / "sim")]
from run_case import hexrow, write_mems  # noqa: E402
from hexutil import derive  # noqa: E402
from net_cycle_model import net_cycles  # noqa: E402
from run_net import golden, pad_out  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402

CASES = {"base": ("nmnist_T100", 0), "mf_gentle12": ("nmnist_T100_mf_e05_d025_ep12", 1),
         "mf_gentler12": ("nmnist_T100_mf_e025_d01_ep12", 1), "mf_aggr": ("nmnist_T100_mf_e2_d1", 1),
         "base_ctrl": ("nmnist_T100_ft12_ctrl", 0)}   # 10 Nov: BASE trained as long as the gated nets (paper's BASE)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--nsmp", type=int, default=20)
    a = ap.parse_args()
    z0 = np.load(ROOT / "results" / "nmnist_T100" / "weights.npz")
    R, Y = test_rasters(z0, a.nsmp)
    ev, ts = [], []
    for S in R:
        ts.append(len(ev))
        for t in range(S.shape[0]):
            ev += np.flatnonzero(S[t]).tolist()
            ts.append(len(ev))
    assert len(ev) < 65536
    for name, (tag, g) in CASES.items():
        z = np.load(ROOT / "results" / tag / "weights.npz")
        W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
        Wo = pad_out(W2, W2.shape[1])
        k, th = int(z["k"]), int(z["theta"])
        for sub in (("netpwr",) if name == "base_ctrl" else ("netpwr", "netstream")):
            d = ROOT / "fpga" / sub / name
            d.mkdir(parents=True, exist_ok=True)
            write_mems(d, W1, R[0].astype(np.int64))                  # w0..w3, p, q (ev/ts overwritten below)
            t2 = d / "_l2"
            t2.mkdir(exist_ok=True)
            write_mems(t2, Wo, np.zeros((1, Wo.shape[0]), np.int64))
            for s in range(4):
                (d / f"o{s}.hex").write_text((t2 / f"w{s}.hex").read_text())
            for f in t2.iterdir():
                f.unlink()
            t2.rmdir()
            if sub == "netpwr":
                (d / "ev.hex").write_text("".join(f"{e:04x}\n" for e in ev))
                (d / "ts.hex").write_text("".join(f"{x:04x}\n" for x in ts))
            else:
                (d / "ev.hex").write_text("0000\n")
                (d / "ts.hex").write_text("0000\n")
            derive(d)
            (d / "none.hex").write_text("0\n")                   # output layer's unused p/q/ev/ts2 tables
            for f in ("w.hex", "ts.hex"):
                (d / f).unlink()
        rows = ["idx,label,class,cycles"]
        for i, (S, y) in enumerate(zip(R, Y)):
            S = S.astype(np.int64)
            h, o, cls = golden(W1, Wo, S, k, th, g, g, W2.shape[1])
            c, _, _ = net_cycles(S.sum(1), h.awake_blk, bool(g), h.spikes.astype(np.int64), W2.shape[1])
            rows.append(f"{i},{int(y)},{cls},{c}")
        (ROOT / "fpga" / "netpwr" / name / "expected.csv").write_text("\n".join(rows) + "\n")
        cy = [int(r.split(",")[3]) for r in rows[1:]]
        print(name, "mean model cycles", np.mean(cy), "events", len(ev))


if __name__ == "__main__":
    main()
