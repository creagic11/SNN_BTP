# HUSH from scratch — a primer

*Anubhav Jha (23EE10091), B.Tech thesis, IIT Kharagpur, supervisor Prof. Rajat Subhra Chakraborty.
State as of 11 Nov 2026 (Paper A draft after three review rounds).*

How to use this: read §0 first (5 minutes). Then go section by section; each ends with **Check yourself**
questions. After each section, tick the matching items in `notes/study_checklist.md`. §12 maps every paper section, figure and
table to the repo file that produced it.

Numbers here are the current ones (whole network on chip, 10–11 Nov). Older numbers in the repo history are
superseded and must not be quoted; §8 lists them and says why.

---

## 0. The whole project in one page

**Problem.** A spiking neural network (SNN) layer on an FPGA spends most of its time and energy fetching weights
from block RAM: for every input spike it reads the weights of every neuron. Most of those neurons will not fire
this timestep, so most of that work is wasted. But you cannot know which ones will not fire without doing the
work, unless you can *prove* it cheaply.

**Idea (HUSH).** Group neurons into sub-blocks of 8. Before a timestep's weights are fetched, compute a cheap
integer *upper bound* (the envelope) on how high any neuron in the sub-block can go this step. If the bound is
below the firing threshold, the sub-block sleeps and its weight reads are skipped. Because it is an upper bound, a
sleeping sub-block cannot contain a neuron that would have fired at that timestep.

**What we built.** An integer SNN (578-256-10, N-MNIST) trained with the gate in the loop; a bit-exact golden
model; SystemVerilog RTL of the whole network (hidden layer, output layer, class decision, and a front-end that
takes raw camera events); a formal proof of the gate arithmetic at the real bit widths; placed-and-routed designs
on a Xilinx Artix-7 XC7A100T at 100 MHz; gate-level power estimates; and a paper draft.

**Results (whole network on chip, N-MNIST, 100 MHz).**

| Design | Accuracy (3 seeds) | Latency | Speedup | Active energy | LUT / BRAM |
|---|---|---|---|---|---|
| BASE (same hardware, gate off, trained equally long) | 98.21 ± 0.13 % | 279.5 µs | 1.00× | 42.5 µJ | 7,745 / 80 |
| HUSH gentler | 96.54 ± 0.07 % | 159.8 µs | 1.75× | 23.7 µJ (−44 %) | 13,885 / 95 |
| HUSH gentle | 95.74 ± 0.07 % | 114.9 µs | 2.44× | 18.4 µJ (−57 %) | 13,885 / 95 |
| HUSH aggressive (6 epochs only) | 92.32 ± 0.68 % | 82.9 µs | 3.39× | 14.4 µJ (−66 %) | 13,885 / 95 |
| Spiker+ (open generator, same chip, BASE's 10-epoch weights) | 97.53 % | 818.4 µs | 0.34× | 254.5 µJ | 13,548 / 70.5 |

**Real time.** Replaying N-MNIST recordings at their recorded timing in RTL simulation, every 3 ms window is
processed within 4.5 µs of its end (HUSH) or 6.6 µs (BASE). Replayed faster than real time with the same input
buffer, BASE drops events above 750×, HUSH gentle above 1,000×.

**The price.** 1.7–5.9 points of accuracy, 79 % more LUTs and 19 % more block RAM than BASE.

**What is proved and what is not.** Proved: at every timestep, the gated layer emits exactly the spikes that the
ungated update *from its own current state* would emit. Not guaranteed: that the gated network follows the same
trajectory as an ungated network over a whole recording. It does not (§3.4), which is why the gate is trained
into the network and accuracy is the end-to-end measure.

**Weak points.** Accuracy cost; area cost; power is a Vivado estimate from simulated activity, not a board
measurement; one dataset and one small fully connected network; real time is shown by RTL replay, not a live
sensor; HUSH only pays on networks with "headroom" (§4.3).

**Where it is going.** Paper A (`paper/hush_paperA.tex`, 7 pages with references; venue not yet chosen). Paper B
(convolutional layers, DVS-Gesture) needs a GPU. Board power measurement needs the board and a power meter.

---

## 1. Spiking neurons, the minimum you need

**LIF neuron (leaky integrate-and-fire), integer version, one timestep t:**

```
U_i  = sat( L(V_i) + Σ_{j active} W_ji )     # leak the old potential, add weights of inputs that spiked
s_i  = [U_i ≥ θ]                              # spike if at or over the threshold θ (= 64)
V_i' = U_i − θ·s_i                            # soft reset: subtract θ, keep the residue
```

- Only active inputs cost work (event-driven).
- **Leak** `L(x) = x − (x >> k)`: multiply by (1 − 2⁻ᵏ) with one shift and one subtract, no multiplier. k = 4, so
  the potential keeps 15/16 per step. Larger k = slower leak = longer memory.
- **Integers everywhere:** INT8 weights, 16-bit potentials, one saturation ("sat", clip to the 16-bit range) after
  an exact sum. The golden model and the hardware compute exactly the same integers, so every result can be
  checked bit for bit. (The PyTorch training model omits the 16-bit clip; the trained weights are then evaluated
  in the exported integer model, which has it.)
- **N-MNIST:** MNIST digits recorded by a moving event camera. 34 × 34 pixels × 2 polarities, pooled 2 × 2 to
  17 × 17 × 2 = **578 inputs**; 300 ms cut into **T = 100 windows of 3 ms**. A window holds on average 41.9 raw
  events, 26.5 distinct pooled inputs (maximum 96).
- **Network:** 578 inputs → 256 hidden LIF neurons → 10 output neurons. The class is decided in integers: most
  output spikes, ties broken by the larger summed potential, then by the lower index.
- **Training:** surrogate gradients (backpropagation through time with a smooth stand-in for the spike step).
  Table "Training setup" in the paper lists every setting.

**Check yourself.** Why does soft reset keep information that hard reset loses? Why does k = 4 mean "slow" leak?
Why must the evaluated model and the hardware share one integer kernel?

---

## 2. Where the work goes, and why skipping is hard

Per timestep, a dense (BASE) layer reads, for each active input j, the 256 weights of row j and does 256 adds.
One such add is a **synaptic operation (SOP)**.

Three kinds of sparsity:
1. **Static weight sparsity** (pruning): fixed zeros.
2. **Input-spike sparsity**: only active inputs cost work. Every event-driven design already uses this.
3. **Output-state sparsity**: neurons that will not fire this step. *This is HUSH's axis.*

Why output-side skipping is hard: you only know a neuron will not fire *after* adding up its inputs. Guessing
(a heuristic) can suppress real spikes. And skipping single neurons does not help on an FPGA: weights come out of
block RAM in wide words that cover several neurons, and a word must be read if *any* neuron in it is needed. So
skipping must be per **group of neurons**, and a group may sleep only if *all* its neurons are safe.

**Prior work you must know** (paper §II):

| Work | What it skips | How it decides | Can it be wrong? |
|---|---|---|---|
| Early (ICCD 2024) | rest of a neuron's accumulation | partial sum of the largest weights vs a tuned threshold | yes, 0.54 % mean accuracy loss |
| SITRA (ISLPED 2025) | weight fetches of outputs predicted silent (spiking transformer) | weight-MSB dot product, no membrane state | yes, 1–2 % loss |
| PS4 (ICCD 2024) | speculates firing over a time window | popcount speculation | recomputes when wrong (costs time) |
| SnaPEA (ISCA 2018) | rest of a ReLU convolution | exact mode: sign-sorted weights, stop when the partial sum turns negative | no (exact mode), but it is for CNNs, per neuron, no state over time, and reads weights up to the stop point |
| SPARSH (ICCAD 2025) | zero weights, zero spikes, refractory neurons | — | input side |
| C-STEP (DATE 2026), Cheng et al. (TCAS-I 2025) | the rest of the inference | early exit in time | different axis |

All three SNN output-side schemes (Early, SITRA, PS4) were evaluated with simulators and ASIC synthesis, not on
an FPGA. HUSH's difference: the decision is a proven bound, taken *before any weight of the sub-block is read*,
it carries membrane state across timesteps, and its granularity (8 neurons) equals one 64-bit block-RAM word.

**Check yourself.** What is an SOP? Why is per-neuron skipping useless with block RAM? How does HUSH differ from
SnaPEA's exact mode in one sentence?

---

## 3. The HUSH gate and why it is safe

### 3.1 Grouping and tables

256 neurons = 8 **blocks** of 32 = 32 **sub-blocks** of 8. Each sub-block has its own 64-bit weight-column RAM
word per input (8 INT8 weights), enabled only if the sub-block is awake. Sub-block size 8 was chosen because
eight INT8 weights fill one 64-bit RAM word; other sizes were not explored.

Two tables are computed once, offline, from the weights:
- **Proxy** `P[j][c] = max over neurons i in sub-block c of W_ji`.
- **Mean** `Q[j][c] = floor(mean of W_ji over c)`. Note Q ≤ P.

### 3.2 The bound, per sub-block c and timestep

- `R_c` = the exact maximum potential of the sub-block after the last step (the hardware keeps it).
- `D_c = Σ_{active j} P[j][c]`: the largest drive any member could receive. One byte per active input instead of
  eight weight bytes.
- **Envelope** `E_c = sat( L(R_c) + max(0, D_c) )`.
- **Gate** `g_c = [E_c ≥ θ]`: awake if 1, asleep if 0.

### 3.3 Theorem 1 (safety)

*If g_c = 0, every neuron i in c has U_i < θ in the ungated update from the same state.*

Proof in four lines: (1) L is non-decreasing, so L(V_i) ≤ L(R_c). (2) W_ji ≤ P_jc, so the neuron's drive
≤ D_c ≤ max(0, D_c). (3) sat is non-decreasing. (4) Hence U_i ≤ E_c < θ.

**Sleeping neurons still get a drive (mean-field).** A sleeping sub-block skips its weight reads. All 8 neurons
receive the same cheap drive `q_c = Σ_{active j} Q[j][c]`, so `U_i = sat(L(V_i) + q_c)`. Because Q ≤ P, this is
also ≤ E_c < θ: they cannot spike, and R_c stays exact. (An earlier variant, "drop", gave sleeping neurons no
drive; it loses much more accuracy and is not in the paper.)

### 3.4 What is guaranteed and what is not (paper Fig. 1)

- **(A) Per-timestep safety — proved.** Starting from HUSH's *own* state at t−1, the gated update emits exactly
  the spikes of the ungated update. Awake sub-blocks are computed exactly; sleeping ones contain no neuron that
  would reach θ.
- **(B) Trajectory equivalence — not guaranteed.** A sleeping neuron received q_c instead of its own drive, so
  its state differs from an ungated run, and later spikes can differ.

Measured on 1,000 test samples per point (`scripts/drift.py` → `results/drift.json`):

| Point | Spikes violating (A) | Hidden spikes per sample: gated / same weights ungated | Class agrees | Accuracy: gated / ungated, same weights |
|---|---|---|---|---|
| gentler | 0 | 390 / 658 | 96.1 % | 95.3 / 95.9 % |
| gentle | 0 | 304 / 553 | 94.6 % | 94.8 / 93.5 % |
| aggressive | 0 | 201 / 388 | 89.9 % | 91.2 / 88.1 % |

The trajectories first differ in window 4 (median). So the gated network is **not** an approximation of an
ungated one: it is a network in its own right, trained with the gate, and removing the gate from the gentle or
aggressive weights makes accuracy *worse*. Never say "zero accuracy loss" or "identical output"; say "no spike
is suppressed relative to the ungated update from the same state".

### 3.5 Formal verification (paper §V, `formal/README.md`)

Two complementary SymbiYosys checks (engine ABC PDR) on the RTL modules the design actually instantiates
(`hush_envelope`, `hush_lane` in `rtl/hush_arith.sv`):

1. **Full width** (`formal/fv_width.sv`; 16-bit V, 18-bit accumulators, k = 4, θ = 64; tasks m578 and m256;
   PASS in 72 s). One timestep of one 8-lane sub-block, every value free. Assumptions: every V_i ≤ R_c (the
   induction hypothesis); every neuron's drive ≤ D_c and q_c ≤ D_c; drives within the range a sum of ≤ M INT8
   values can take. Assertions: gate = 0 ⇒ ungated U < θ; U ≤ E for every lane, awake or asleep; spike ⇒ gate;
   **no wrap-around** (each 18-bit sum equals the same sum computed 8 bits wider); the new maximum bounds the new
   potentials. With V = R = 0 at reset this is the inductive step of Theorem 1 at the real widths.
2. **Reduced width, sequential** (`formal/fv_hush.sv`; 8-bit V, 4 lanes): the same properties over unbounded
   time, for both sleep semantics.

Mutants with an unsafe proxy (drive allowed above D_c) fail immediately, so the checks are not vacuous.

**Scope, exactly.** The proof covers the envelope and lane *arithmetic* under the assumption drive ≤ D_c. That
assumption holds by construction of the P and Q tables (generated offline, checked by simulation). The RTL's max
tree that computes R_c, the second finalise stage, the memories and the sequencing are **not** in the formal
harness; they are covered by the bit-exact simulations (§6). The m256 task only adds the no-wrap check at the
output layer's widths (the output layer is not gated).

**Why 18-bit accumulators?** |L(V)| ≤ 30,720 and a sum of up to 578 INT8 weights lies in [−73,984, 73,406], so a
lane sum lies in [−104,704, 104,126], inside ±131,072 (18 bits signed). The clip to 16 bits happens once.

**Check yourself.** Prove U_i ≤ E_c in four lines. Why max(0, D_c)? Why does Q ≤ P keep mean-field safe? State
(A) and (B) precisely and quote one number for each. What does the formal proof assume, and what covers the rest?

---

## 4. Training with the gate in the loop, and when HUSH pays

### 4.1 Co-training

The forward pass uses the hard gate exactly as the hardware does; gradients flow through whichever update
(exact or mean-field) the gate selected. Two penalties are added to the cross-entropy:
- **Exceedance**: λ_e · mean over (c, t) of max(0, E_c − θ)/θ. Pushes envelopes below the threshold.
- **Proxy drive**: λ_d · mean_c Σ_j r_j · max(0, P_jc)/θ, with r_j the firing rate of input j. Shrinks the
  largest weight of each sub-block.

| Point | (λ_e, λ_d) | Fine-tune epochs from the 10-epoch ungated net |
|---|---|---|
| gentler | (0.25, 0.1) | 12 |
| gentle | (0.5, 0.25) | 12 |
| aggressive | (2, 1) | **6** (not re-run at 12) |

Other settings: Adam, one-cycle schedule, batch 128, lr 0.02 for fine-tuning, fast-sigmoid surrogate with
s = θ/4, INT8 weights with a straight-through estimator, firing-rate regulariser 5·max(0, r̄ − 0.05), seeds
0, 1, 2. The final epoch is kept (no model selection on the test set).

### 4.2 The fair baseline

The gated nets get 12 extra epochs. Giving the ungated net the same 12 extra epochs (no gate) raises it from
97.66 % to **98.21 %**. That 22-epoch network is the paper's BASE, so the accuracy cost of the gate is quoted
against a baseline trained equally long (1.7 / 2.5 / 5.9 points). Using the 10-epoch net would flatter HUSH.

Training longer with the gate also helps HUSH: the gentle point went from 95.37 %, 1.98× (6 epochs) to 95.74 %,
2.44× (12 epochs).

### 4.3 When does HUSH pay? Headroom

A sub-block sleeps when the gap between θ and its most excited neuron (the headroom) exceeds the step's
worst-case drive. A neuron under steady inhibition b settles about 2ᵏ·|b| below rest, so
**headroom ≈ θ + 2ᵏ·|b|: a slow leak turns inhibition into headroom** (`docs/headroom_model.md`).

| Network (SHD study, 26 Oct) | Headroom | Weight reads after co-training |
|---|---|---|
| feed-forward LIF, k = 5 | 9.7 θ | 0.64 |
| recurrent adaptive LIF | 0.09 θ | 0.98 (useless) |
| feed-forward + axonal delays, fast leak | 0.4–1.2 θ | 0.77–0.97 |

So HUSH suits sparse event-vision tasks with slow leaks; it does not suit recurrent adaptive or fast-leak delay
networks. This limit is measured and explainable. Within N-MNIST the same effect shows per window: the speedup
falls from 2.2× in quiet windows to 1.59× in busy ones (§7.4).

**Check yourself.** What does each penalty push? Why is 98.21 %, not 97.66 %, the honest baseline? Why does a
larger k give more headroom? Which point was trained for only 6 epochs?

---

## 5. The hardware

### 5.1 Hidden layer (`rtl/hush_layer.sv`, paper Fig. 2 and Fig. 3)

Per timestep:
1. **Combine** (1 cycle): the gates g_c for all 32 sub-blocks from R_c and the envelope bank (D_c, q_c).
2. **Block loop** over the 8 blocks of 32 neurons:
   - a block with any awake sub-block streams the timestep's n events through a 4-stage pipeline (event read,
     index register, weight read, accumulate in 32 lanes of 18 bits) and finalises in 2 stages (sat, spike, soft
     reset; sleeping sub-blocks inside it take L(V) + q_c). Cost **4 + (n + 4)** cycles. Only the weight columns
     of awake sub-blocks are read.
   - a block with all four sub-blocks asleep takes **3** cycles (state read, mean-field finalise, write-back).
3. 2 closing cycles. Total: `1 + Σ_blocks c + 2`.

The **envelope unit (ETU)** computes D_c and q_c for timestep t+1 while the block loop works on t (two banks,
swapped each step), so the gate costs almost no extra time.

Consequence: **time** is saved per 32-neuron block (all four sub-blocks asleep); **energy** is also saved per
8-neuron sub-block (its weight column is not read).

### 5.2 Whole network (`rtl/hush_net.sv`)

Hidden spikes enter a 32-entry FIFO; a drain turns each set bit into an event for the output layer (the same
layer module, gate off, 32 lanes, 10 used). The output layer runs **one timestep behind** the hidden layer and
overlapped with it, so it adds almost no latency. The classifier is the integer argmax (§1).

### 5.3 Stream front-end (same file, STREAM = 1)

Raw camera events (x, y, p) are pooled 2 × 2 into the 578 inputs, de-duplicated per window (the model's input is
a 0/1 raster), and written into a ring of 1,024 events (one RAMB18). An end-of-window marker closes the window,
records its range and lets the hidden layer start. Markers have reserved space in the 128-entry input FIFO
(events may use 64), so overload can drop events but never a marker; a lost marker would hang the inference.
In stream mode the envelope for window t is computed when the window closes (it needs that window's events).

### 5.4 Resources (`results/resources.md`, paper Table V)

| Build | Hidden layer LUT / BRAM | Output LUT / BRAM | Glue LUT | Total LUT | Total BRAM | WNS |
|---|---|---|---|---|---|---|
| BASE, power build | 3,874 / 74 | 3,117 / 6 | 754 | 7,745 | 80 | +0.956 ns |
| HUSH, power build | 9,922 / 89 | 3,150 / 6 | 813 | 13,885 | 95 | +0.450 ns |
| BASE, stream build | 4,482 / 41.5 | 3,142 / 7 | 1,112 | 8,736 | 48.5 | +0.252 ns |
| HUSH, stream build | 10,365 / 56.5 | 3,122 / 6 | 1,119 | 14,606 | 62.5 | +0.256 ns |

- A **power build** stores 20 test recordings on chip (53k events, ≈ 32.5 BRAM tiles) so power can be simulated
  over 20 inferences without a host. A **stream build** has the sensor front-end and the 1,024-event ring
  instead. That is the whole BRAM difference; weights and tables are identical.
- HUSH adds the same ≈ 6k LUTs and 14–15 BRAM tiles in both (envelope unit, P and Q tables, sub-block control):
  **+79 % LUT, +19 % BRAM**.
- Device: XC7A100T-1CSG324C (the chip on a Nexys A7-100T), Vivado 2024.1, default directives, 100 MHz met by all.

**Check yourself.** Why can the envelope unit run one step ahead in batch mode but not in stream mode? Why is an
asleep block 3 cycles, not 0? Why does a power build need 32 more BRAM tiles than a stream build? Where do
HUSH's extra 6k LUTs go?

---

## 6. How everything was checked and measured

1. **Golden model** (`golden/hush.py`, Python integers) defines the behaviour; property tests with Hypothesis
   (`pytest -q tests/`) check the safety invariants, and mutation tests show the tests catch unsafe variants.
2. **RTL = golden, bit for bit** (Icarus Verilog): 80 randomised layer configurations (`rtl/sim/regress.py`);
   the whole network on 50 N-MNIST samples for each of four weight sets, every block result and class, with
   cycle counts equal to an exact cycle model (`rtl/sim/run_net.py`, `rtl/sim/net_cycle_model.py`); 40 random
   whole networks including a 4-entry spike FIFO that forces back-pressure; stream mode in every run without
   dropped events (`rtl/sim/run_stream.py`).
3. **Formal proof** of the gate arithmetic (§3.5).
4. **Place and route** in Vivado: area and timing from the routed designs.
5. **Power from gate-level activity.** The routed netlist is simulated over 20 back-to-back test inferences
   (functional netlist, xsim); the switching activity of every net (SAIF; 99.9–100 % of nets matched, confidence
   High) is read back into `report_power`. **Energy per inference = power × latency** while the chip is
   processing: this is *active* energy. Limits: zero-delay activity (no glitch power), Vivado's model, not a
   board measurement.
6. **Gate-level simulation = cycle model** for every inference (+3 cycles of restart).

Implementation runs (Vivado 2024.1 on a Windows build machine): **L1** (10 Nov; four whole-network power builds, two stream builds,
Spiker+) and **L2** (11 Nov; 22-epoch BASE power, Spiker+ high-effort build, stream builds after the marker fix).
Results are in `results/power_l1/` and `results/power_l2/` with a README each.

Three review rounds were applied to the paper (10–11 Nov): an internal fresh-eyes review (20 items), an external
review (scope of the safety claim, full-width proof, resource accounting, charged heuristic comparison, energy
wording), a second fresh-eyes review (epoch counts, drift metric, proof scope, energy at a common speed), and a
final strict pass (area cost up front, energy attribution, SnaPEA, more figures). See `notes/development_log.md`.

**Check yourself.** Why is gate-level simulation better than RTL simulation for power? What does "active
energy" include? What would a board measurement add? Which parts of the design are proved and which simulated?

---

## 7. Results

### 7.1 Accuracy against savings (paper Table III, Fig. 4; `results/net_latency.md`)

| Design | Accuracy % (3 seeds) | Column reads | Weight-memory traffic | Latency µs (500 samples) | Speedup |
|---|---|---|---|---|---|
| BASE (22 epochs) | 98.21 ± 0.13 | 1.000 | 1.00 | 279.5 | 1.00× |
| HUSH gentler | 96.54 ± 0.07 | 0.204 | 0.45 | 159.8 ± 8.1 | 1.75× |
| HUSH gentle | 95.74 ± 0.07 | 0.118 | ≈ 0.37 | 114.9 ± 7.0 | 2.44× |
| HUSH aggressive (6 ep) | 92.32 ± 0.68 | 0.070 | 0.32 | 82.9 ± 7.8 | 3.39× |

- **Column reads** count only the 8-byte weight columns. **Traffic** also charges HUSH its own reads of P and Q
  (2 bytes per sub-block and active input): total = column reads + 0.25. Always quote traffic when asked what
  HUSH really saves in memory: 0.32–0.45 of BASE.
- Speedup is the mean of per-seed ratios against the ungated net of the same seed.
- Accuracy uses the hardware's integer decision rule on the full 10,000-sample test set
  (`results/acc_integer.json`).

### 7.2 Hardware on one chip (paper Table IV, Fig. 5; `results/power_l1/README.md`)

| Design | LUT | BRAM | WNS ns | Latency µs (20 samples) | Power mW | Energy µJ | of which dynamic µJ |
|---|---|---|---|---|---|---|---|
| BASE | 7,745 | 80 | +0.956 | 279.5 | 152 | 42.5 | 14.3 |
| HUSH gentler | 13,885 | 95 | +0.450 | 151.2 | 157 | 23.7 | 8.5 |
| HUSH gentle | 13,885 | 95 | +0.450 | 115.3 | 160 | 18.4 | 6.7 |
| HUSH aggressive | 13,885 | 95 | +0.450 | 87.7 | 164 | 14.4 | 5.4 |
| Spiker+ | 13,548 | 70.5 | +0.005 (high effort) | 818.4 | 311 | 254.5 | 171.9 |

How to read it:
- HUSH draws 3–8 % **more power** but spends 44–66 % **less energy**, because it finishes sooner.
- Static power is 101–102 mW for every design (it is the chip's). **Two thirds of BASE's active energy is static
  power × latency**, so most of the saving comes from finishing sooner; dynamic energy alone falls 41–62 %.
- **Area × time** (LUT × latency) improves less than latency: 3 % (gentler), 26 % (gentle), 44 % (aggressive).
- Latency here is over the 20 simulated inferences; the speedups in §7.1 use the 500-sample means.

### 7.3 Spiker+ on the same chip

Spiker+ (Carpegna et al., an open VHDL generator) is clock-driven and ungated. It runs **BASE's 10-epoch INT8
weights** (97.53 % with its own neuron arithmetic), scans all 578 inputs serially each timestep, and needs 81.8k
cycles per inference. With default settings it misses 100 MHz by 0.24 ns; with high-effort directives it meets
it (+0.005 ns). Its power was measured on the default-effort netlist (the high-effort one is estimated 4 % higher,
so 254.5 µJ is a lower bound). It draws 311 mW, 140 mW of it in block RAM, which it reads every cycle (ours:
12 mW). Energy: 6.0× BASE, 13.8× HUSH gentle.

### 7.4 Speedup depends on input activity (paper Fig. 6; `results/realtime/stream_stats.md`, A9.1b)

| Active inputs in the 3 ms window | Share of windows | BASE cycles | HUSH gentle cycles | Speedup |
|---|---|---|---|---|
| 1–9 | 21 % | 118 | 53 | 2.22× |
| 10–19 | 19 % | 195 | 92 | 2.12× |
| 20–29 | 17 % | 280 | 143 | 1.96× |
| 30–39 | 17 % | 362 | 187 | 1.94× |
| 40–59 | 22 % | 469 | 260 | 1.81× |
| ≥ 60 | 3 % | 610 | 384 | 1.59× |

More active inputs wake more sub-blocks. On a dense stream the speedup tends to 1×.

### 7.5 Heuristic gates, exploratory (paper Table VI; `results/heuristic_gates.md`)

Keep the HUSH-trained gentle network (seed 0, 1,000 samples) and swap only the predictor. Each predictor is
charged its own memory reads.

| Matched on | Predictor | Accuracy | Suppressed spikes | Traffic |
|---|---|---|---|---|
| — | HUSH | 94.8 % | 0 | 0.355 |
| traffic | Early-style | 93.6 % | 409 | 0.359 |
| traffic | SITRA-inspired | 87.4 % | 74,095 | 0.404 |
| reads | Early-style | 92.4 % | 485 | 0.350 |
| reads | SITRA-inspired | 68.1 % | 117,450 | 0.227 |

Caveats you must state: the networks were trained for HUSH, not for the heuristics; one seed; the Early-style
charge is a lower bound; the state-free predictor is "inspired by" SITRA (it counts negative weights, it is not
SITRA's MSB dot product) and cannot be matched exactly (it moves 14 % more bytes than HUSH at the nearest step).
This shows what the proof buys; it is not a claim that HUSH beats those papers' own systems.

### 7.6 Real-time operation (paper §VII; `results/realtime/realtime.md`)

- **At true sensor timing** (RTL replay of 4 recordings per design, bit-exact, no drops): a window is processed
  in 1.47 µs on average with HUSH gentle (3.04 µs BASE, −52 %), at most 4.50 µs (6.64 µs), i.e. ≤ 0.22 % of the
  3 ms window. Both designs are real-time by a wide margin; real time is **not** what distinguishes HUSH.
- **Energy at sensor speed.** The chip idles > 99.9 % of the time. A 300 ms recording costs ≈ 30.3 mJ of static
  energy for either design; HUSH saves only its dynamic share (6.7 vs 14.3 µJ), under 0.03 % of the total. Say
  this plainly: the 44–66 % is *active* energy.
- **Where the gain appears: a busy chip.** At 750× real time (the fastest speed at which BASE drops nothing on
  the 20 heaviest recordings), a recording occupies 0.40 ms: BASE 101 mW × 0.40 ms + 14.3 µJ = **54.7 µJ**,
  HUSH 102 mW × 0.40 ms + 6.7 µJ = **47.5 µJ** (−13 %). HUSH can also run at 1,000× (37.3 µJ).
- **Faster than real time** (same 1,024-event buffer, speeds in steps of 250×; paper Fig. 7): BASE passes all 20
  recordings up to 750×; HUSH gentle up to 1,000× (23.7 M events/s, 1.33×) and 1,500× for the median recording
  (2.0×); HUSH gentler 750× on all 20 and 1,000× on 18.
- **Early decisions** (paper Fig. 8; 10,000 samples, seed 0). The class can be read after any window. Between
  21 and 156 ms the gentler network is *more* accurate than BASE (87.7 vs 79.5 % at 60 ms; 92.6 vs 88.9 % at
  99 ms); gentle leads from 21 to 144 ms; BASE leads from 159 ms on. The gated nets do not spike earlier or more
  (39–41 vs 52 output spikes in the first 99 ms); their early leading class is simply wrong less often
  (8.5–8.8 % vs 10.6 %).

### 7.7 Against published designs (paper Table VII; `docs/literature/nmnist_dvs_fpga.md`)

| Design | FPGA | Accuracy | LUT | Power | Latency |
|---|---|---|---|---|---|
| Cheng et al., TCAS-I 2025 | ZCU104 | 98.11 % | 81.3k | 0.81 W dynamic | not available to us |
| FeNN-DMA, 2025 | KV260 | 98.46 % | 55.0k | 0.53 W dynamic | not reported |
| Surrogates, 2026 | xcvu9p | 96.4 % | not reported | 0.31 W | 5.9 ms |
| Wu, Song & So, ICFPT 2023 | ZCU102 | 95.76 % | 39.7–165k | 0.33–0.37 W | 50 ms |
| HUSH gentler | XC7A100T | 96.54 % | 14.6k (stream build) | 0.16 W total | 0.16 ms |
| HUSH gentle | XC7A100T | 95.74 % | 14.6k | 0.16 W total | 0.11 ms |

HUSH is 37–435× faster than the two designs that report latency and needs 77–950× less active energy per
inference (their energy computed by us as power × latency), with 3.8–5.6× fewer LUTs than Cheng et al. and
FeNN-DMA and 2.7–11.3× fewer than Wu et al.'s range. **These rows are not like for like**: different networks
(convolutional, recurrent, ours 578-256-10), all others on UltraScale+ parts with 1.8–19× the LUT capacity,
different latency definitions and power methods. Only the same-chip comparison (§7.1–7.3) isolates HUSH's effect.
Say this before a reviewer does.

**Check yourself.** Why does HUSH use more power but less energy? What fraction of the energy saving is "finish
sooner"? Why is the area × time gain only 3 % for gentler? What are column reads vs traffic? Why is the
real-time energy saving 13 % and not 57 %? Give the three caveats of the heuristic table.

---

## 8. Numbers that were thrown away, and why

Knowing this history is a strength in a viva: the numbers were attacked before anyone else did.

1. **v1 builds (before 28 Oct).** The test top level observed only 12 of 32 output lanes, so Vivado deleted most
   of BASE (1.3k LUT); weight tables were ROMs and were trimmed to 6 bits; sub-block gating existed only in a
   counter; power was vectorless. All fixed in v5.
2. **v5 hidden-layer numbers (28 Oct): BASE 97.59 %, 302.9 µs, 43.9 µJ, 3.8k LUT; HUSH gentle 95.32 %, 153.0 µs,
   23.1 µJ, 9.8k LUT.** Superseded on 10 Nov by the whole network on chip (output layer overlapped, class on
   chip), 12-epoch gated nets and the fair 22-epoch baseline. Do not quote them.
3. **"Zero accuracy loss / identical spikes" wording.** Replaced by the scoped claim (A) vs (B) of §3.4.
4. **"12 epochs" for the aggressive point.** It is 6.
5. **"−37 %" average window and "840 vs 828 cycles" worst window.** Those came from 6-epoch weights; replaced by
   −52 % (1.47 vs 3.04 µs) and the activity table of §7.4.
6. **Real-time energy "61 vs 48 µJ"** compared the designs at different speeds; replaced by the common-speed
   figures of §7.6.
7. **Float-keyed accuracy** from the trainer (differs from the hardware rule in rare ties); all accuracies now
   use the integer rule.

---

## 9. What is left

| Item | Status |
|---|---|
| Venue for Paper A (TCAS-II brief needs cuts; FCCM-style 8 pages fits) | open, your decision |
| Departments in the author block | not given yet |
| Aggressive point re-trained at 12 epochs (+ its power on the build machine) | optional |
| A7: board power measurement | blocked: needs a Nexys A7-100T and a power meter |
| Paper B: convolutional layers, DVS-Gesture | needs a GPU |

---

## 10. The hardest questions you will get (short answers)

1. **"Is the network's output provably unchanged?"** No. Per timestep, from the same state, no spike is
   suppressed (proved). Over a recording the trajectories differ (measured, §3.4). Accuracy is the end-to-end
   measure, and the gate is trained in.
2. **"Isn't this SnaPEA for SNNs?"** SnaPEA's exact mode stops a ReLU dot product once its partial sum is
   negative; it reads weights up to that point, per neuron, with no state. HUSH decides before reading any weight
   of the sub-block, carries the exact maximum potential across time, and gates whole block-RAM words.
3. **"SITRA already skips silent outputs."** Its predictor is a heuristic without membrane state. In our
   exploratory swap, a state-free predictor suppresses tens of thousands of spikes; HUSH suppresses none.
4. **"Your proof is at toy widths."** No: the inductive step is proved at the real widths (16/18 bits) for both
   layers, including no wrap-around; a reduced-width sequential proof complements it. The assumption (drive ≤ D_c)
   holds by construction of P.
5. **"What does the proof not cover?"** The max tree for R_c, the second finalise stage, memories and sequencing:
   those are covered by bit-exact simulation against the golden model.
6. **"79 % more LUTs."** Yes. Area × time improves 26 % (gentle) and 44 % (aggressive), only 3 % for gentler. The
   design still uses 22 % of the XC7A100T's 63,400 LUTs.
7. **"More power, so how less energy?"** Energy = power × time. Power is +3–8 %, time is −46 to −69 % (the 20 measured inferences).
8. **"Most of your energy saving is static power."** Correct: two thirds of BASE's active energy is static. HUSH
   also cuts dynamic energy 41–62 %. At sensor speed the saving is negligible; on a busy chip it is 13 % at equal
   speed.
9. **"Your power is an estimate."** Yes: routed netlist, gate-level activity, ≥ 99.9 % of nets matched, Vivado's
   model, no glitch power. Board measurement is open (A7).
10. **"Is BASE a fair baseline?"** Same RTL with the gate off, trained equally long (98.21 %). Plus Spiker+ on the
    same chip as an external one.
11. **"Why is the aggressive point only 6 epochs?"** It was not re-run; it is labelled. The headline points are
    gentler and gentle.
12. **"Real time on what sensor?"** RTL replay of recorded N-MNIST streams at their recorded timing (4
    recordings), not a live sensor. N-MNIST is a light stream (≈ 14k events/s).
13. **"Why not gate per neuron?"** One 64-bit RAM word serves 8 neurons; per-neuron gating would still read it.
14. **"Does it work on other networks?"** Where headroom exists (§4.3). Not on recurrent adaptive or fast-leak
    delay networks; convolutional layers are future work.
15. **"The SOTA ratios are huge. Are they fair?"** No, and the paper says so: different networks, devices and
    methods. The same-chip comparison is the evidence.

---

## 11. Glossary

| Term | Meaning |
|---|---|
| LIF | leaky integrate-and-fire neuron |
| θ | firing threshold (64) |
| k | leak shift; L(x) = x − (x >> k), k = 4 |
| sat | clip to the 16-bit signed range, applied once per update |
| SOP | synaptic operation: one weight added into one neuron |
| Window / timestep | 3 ms of sensor time; 100 per recording |
| Sub-block / block | 8 neurons sharing one 64-bit weight word / 4 sub-blocks processed together (32 lanes) |
| P, Q | per input and sub-block: maximum and floor-mean of the 8 weights |
| R_c, D_c, q_c | exact max potential of sub-block c; proxy drive Σ P; mean-field drive Σ Q |
| Envelope E_c, gate g_c | upper bound sat(L(R_c) + max(0, D_c)); awake if E_c ≥ θ |
| ETU | envelope unit: computes D_c and q_c one timestep ahead |
| BASE | the same RTL with the gate off, 22-epoch ungated network |
| Gentler / gentle / aggressive | three training strengths (more sleep, less accuracy) |
| Column reads / traffic | weight-column reads relative to BASE / all weight-memory bytes including P and Q |
| Power build / stream build | 20 recordings stored on chip for power simulation / sensor front-end with a 1,024-event ring |
| Active energy | power × latency while the chip is processing one inference |
| SAIF | switching-activity file from gate-level simulation, read back into Vivado's power report |
| WNS | worst negative slack; ≥ 0 means the 100 MHz clock is met |
| BRAM tile | 36 Kb of block RAM (RAMB36, or two RAMB18); 135 on the XC7A100T |
| PDR | property-directed reachability: an unbounded model-checking engine |
| (A) / (B) | per-timestep safety (proved) / trajectory equivalence with an ungated run (not guaranteed) |
| Headroom | how far the most excited neuron of a sub-block sits below θ |
| L1, L2 | the two build machine Vivado runs of 10 and 11 Nov |

---

## 12. Map: paper → repo

| Paper item | What it shows | Produced by | Data |
|---|---|---|---|
| §III, Theorem 1 | the gate and its proof | `golden/hush.py`, `tests/test_hush.py` | — |
| Fig. 1, §III "what is guaranteed" | (A) vs (B) and the drift numbers | `python scripts/drift.py --n 1000` | `results/drift.json` |
| Fig. 2, Fig. 3, §IV | datapath and schedule | `rtl/hush_layer.sv`, `rtl/hush_net.sv`, `rtl/sim/net_cycle_model.py` | — |
| §V, Table I | verification and width bounds | `formal/fv_width.sby`, `formal/fv_hush.sby`, `rtl/sim/regress.py`, `rtl/sim/run_net.py`, `rtl/sim/run_stream.py` | `formal/README.md`, `results/net/` |
| Table II | training setup | `train/train_snn.py`, `train/qsnn.py`, `scripts/seed_run.sh` | `results/nmnist_T100*/` |
| Table III, Fig. 4 | accuracy, reads, latency, speedup | `scripts/acc_integer.py`, `scripts/net_perf.py`, `scripts/net_table.py`, `scripts/fig_paper.py` | `results/acc_integer.json`, `results/net_latency.md` |
| Table IV, Fig. 5 | area, timing, power, energy | Vivado: `fpga/run_l1.bat`, `fpga/run_l2.bat` | `results/power_l1/`, `results/power_l2/` |
| Table V | resources of the four builds | routed `util_hier.rpt` | `results/resources.md` |
| Table VI | heuristic predictors | `scripts/heuristic_gates.py --match reads|traffic` | `results/heuristic_gates.md` |
| §VII, Fig. 6 | cycles per window vs activity | `scripts/activity_buckets.py`, `scripts/stream_stats.py` | `results/realtime/stream_stats.md` |
| §VII, Fig. 7 | sensor timing and replay sweep | `rtl/sim/run_stream.py`, `scripts/stream_sweep.py`, `scripts/realtime_summary.py` | `results/realtime/realtime.md`, `stream_sweep.jsonl` |
| Fig. 8 | accuracy vs elapsed sensor time | `scripts/early_decision.py`, `scripts/early_analysis.py`, `scripts/fig_early.py` | `results/realtime/early_decision.json` |
| Table VII | published designs | — | `docs/literature/nmnist_dvs_fpga.md` |
| Spiker+ rows | same-chip external baseline | `spikerplus/`, `spikerplus/fpga/build_spiker_hi.tcl` | `results/power_l1/`, `results/power_l2/` |

Figures 4–7 are regenerated with `python scripts/fig_paper.py`, Fig. 8 with `python scripts/fig_early.py` (both
from the repo root). The paper is built in `paper/` with `pdflatex hush_paperA`, `bibtex hush_paperA`, then
`pdflatex` twice. The dated log of every step is `notes/development_log.md`.
