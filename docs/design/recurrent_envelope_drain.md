# Recurrent envelope update: design decision (P2, 26 Oct 2026)

**Decision:** duplicated, true dual-port P_rec (and Q_rec) BRAM. The rows of each block's spike burst drain while the *next* block's PE pass runs. The scheduler issues awake blocks first and asleep blocks last. Spikes are treated as final only at BLK_FIN, with no speculative or early fetch.

## Why (evidence)

| Proposal | Verdict | Reason |
| --- | --- | --- |
| (a) shared weight port | rejected | steals PE cycles one-for-one per spike |
| (b) duplicated P_rec BRAM | **adopted** | 4 RAMB36 for P_rec at 72-bit SDP width (8 with Q_rec) out of 135; no port conflict |
| PAB (one-cycle combinational merge of a burst + LUTRAM staging) | rejected | D_{t+1} is a 576-bit register, so there is no BRAM read-modify-write loop; merging k rows in one cycle needs k simultaneous 256-bit row reads (≈ 4k RAMB36 ports); gate(t+1) needs the full D_{t+1}, so the drain cannot be hidden behind its own use |
| Early-fetch on mid-pass threshold crossing | rejected | dataflow is input-serial, so U is final only at BLK_FIN; 0.40 false crossings per true spike (45% of weights are negative); a wrong negative row lowers D, which is **unsafe** (breaks Theorem 1′) |
| Exact lookahead finality signal | rejected | needs future-event weights (O(n) per lane); static bounds almost never fire |

## Exposed tail (cycles per inference)

Source: `scripts/rec_tail_model.py`, SHD 87% model, 40 test samples. Block-loop cost is about 145k cycles per inference (1.45 ms at 100 MHz, for 1 s of audio).

| Policy | 1 port | 2 ports (dual-port) |
| --- | --- | --- |
| naive (all rows after the loop) | 9,553 (6.6%) | 5,155 (3.6%) |
| overlap with the next block's pass | 1,292 (0.89%) | 665 (0.46%) |
| overlap + awake-first ordering | same on the un-co-trained net (almost all blocks awake); helps once co-training creates asleep blocks | |

The chosen configuration is overlap, dual-port, awake-first: about 0.46% overhead. The remaining tail is the last awake block's burst, (s + 1)/2 + 3 cycles, partly covered by asleep blocks and STEP_END.

Cost: a second 32-lane accumulate path (≈ 600 LUTs) for the second port, and a small spike FIFO of 32 entries (one block's maximum burst).
