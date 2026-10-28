"""Derived memory images for hush_layer v5 (28 Oct 2026, A3b).
w0..w3.hex : the four 64-bit sub-block columns of w.hex (column s = lanes 8s..8s+7 = bits [64s+63:64s]).
ts2.hex    : 32-bit pairs {ts[i+1], ts[i]}, one per ts entry (last entry pairs with itself), so the event range
             of a timestep is one synchronous BRAM read.
"""
from pathlib import Path


def derive(d):
    d = Path(d)
    w = [l.strip() for l in open(d / "w.hex") if l.strip() and not l.startswith("//")]
    for s in range(4):
        with open(d / f"w{s}.hex", "w") as f:
            for x in w:
                x = x.zfill(64)
                f.write(x[64 - 16 * (s + 1):64 - 16 * s] + "\n")
    ts = [int(l, 16) for l in open(d / "ts.hex") if l.strip() and not l.startswith("//")]
    assert max(ts) < 1 << 16
    with open(d / "ts2.hex", "w") as f:
        for i, x in enumerate(ts):
            nxt = ts[i + 1] if i + 1 < len(ts) else x
            f.write(f"{nxt:04x}{x:04x}\n")


if __name__ == "__main__":
    import sys
    for p in sys.argv[1:]:
        derive(p)
        print("derived", p)
