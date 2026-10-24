"""Randomised RTL regression against the golden models (Icarus Verilog).

    python rtl/sim/regress.py --n 40
Varies M, N, T, k, theta, input rate, weight range, GATE and MF; reports any failing seed.
"""

import argparse
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from run_case import check  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=40)
    ap.add_argument("--seed0", type=int, default=100)
    a = ap.parse_args()
    fails, slept = [], 0
    for s in range(a.seed0, a.seed0 + a.n):
        rng = np.random.default_rng(s)
        M = int(rng.integers(5, 80))
        N = 32 * int(rng.integers(1, 4))
        T = int(rng.integers(1, 20))
        k = int(rng.integers(1, 6))
        theta = int(rng.integers(16, 300))
        wr = int(rng.choice([16, 64, 127]))
        bias = int(rng.integers(-wr // 2, 1))          # negative-leaning weights make blocks sleep
        W = np.clip(rng.integers(-wr, wr + 1, size=(M, N)) + bias, -128, 127)
        rate = float(rng.choice([0.02, 0.08, 0.25, 0.6]))
        S = (rng.random((T, M)) < rate).astype(np.int64)
        gate, mf = int(rng.integers(0, 2)), int(rng.integers(0, 2))
        ok, _ = check(W, S, k, theta, gate, mf, verbose=True)
        if not ok:
            fails.append(s)
    print(f"{a.n - len(fails)}/{a.n} passed; failing seeds: {fails}")
    sys.exit(1 if fails else 0)


if __name__ == "__main__":
    main()
