# HUSH from scratch — a primer

*Anubhav Jha (23EE10091), B.Tech thesis, IIT Kharagpur, supervisor Prof. Rajat Shubhra Chakraborty. State as of 28 Oct 2026.*

How to use this: read §0 first (5 minutes). Then go section by section; each ends with **Check yourself** questions.
Numbers here are the current (v5) ones. Older numbers you may see in the repo history (1.3k-LUT BASE, 15–46 %
energy saving, vectorless power) are wrong and must never be quoted (§8 explains why).

---

## 0. The whole project in one page

**Problem.** A spiking neural network (SNN) layer on an FPGA spends most of its time and energy fetching weights
from block RAM: for every input spike, it reads the weights of every neuron. Most of those neurons will not fire
this timestep, so most of that work is wasted. But you cannot know which ones will not fire without doing the work…
unless you can *prove* it cheaply.

**Idea (HUSH).** Group neurons into sub-blocks of 8. Before a timestep's weights are fetched, compute a cheap,
provably safe *upper bound* on how high any neuron in the sub-block can go this step. If the bound is below the
firing threshold, the whole sub-block sleeps: its weight reads are skipped. Because it is an upper bound, a sleeping
sub-block can never contain a neuron that would have fired (**zero suppressed spikes, proven**).

**What we built.** An integer SNN (578-256-10, N-MNIST), trained with the gate in the loop; a bit-exact golden model,
RTL in SystemVerilog, a formal proof of the gate on the RTL, and a placed-and-routed Artix-7 XC7A100T design at 100 MHz.

**Results (whole network, N-MNIST).**

| Design | Accuracy | Latency / inference | Energy / inference | LUTs |
|---|---|---|---|---|
| BASE (same hardware, gate off) | 97.59 % | 302.9 µs | 43.9 µJ | 3.8k |
| HUSH gentle | 95.32 % | 153.0 µs (1.98× faster) | 23.1 µJ (−47 %) | 9.8k |
| HUSH aggressive | 92.72 % | 97.2 µs (3.12× faster) | 15.3 µJ (−65 %) | 9.8k |

**Versus the state of the art.** The best published N-MNIST FPGA design (FPT 2023) gets 95.76 % at 50 ms and
≈17.5 mJ per inference. HUSH gentle matches its accuracy at ≈330× lower latency and ≈760× lower energy, with 4–17×
fewer LUTs. Competing *skipping* schemes at the same savings either lose accuracy badly or suppress spikes; HUSH
suppresses none.

**Weak points.** Accuracy (we lose 2.3–4.9 points to our own ungated net); power is a Vivado estimate, not a board
measurement; HUSH only pays on networks with "headroom" (slow leak, mostly inhibited neurons), not on recurrent
adaptive or fast-leak delay networks. A GPU closes the first gap, a Nexys A7-100T board the second.

**Where it is going.** Paper A (tier-2: TCAS-II or DATE) now; Paper B (tier-1: ICCAD/TCAD) after a GPU.

---

## 1. Spiking neurons, the minimum you need

**LIF neuron (leaky integrate-and-fire), integer version, one timestep t:**

```
U_i = clip( L(V_i) + Σ_j z_j · W_ji )        # leak old potential, add weights of inputs that spiked
s_i = [U_i ≥ θ]                              # spike if over threshold θ (= 64 here)
V_i' = U_i − θ·s_i                           # soft reset: subtract θ, keep the residue
```

- `z_j ∈ {0,1}`: did input j spike this step. Only active inputs cost work (event-driven).
- **Leak** `L(x) = x − (x >> k)`: multiply by (1 − 2⁻ᵏ) with one shift and one subtract, no multiplier. Here k = 4,
  so the potential keeps 15/16 per step. Larger k = slower leak = longer memory.
- **Integers everywhere:** INT8 weights, 16-bit potentials, saturating ("clip") arithmetic. The trained model,
  the golden model and the hardware compute *exactly the same integers*, so every result is checkable bit for bit.
- **N-MNIST:** MNIST digits recorded by a moving event camera. Two polarities × 34×34 pixels, pooled 2×2 to
  2×17×17 = **578 inputs**; 300 ms binned into **T = 100 timesteps**. A sample has a few thousand input events.
- **Network:** 578 inputs → 256 hidden LIF neurons → 10 output neurons. The hardware accelerates the hidden layer
  (almost all of the work); the output layer (256 → 10) is tiny.
- **Training:** surrogate gradients (backprop through time with a smooth stand-in for the spike step), with the
  integer forward pass kept exact.

**Check yourself.** Why does soft reset keep information that hard reset loses? Why does k = 4 mean "slow" leak?
Why must training and hardware share one integer kernel?

---

## 2. Where the work goes, and why skipping is hard

Per timestep, a dense (BASE) layer does, for each active input j, a read of the 256 weights in row j and 256 adds.
That is a **synaptic operation (SOP)** per (active input, neuron): 683,055 per N-MNIST inference on average.

Three kinds of sparsity exist:
1. **Static weight sparsity** (pruning) — fixed zeros.
2. **Input-spike sparsity** — only active inputs cost work. Every event-driven design already exploits this.
3. **Output-state sparsity** — neurons that will not fire this step. *This is HUSH's axis.*

Why output skipping is hard: you only know a neuron will not fire *after* you add up its inputs. Guessing
(heuristics) suppresses real spikes. And skipping single neurons does not help hardware: weights come from BRAM in
wide words covering many neurons; a word must be read if *any* neuron in it is needed. So skipping must be per
**block of neurons**, and a block only sleeps if *all* its neurons are safe.

**Check yourself.** What is an SOP? Why is per-neuron skipping useless on BRAM?

---

## 3. The HUSH gate and why it is provably safe

**Grouping.** 256 neurons = 8 blocks of 32 = 32 **sub-blocks of 8**. One 256-bit weight word = 32 INT8 weights =
4 columns of 64 bits; each column feeds one sub-block of 8 neurons. In v5 each column is its own BRAM, enabled only
if its sub-block is awake.

**Two tables, computed once from the weights:**
- **Proxy** `P[j][c] = max over neurons i in sub-block c of W_ji` — the largest weight input j gives anyone in c.
- **Mean** `Q[j][c] = floor(mean of W_ji over c)` — used by the mean-field variant (below). Note Q ≤ P.

**The bound, per sub-block c, per timestep:**
- `R_c` = the exact maximum potential V of the sub-block after the last step (the hardware keeps it).
- `D_c = Σ_{active j} P[j][c]` — worst-case drive this step (one P row read per active input, not 8 weight reads).
- **Envelope** `E_c = clip(L(R_c)) + max(0, D_c)`.
- **Gate:** sub-block awake iff `E_c ≥ θ`. Otherwise it sleeps this step.

**Theorem 1 (safety), in words.** For any neuron i in c: its old potential ≤ R_c, the leak L is non-decreasing (so
L(V_i) ≤ L(R_c)), and each weight it receives ≤ the proxy (so its drive ≤ D_c). Clip is also non-decreasing. So
U_i ≤ E_c < θ: **no neuron in a sleeping sub-block can fire.** Induction over timesteps covers every step.

**What it does *not* claim.** A sleeping neuron skips its sub-threshold drive, so its *future* potential differs from
the ungated network. Spikes at this step are identical; later spikes can differ. That is why accuracy, not spike
equality, is the end-to-end metric, and why the network is **co-trained with the gate**.

**Two ways to treat sleeping neurons:**
- **HUSH-drop:** they only leak (drive dropped).
- **HUSH-MF (mean-field):** they get the cheap shared drive `Σ_j Q[j][c]` (one Q row read per input, shared by all 8).
  Since Q ≤ P, the bound still holds; accuracy is much better than drop. **HUSH-MF is our main design.**

**Proof status.** Paper proof (Theorem 1, and Theorem 1′ for recurrent adaptive neurons); Hypothesis property tests
on the golden models, with mutation tests that show the tests catch unsafe variants; and a **formal proof on the RTL
arithmetic with SymbiYosys (unbounded, PDR)** — a deliberately unsafe gate fails the proof.

**Check yourself.** Prove U_i ≤ E_c in four lines. Why is max(0, D_c) used? Why does Q ≤ P keep mean-field safe?
What exactly is "zero suppressed spikes" — at which step and compared to what?

---

## 4. Training with the gate in the loop, and when HUSH pays

**Co-training.** The forward pass runs the gate exactly as hardware does; the gate's 0/1 decision gets a
straight-through gradient. Extra losses push the network toward sleeping: an **exceedance** loss (how far envelopes
exceed θ) and an **envelope-drive** loss (shrink positive proxies of active inputs), plus a firing-rate target (5 %).
Gentle = exceedance weight 0.5, drive weight 0.25; aggressive = 2 and 1. Both fine-tune the ungated net for 6 epochs.

**Result on N-MNIST:** gentle reads 16.8 % of weight columns, aggressive 6.7 %, at 95.32 % / 92.72 % accuracy.

**When does it pay? Headroom.** A sub-block sleeps when the gap between θ and its most excited neuron (headroom)
exceeds the step's worst-case drive (≈ active inputs × mean positive proxy). A neuron under steady inhibition b
settles at about 2ᵏ·|b| below rest, so **headroom ≈ θ + 2ᵏ·|b|: slow leak multiplies inhibition into headroom.**

| Network | headroom | weight reads after co-training |
|---|---|---|
| FF LIF, k = 5 (SHD) | 9.7 θ | 0.64 |
| recurrent adaptive LIF (SHD) | 0.09 θ | 0.98 (useless) |
| FF + axonal delays, fast leak (SHD) | 0.4–1.2 θ | 0.77–0.97, −6.7 pt when forced |

So HUSH suits sparse event-vision tasks with slow leaks (N-MNIST, DVS-Gesture); it does not suit the networks that
win SHD (recurrent adaptation, fast-leak delays). This is a measured, explainable limit — state it, don't hide it.

**Check yourself.** Why does a bigger k give more headroom? Why does recurrent adaptation kill it? What did the
k = 4 control show (gate alone −6.7 pt vs rate regulariser alone −0.5 pt)?

---

## 5. The hardware

```
                       ┌──────────── for timestep t+1, overlapped ────────────┐
 event store ──► ETU: for each active input j, read P row (and Q row) ──► D_c, Qsum_c (double-buffered)
      │                                                                          │
      │                 COMBINE (timestep t): gate_c = [clip(L(R_c)) + D_c ≥ θ] for all 32 sub-blocks
      │                                                                          │
      ▼                                                                          ▼
 block loop, 8 blocks of 32 neurons:
   any sub-block awake?  yes → LOAD state → RUN: for each active input, read weight columns of AWAKE
                                sub-blocks only, add into 32 accumulators → FIN/FIN2: leak, mean-field
                                drive for asleep sub-blocks, spike, soft reset, write back, update R_c
                         no  → 3-cycle asleep pass: leak + mean-field drive, write back, update R_c
```

- **ETU (envelope unit):** computes next step's D and Q-sums while the block loop works on this step, so the gate
  costs almost no extra time.
- **Cycle cost (exact model, matches gate-level simulation within 3–8 cycles per inference):** awake block =
  4 + (n_t + 4) cycles with n_t active inputs; asleep block = 3 cycles. An N-MNIST sample has ~27 active inputs per step, so an
  asleep block is ~12× cheaper than an awake one. Latency speedup ≈ how many blocks sleep.
- **Memories (all writable BRAM in v5, loadable over USB-UART):** weights (4 column RAMs, 4,624 × 64 bit each), P and
  Q tables (578 × 256 bit), input events, timestep index pairs, neuron state (distributed RAM).
- **Implementation:** Vivado 2024.1, XC7A100T-1CSG324C (the chip on a Nexys A7-100T), 100 MHz, all builds meet timing.

| Build | LUT | FF | BRAM (36K + 18K) | DSP | timing slack |
|---|---|---|---|---|---|
| BASE | 3,821 | 2,643 | 43 + 0 | 0 | +1.441 ns |
| HUSH-drop | 7,618 | 4,528 | 50 + 1 | 0 | +0.198 ns |
| HUSH-MF | 9,800 | 6,284 | 57 + 2 | 0 | +0.496 ns |

HUSH costs 2.6× BASE's LUTs (32 envelope comparators, ETU accumulators, P/Q tables) — still 15.5 % of the chip.

**Check yourself.** Why can the ETU run one step ahead? Why is an asleep block 3 cycles, not 0? Where does the
2.6× LUT overhead come from?

---

## 6. How everything was checked

1. **Golden model** (Python, integer): REF (ungated), GATED, and an ORACLE (perfect knowledge) for comparison.
2. **RTL vs golden, bit-exact:** every block write-back (spikes + 16-bit state) and every counter compared;
   80 random regressions + full N-MNIST samples for all three designs. Cycle counts must equal the model exactly.
3. **Formal proof** of the gate arithmetic on the RTL (SymbiYosys).
4. **Vivado place-and-route:** timing met; area from the routed design.
5. **Power, activity-based ("SAIF"):** the *routed netlist* is simulated over 20 real N-MNIST samples stored on
   chip; the switching activity of every net (100 % matched) is fed back into Vivado's power report. Energy per
   inference = power × latency. Limitations: still a Vivado estimate (no glitch power), not a board measurement.

**Check yourself.** Why is gate-level simulation better than RTL simulation for power? What would a board add?

---

## 7. Results and the state-of-the-art comparison

**Ours (whole network, 500 test samples, 100 MHz):**

| Design | Accuracy | Latency | Throughput | Weight-column reads | Power | Energy | per SOP |
|---|---|---|---|---|---|---|---|
| BASE | 97.59 % | 302.9 µs | 3,301/s | 1.00 | 145 mW | 43.9 µJ | 64.3 pJ |
| HUSH gentle | 95.32 % | 153.0 µs | 6,537/s | 0.168 | 151 mW | 23.1 µJ | 33.8 pJ |
| HUSH aggressive | 92.72 % | 97.2 µs | 10,284/s | 0.067 | 157 mW | 15.3 µJ | 22.4 pJ |

Reading it: about 101 mW of each total is the chip's static (leakage) power, the same for every design, so **energy
mostly follows latency**. HUSH also switches less: dynamic energy per hidden-layer inference 12.6 → 7.2 → 4.9 µJ.

**Four levels of comparison (what each proves):**
1. **Internal ablation** (BASE vs HUSH, same chip, same RTL): isolates what HUSH itself adds. *Strongest evidence.*
2. **Competing skipping ideas in the same setting** (same nets, same sub-blocks, thresholds tuned to equal savings):

   | N-MNIST | Accuracy | Reads | Suppressed spikes |
   |---|---|---|---|
   | HUSH | 95.5 % | 0.157 | **0** |
   | SITRA-style (ISLPED 2025; ignores membrane state) | 66.0 % | 0.149 | 15,121 |
   | Early-style (ICCD 2024; membrane + top-8 weights) | 93.5 % | 0.153 | 36 |

   Caveats in our favour, stated openly: Early's extra weight reads are not charged; the nets were co-trained with HUSH.
3. **Same-device external baseline** — Spiker+ on the XC7A100T. *Task 2 (next).*
4. **Published state of the art:**

   | Work | FPGA | Accuracy | LUT | Latency | Energy / inference |
   |---|---|---|---|---|---|
   | HUSH gentle (ours) | Artix-7 100T | 95.32 % (N-MNIST) | 9.8k | 153 µs | 23.1 µJ |
   | Wu, Song & So, FPT 2023 | ZCU102 | 95.76 % (N-MNIST) | 39.7k–165k | 50 ms | ≈17.5 mJ |
   | Ansari & Wielgosz 2026 | Artix-7 200T | 96.7 % (MNIST) | 16.0k | 82 µs | ≈27.6 µJ |
   | Spiker-LL 2026 | PYNQ-Z2 | 90 % (MNIST) | 8.5k | 120 µs | 39 µJ |
   | Spiker+ 2024 | 7-series | 96.83 % (MNIST) | 7.6k cells | 780 µs | ≈140 µJ |

   ≈ = computed by us as power × latency from the paper's numbers. Cross-paper ratios mix devices, networks and
   design styles; only level 1 isolates HUSH's own contribution. Say this before a reviewer does.

**Check yourself.** Which level of comparison would you lead with, and why? Why does SITRA-style collapse? Why are
the 330×/760× ratios not "HUSH's" gains?

---

## 8. Why the earlier (v1) numbers were thrown away

On 28 Oct an audit of our own builds found four problems a reviewer would have rejected:
1. The test top level only observed 12 of 32 output lanes, so Vivado **deleted most of BASE** (1.3k LUT instead of 3.8k).
2. Weight tables were ROMs, so Vivado **stored INT8 weights in 6 bits**.
3. HUSH's per-sub-block weight gating **existed only in a counter**, not in the hardware read enables.
4. Power was **vectorless** (assumed switching rates), and a test-harness ROM added 10k LUTs to HUSH only.

All fixed in v5 and re-verified. Net effect: the honest comparison is *better* for HUSH (−47/−65 % energy vs the
earlier −15/−46 %). Knowing this story is a strength in a viva: it shows the numbers were attacked before anyone else did.

---

## 9. What is left, and why a GPU and a board

| Task (Paper A) | Status |
|---|---|
| A3 activity-based power | done |
| A4 Spiker+ on the same chip (same-device external baseline) | next |
| A5 three training seeds per N-MNIST point (error bars) | to do |
| A8 paper draft | to do |
| A6 raise gated N-MNIST accuracy | to do |
| A7 board power measurement | blocked: needs a Nexys A7-100T + power meter |

- **GPU:** closes the accuracy gap (wider nets, seeds, DVS-Gesture with a convolutional SNN — the benchmark tier-1
  reviewers expect). CPU training here is ~1 minute per epoch for one small layer.
- **Board:** replaces the Vivado estimate with measured power; static power cancels in a BASE-vs-HUSH difference.

---

## 10. The hardest questions you will get (short answers)

1. **"Isn't this SnaPEA for SNNs?"** SnaPEA terminates ReLU dot products early using sign-sorted weights; HUSH
   bounds *stateful* neurons across time using the carried exact max potential, at BRAM-word granularity, with a proof
   and a hardware datapath that skips the weight fetch itself.
2. **"SITRA already skips silent outputs."** SITRA's predictor is state-free and heuristic: at equal savings it
   suppresses 15,121 spikes and drops to 66 %; HUSH suppresses none (Theorem 1, formally proven on RTL).
3. **"Your gated network is not the one you trained."** It is: training runs the exact gate in the forward pass.
   Accuracy is reported for the gated network.
4. **"The envelope unit runs every step — how can energy fall?"** It reads one P (and Q) row per input event instead
   of 32 sub-block weight columns, and it runs overlapped, so latency and weight reads both fall (measured: −47/−65 %).
5. **"2.6× the LUTs of BASE."** Area is paid once; latency and energy savings are paid back on every inference. It is
   still 15.5 % of a 100T.
6. **"Your power is an estimate."** Yes: gate-level, activity-based, 100 % nets matched, but Vivado's model. Board
   measurement is the open item (A7), and why we need the board.
7. **"Why not gate per neuron?"** BRAM words are 64–72 bits wide; one word serves 8 neurons. Per-neuron gating would
   still read the word.
8. **"Does it work on SHD / recurrent nets?"** Only where headroom exists (§4). We say exactly where it pays and why.
9. **"Accuracy is below your own ungated net."** 2.3 points (gentle). Closing it is the GPU's job: wider nets, seeds.
10. **"Why not compare against more designs on your chip?"** Spiker+ on the XC7A100T is task A4.

---

## 11. Glossary

| Term | Meaning |
|---|---|
| LIF | leaky integrate-and-fire neuron |
| θ | firing threshold (64) |
| k | leak shift; L(x) = x − (x >> k) |
| SOP | synaptic operation: one weight added into one neuron |
| Sub-block | 8 neurons sharing one 64-bit weight column |
| P, Q | per-input max and mean weight over a sub-block |
| Envelope E_c | provable upper bound on any potential in sub-block c this step |
| ETU | envelope unit, computes next step's D one step ahead |
| BASE / HUSH-drop / HUSH-MF | same hardware with gate off / gate on, asleep neurons leak only / gate on, asleep get mean drive |
| Gentle / aggressive | two co-training strengths (more sleep, less accuracy) |
| BRAM (RAMB36) | 36-kbit block RAM on the FPGA (135 on the XC7A100T) |
| LUT, FF, DSP | logic, flip-flop and multiplier resources of the FPGA |
| WNS | worst negative slack: ≥ 0 means timing is met at the target clock |
| Vectorless power | Vivado power with assumed switching rates |
| SAIF | switching-activity file from simulation; makes power activity-based |
| Static / dynamic power | leakage (always on) / switching (depends on activity) |
| Bit-exact | hardware and golden model produce identical integers |
| Headroom | how far the most excited neuron of a sub-block sits below θ |
