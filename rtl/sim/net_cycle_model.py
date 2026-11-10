"""Cycle model of rtl/hush_net.sv (A9.2): hidden layer (L1), spike FIFO + drain, output layer (L2), classifier.

L1 follows cycle_model.rtl_cycles block by block (no FIFO back-pressure: the model reports the peak FIFO
occupancy so a caller can check it stays below FIFO_D - 3). For a block whose FIN2 is cycle e (L1 timeline):
  the FIFO entry can be popped from cycle e + 2; the drain takes 1 (pop) + popcount + 1 cycles per entry;
  for the last block of timestep t, L2 may start timestep t two cycles after that entry's last drain cycle.
L2 (one block, dense) per timestep: COMBINE + 4 + (n + 4 if n > 0 else 1) + SEL + STEP_END; it waits in COMBINE.
Classifier: NOUT cycles after L2's done. Constant offsets are fixed against the RTL (see check in run_net.py).
"""
from __future__ import annotations

import numpy as np

from cycle_model import block_cycles, etu_cycles

OFF_TOTAL = 2      # start/done handshake; fixed against the RTL on 8 random nets (10 Nov), constant


def l1_schedule(n: np.ndarray, awake_blk: np.ndarray, envelope: bool):
    """FIN2 cycle of every block (L1 counter time) and L1 total cycles, exactly as rtl_cycles."""
    T, G = awake_blk.shape
    cyc = 0
    fin = np.zeros((T, G), np.int64)
    if envelope:
        cyc += etu_cycles(int(n[0])) + 2
    etu_done_at = 0
    for t in range(T):
        if envelope and t > 0:
            cyc = max(cyc, etu_done_at)
        cyc += 1
        if envelope and t + 1 < T:
            etu_done_at = cyc + 1 + etu_cycles(int(n[t + 1]))
        for b in range(G):
            cyc += block_cycles(int(n[t]), bool(awake_blk[t, b]))
            fin[t, b] = cyc - 1                       # index of the FIN2 cycle
        cyc += 2
    return fin, cyc


def net_cycles(n1: np.ndarray, awake_blk: np.ndarray, envelope: bool, hid_spikes: np.ndarray, nout: int,
               off: int | None = None):
    """Total cycles start -> class of hush_net, and peak FIFO occupancy. hid_spikes: (T, N1) 0/1."""
    T, G = awake_blk.shape
    fin, l1_total = l1_schedule(n1, awake_blk, envelope)
    pc = hid_spikes.reshape(T, G, 32).sum(2)
    d_end = -10 ** 9
    ready = np.zeros(T, np.int64)                    # first cycle L2 may run COMBINE for timestep t
    arrivals, pops = [], []
    for t in range(T):
        for b in range(G):
            a = fin[t, b] + 2
            p = max(a, d_end + 1)
            d_end = p + int(pc[t, b]) + 1
            arrivals.append(a - 1)
            pops.append(p)
        ready[t] = d_end + 2
    # FIFO occupancy: entry i in the FIFO from cycle arrivals[i] (written) until pops[i] (popped)
    ev = sorted([(x, 1) for x in arrivals] + [(x, -1) for x in pops])
    occ = peak = 0
    for _, dlt in ev:
        occ += dlt
        peak = max(peak, occ)
    n2 = hid_spikes.sum(1).astype(np.int64)
    c = 0
    for t in range(T):
        c = max(c, int(ready[t]))
        c += 1 + 4 + (int(n2[t]) + 4 if n2[t] > 0 else 1) + 2
    total = c + nout + (OFF_TOTAL if off is None else off)
    return total, peak, l1_total
