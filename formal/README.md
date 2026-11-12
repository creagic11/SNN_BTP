# Formal verification of the HUSH safety arithmetic

Two complementary SymbiYosys checks verify the arithmetic of the gate on the RTL modules that the design
instantiates (`hush_envelope` and `hush_lane` in `rtl/hush_arith.sv`). The first works at the exact bit widths of
the implementation for one timestep; the second works at reduced widths over unbounded time. Memories, sequencing
and the remaining datapath are verified by bit-exact simulation against the golden model (`rtl/sim/`).

Requirements: Yosys 0.33, SymbiYosys at tag `yosys-0.33`, ABC (engine `abc pdr`). Run from this directory:

```
sby -f fv_width.sby m578        # full width, hidden layer (578 inputs)
sby -f fv_width.sby m256        # full width, output-layer widths (256 inputs)
sby -f fv_width_mut.sby m578    # mutant: must FAIL
sby -f fv_hush.sby prove_mf     # reduced width, mean-field drive for sleeping lanes
sby -f fv_hush.sby prove_drop   # reduced width, sleeping lanes receive no drive
sby -f fv_hush_mut.sby          # mutant: must FAIL
```

The `fv_width_m256`, `fv_width_m578` and `fv_width_mut_m578` directories hold the solver outputs of the full-width runs (status files and logs). The outputs of the reduced-width runs are not tracked.

## 1. Full-width inductive step — `fv_width.sv`, `fv_width.sby` (11 November 2026)

This check runs
the same RTL modules (`hush_envelope`, `hush_lane`) at the **exact widths of the implementation**: VB = 16,
K = 4, θ = θ_h = 64, and AB = clog2(2¹⁵ + 128·M + 1) + 1 = 18 bits for both layers (M = 578 hidden, M = 256
output). It is the inductive step of Theorem 1 for one 8-lane sub-block with every value free: assuming
V_l ≤ R (induction hypothesis), drive_l ≤ D and qs ≤ D (Σ_j W_jl ≤ Σ_j P_jc and ⌊mean⌋ ≤ max, per active input),
and |D|, |drive_l|, |qs| bounded by sums of at most M INT8 values, it proves:

| | Property | m578 | m256 |
|---|---|---|---|
| F1 | gate = 0 ⇒ the ungated U_l < θ (no suppressed spike) | PASS | PASS |
| F2 | U_l ≤ E for every lane, awake or asleep (mean-field drive) | PASS | PASS |
| F3 | spike ⇒ gate | PASS | PASS |
| F4 | no wrap-around: every 18-bit sum and the clipped envelope equal the same computation 8 bits wider | PASS | PASS |
| F5 | V′_l ≤ max_l V′_l (R′ = max V′ restores the hypothesis) | PASS | PASS |

Engine ABC PDR, 72 s for both tasks. Mutant `fv_width_mut.sv` (drops the assumption that the proxy bounds the
weights) FAILs immediately, so the check is not vacuous. With V = R = 0 at reset, F5 + F2 make V_l ≤ R an invariant
of all reachable states and F1 holds at every timestep, at full width.

**Scope.** What this check covers and what it does not:
- It proves the envelope and lane arithmetic (`hush_envelope`, `hush_lane`) at the real widths, *given* the assumption
  that each neuron's drive is at most D_c (and q_c ≤ D_c). That assumption holds by construction of the P and Q tables,
  which are generated offline from the weights; the bit-exact simulations check the tables and the memories.
- F5 is a sanity check only: it states that a maximum bounds its inputs. The RTL max tree that computes R_c and the
  second finalise stage are not in this harness; they are covered by the bit-exact RTL-vs-golden simulations.
- The m256 task matters only for F4 (no wrap-around at the output layer's widths); the output layer is not gated.


## 2. Reduced-width sequential proof — `fv_hush.sv`, `fv_hush.sby` (24–25 October 2026)

`fv_hush.sv` wraps `hush_envelope` and `hush_lane` into one sub-block of 4 lanes driven by 3 inputs, with
arbitrary constant 4-bit weights and arbitrary input spikes every cycle. Widths are reduced (VB = 8, AB = 12,
K = 2, θ = 20) so that the unbounded proof completes; the argument does not depend on the width because both clips
are the same non-decreasing function. Properties, asserted on every reachable state:

1. A sleeping sub-block contains no lane whose ungated update reaches θ (no suppressed spike).
2. R equals the exact maximum V of the sub-block (exact resynchronisation).
3. Every lane's new pre-reset potential, awake or asleep (including the mean-field drive), is at most E.
4. A spike implies that the sub-block is awake.

| Task | Engine | Result |
| --- | --- | --- |
| `prove_mf` (mean-field drive) | ABC PDR (unbounded) | PASS, 1,128 s |
| `prove_drop` (no drive while asleep) | ABC PDR (unbounded) | PASS |
| `fv_hush_mut.sby` (proxy replaced by the sub-block mean, which is unsafe) | ABC BMC3, depth 8 | FAIL at once, so the properties are not vacuous |

SMT engines (Boolector 1.5, Z3 4.8) did not complete within the time available.

The RTL registers U and the awake bits at the first finalise stage and applies spike = awake ∧ (U ≥ θ) and
V′ = U − θ·spike in a second stage; the formula is the one in `hush_lane`. R is refreshed through a two-stage max
tree and is first read at least 3 cycles after it is written. Both stages are covered by the bit-exact simulations.

## 3. Width and value bounds of the implementation (`rtl/hush_layer.sv`, `rtl/hush_net.sv`)

| Quantity | Width | Range of values that can occur | Headroom |
|---|---|---|---|
| Weight W, proxy P = max, mean Q = ⌊mean⌋ | 8 b signed | [−128, 127] (Q ≤ P) | exact |
| Membrane V, R, leak L(V) = V − (V ≫ 4) | 16 b signed | [−32,768, 32,767]; L(V) ∈ [−30,720, 30,720] | saturated by design |
| Envelope sum D, mean-field sum qs (hidden layer, ≤ 578 active inputs) | 18 b signed | [−73,984, 73,406] | 1.77× |
| Lane accumulator L(V) + Σ W (hidden layer) | 18 b signed | [−104,704, 104,126] | 1.25× |
| Lane accumulator (output layer, ≤ 256 active inputs) | 18 b signed | [−63,488, 63,232] | 2.06× |
| U and E after the clip | 16 b | [−32,768, 32,767] | saturated by design |
| Classifier spike count per class (T = 100) | 16 b | [0, 100] | — |
| Classifier ΣU per class | 32 b signed | \|ΣU\| ≤ 100 · 32,768 = 3.28 M | 655× |

The accumulators are sized so the sums are exact before the single clip; F4 checks this at the real widths.
