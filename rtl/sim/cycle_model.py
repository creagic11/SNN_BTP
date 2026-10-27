"""Exact cycle model of rtl/hush_layer.sv v1, from a golden trace (T2.4).

Per timestep t with n_t active inputs and the block gates of the golden model:
  COMBINE       : 1 cycle, plus a stall until the envelope bank for t is ready
  awake block   : SEL + LOAD + RUN + FIN + FIN2 = 4 + (n_t + 3 if n_t > 0 else 1)
  asleep block  : SEL + SLP_FIN + FIN2 = 3
  end of step   : SEL (b == G) + STEP_END = 2
The envelope unit for t+1 starts one cycle after COMBINE(t) and needs n_{t+1} + 3 cycles
(or 1 when n = 0); COMBINE(t+1) stalls if the block loop of t finishes earlier.
Timestep 0 is preceded by the envelope pass for t = 0 (ETU0 state). BASE (GATE=0, MF=0) has no
envelope unit.
"""

from __future__ import annotations

import numpy as np


def etu_cycles(n: int) -> int:
    return n + 3 if n > 0 else 1


FIN_STAGES = 2   # finalize is two stages since the 27 Oct timing fix (FIN + FIN2)


def block_cycles(n: int, awake: bool) -> int:
    return (2 + FIN_STAGES + (n + 3 if n > 0 else 1)) if awake else 1 + FIN_STAGES


def rtl_cycles(n: np.ndarray, awake_blk: np.ndarray, envelope: bool) -> int:
    T, G = awake_blk.shape
    cyc = 0
    if envelope:
        cyc += etu_cycles(int(n[0])) + 2          # ETU0 wait incl. the go pulse and the ready check
    etu_done_at = 0
    for t in range(T):
        start = cyc
        if envelope and t > 0:
            cyc = max(cyc, etu_done_at)           # stall in COMBINE until bank ready
        cyc += 1                                  # COMBINE
        if envelope and t + 1 < T:
            etu_done_at = cyc + 1 + etu_cycles(int(n[t + 1]))
        cyc += sum(block_cycles(int(n[t]), bool(a)) for a in awake_blk[t])
        cyc += 2                                  # SEL(b==G) + STEP_END
    return cyc
