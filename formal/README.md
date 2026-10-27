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
