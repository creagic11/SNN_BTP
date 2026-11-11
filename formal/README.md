# Formal verification of the HUSH safety arithmetic (T2.3)

`fv_hush.sv` wraps the RTL modules `hush_envelope` and `hush_lane` from `rtl/hush_arith.sv` (the same modules `rtl/hush_layer.sv` instantiates) into one sub-block of 4 lanes driven by 3 inputs, with arbitrary constant 4-bit weights and arbitrary input spikes every cycle. Widths are reduced (VB = 8, AB = 12, K = 2, θ = 20) so the solver finishes; the argument does not depend on width because both clips are the same monotone function.

Properties (assertions on every reachable state):

1. A gated sub-block contains no lane whose ungated update reaches θ (no suppressed spike).
2. R equals the exact max V of the sub-block (exact resync invariant).
3. Every lane's new pre-reset potential, awake or asleep (incl. mean-field drive), is ≤ the envelope E.
4. A spike implies the sub-block is awake.

| Task | Engine | Result |
| --- | --- | --- |
| `prove_mf` (mean-field) | ABC PDR (unbounded) | **PASS**, 1,128 s |
| `prove_drop` (drop semantics) | ABC PDR (unbounded) | **PASS** |
| `fv_hush_mut.sby` (proxy replaced by the sub-block mean: unsafe) | ABC BMC3, depth 8 | **FAIL** found immediately: the properties are not vacuous |

Run: `sby -f fv_hush.sby prove_mf` (needs SymbiYosys at tag `yosys-0.33` to match Yosys 0.33; SMT engines boolector 1.5 and z3 4.8 did not finish here).

Scope note: the formal proof covers the safety arithmetic and the resync recursion for one sub-block. The full layer (memories, sequencing, counters) is checked by bit-exact simulation against the golden model (`rtl/sim/regress.py`).

Note (27 Oct 2026, timing fixes). `hush_layer` now registers the saturated pre-reset potential U (output `u` of `hush_lane`) and the awake bits at FIN, and applies spike = awake ∧ (U ≥ θ) and Vnew = U − θ·spike in a second stage (FIN2). The formula is identical to `hush_lane`'s; the proven safety arithmetic (U and the envelope) is unchanged. R is refreshed from the registered word through a two-stage max tree, so it lands 2 cycles after FIN2 and is first read ≥ 3 cycles after it, at COMBINE. Bit-exact simulation covers both changes (40/40 random + N-MNIST in all modes). The formal harness still instantiates `hush_lane` / `hush_envelope` directly.

## Full-width check (11 Nov 2026) — `fv_width.sv`, `fv_width.sby`

The reduced-width proof above covers the sequential behaviour (the R recursion over time). This second check runs
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

### Width and value bounds of the implementation (`rtl/hush_layer.sv`, `rtl/hush_net.sv`)

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
