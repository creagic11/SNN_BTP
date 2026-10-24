# HUSH v2 — Revised BTP Research Proposal

Oct 15, 2026 · Anubhav Jha (23EE10091), IIT Kharagpur · Supervisor: Prof. Rajat Shubhra Chakraborty

Repository copy of the Claude Doc of the same name. Diagrams live in the Claude Doc.

## Summary

HUSH v2 skips the weight fetch and accumulation for whole groups of neurons whose membrane potentials provably cannot reach threshold in the current timestep, on a Xilinx Artix-7 XC7A100T. It targets output-side, state-driven dynamic sparsity, the axis that FPGA SNN accelerators leave unused. Input-spike skipping (Cerebron, Spiker+) and static weight sparsity (FireFly-S, SPARSH) are already well covered.

**Thesis statement.** A per-group integer envelope, computed from input spikes and a small proxy table, can switch off BRAM reads and PE cycles with a machine-checked guarantee that no switched-off neuron would have fired. The resulting envelope-gated network can be trained to stay within 1 accuracy point of the ungated network.

**Hypotheses, each with a gate in the roadmap:**

1. **H1 (feasibility).** After neuron clustering and gated training, the awake-block fraction ρ is at most 0.35 at no more than 1 point accuracy loss on at least two of MNIST, N-MNIST and SHD.
2. **H2 (speed).** With a decoupled envelope pipeline, layer cycles fall by min(G, 1/ρ) against the same engine with gating off. For G = 13 that is 2.9× at ρ = 0.35 and 8.7× at ρ = 0.115.
3. **H3 (energy).** Measured energy per inference falls in proportion to the BRAM read bits avoided, after paying the envelope overhead (about 3% of baseline read bits at 32-neuron granularity, about 12% with 8-neuron sub-blocks).

**What changed from v1.** Signed proxies with a clamped sum; a hierarchical envelope matched to the RAMB36 72-bit column; a decoupled pipeline that hides the envelope pass; an eager shift-subtract leak instead of the lazy-leak ROM and DSPs; and "zero accuracy loss" replaced by an exact statement of what the hardware computes.

## Audit of v1: what is kept and what is discarded

| Item from v1 | Decision | Reason |
| --- | --- | --- |
| Output-side block hibernation driven by a membrane envelope | Keep | The core novelty |
| Proxy table P = per-block max of positive weights | Upgrade | Signed proxies with a clamped sum are tighter and still provable |
| "Zero accuracy loss versus the exact network" | Discard | Inputs arriving during hibernation are dropped, so later state can differ from plain LIF |
| Lazy leak via a 72-entry λ^Δ ROM and 32 DSP48E1s | Discard | Not bit-identical to repeated shift-subtract; replaced by an eager leak sweep, 0 DSPs |
| EXACT configuration | Discard | One RTL with the mask forced on is the baseline |
| Spectral clustering and group-lasso training | Keep, retarget | Penalty now acts on envelope exceedance, with the gate in the forward pass |
| Results draft: 202→17 mW, 3.8×, s* = 42.8%, 0 BRAM | Discard all | 0 RAMB36 means weights were not on chip; 8.41× on SHD exceeds the cap G = 8 |
| Shunt protocol on Nexys A7 jumpers JP1/JP3 | Discard | Those jumpers select programming mode and power source |
| 10-week plan | Replace | 18-week plan with four gates |

Correction to the earlier review: Spiker+ on SHD runs in 0.54 ms at 0.43 W (0.23 mJ per inference) per its Table III; the 54 µs in its abstract is inconsistent with that table.

## Literature review

See `docs/literature/` for the comparison table and the novelty check.

## Formulation

**Integer LIF with soft reset.**

    L(x) = x − (x >> k)
    U_i(t) = L(V_i(t−1)) + Σ_{j∈S(t)} W_ij
    s_i(t) = [U_i(t) ≥ θ]
    V_i(t) = U_i(t) − θ·s_i(t)

`>>` is an arithmetic shift (floor division by 2^k).

**Lemma 1 (monotone leak).** L is non-decreasing on the integers: L(x+1) − L(x) ∈ {0, 1}.

**Gated model.** Neurons are grouped into sub-blocks c of 8. If g_c(t) = 1 the update runs unchanged. If g_c(t) = 0, inputs at t are dropped: V_i(t) = L(V_i(t−1)), s_i(t) = 0.

**Envelope with signed proxies.**

    P_{j,c} = max_{i∈c} W_ij
    D_c(t)  = Σ_{j∈S(t)} P_{j,c}
    Ê_c(t)  = sat( L(R_c(t−1)) + max(0, D_c(t)) )
    g_c(t)  = [Ê_c(t) ≥ θ_h]
    R_c(t)  = max_{i∈c} V_i(t) if awake, else Ê_c(t);  R_c(0) = 0

**Theorem 1.** For all t and i ∈ c: V_i(t) ≤ R_c(t) and U_i(t) ≤ Ê_c(t). Proof by induction using W_ij ≤ P_{j,c} and Lemma 1; upward saturation only raises Ê.

**Corollary 1 (exact mode).** If θ_h ≤ θ, gating never removes a spike the ungated update would have produced at that timestep.

**Corollary 2.** max(0, ΣP) ≤ Σ max(0, P): never looser than v1.

**Corollary 3 (hierarchy).** A 32-neuron block is scheduled if any of its four sub-blocks is awake; this is tighter than one proxy over 32 neurons.

**Predictive mode.** θ_h > θ gates more aggressively and can suppress spikes; reported separately.

## Microarchitecture on the XC7A100T

Layer-major dataflow (all T timesteps of layer 1, then layer 2), so a layer's spike raster is complete before its pass. The envelope for t+1 is computed while the PE array works on t.

Units: (1) ETU — per active input reads one proxy row (400 bits for N = 400) into 50 saturating INT16 accumulators; (2) Combine — Ê_c = L(R_c) + max(0, D_c), compare with θ_h, 50-bit sub-block mask OR-reduced to 13-bit block mask; (3) Scheduler + 32-lane PE array — one 256-bit weight word per active input at address b·M + j, threshold, soft reset, write-back, four 8-input max trees giving R_c; (4) Leak sweep for asleep blocks on the second LUTRAM port; (5) Output raster writer.

Memory map: a 512×72 RAMB36 column holds 8 INT8 weights + 8 spare bits; one 256-bit word = 4 columns = 4 sub-blocks. Block skipping saves cycles and energy; sub-block gating saves energy.

**Cycle model.**

    C_BASE = Σ_t (G·n_t + c0)
    C_HUSH = Σ_t (max(n_{t+1}, A_t·n_t) + c1)
    speedup ≈ G / max(1, ρG) = min(G, 1/ρ)

MNIST 784-400, G = 13, 5% activity (39 active inputs), BASE = 507 cycles/timestep:

| ρ | v1 serial (cycles) | v2 overlapped (cycles) | v2 speedup |
| --- | --- | --- | --- |
| 0.115 | 97 | 58 | 8.7× |
| 0.35 | 216 | 177 | 2.9× |
| 1.0 | 546 | 507 | 1.0× |

**Resource budget (pre-synthesis estimates).**

| Unit | LUT | FF | DSP | RAMB36 |
| --- | --- | --- | --- | --- |
| Weights 784×400 INT8 | ~100 | ~50 | 0 | 80 |
| Proxy table 784×50 INT8 | 0 | 0 | 0 | 12 |
| ETU + combine | ~2,400 | ~1,600 | 0 | 0 |
| PE array 32×INT16 | ~1,200 | ~800 | 0 | 0 |
| Four 8-input max trees | ~450 | ~300 | 0 | 0 |
| State LUTRAM 400×INT16 | ~350 | 0 | 0 | 0 |
| Output layer + argmax | ~300 | ~200 | 0 | 2 |
| Control + rasters | ~600 | ~450 | 0 | 2 |
| **Total** | **~5,400 (8.5%)** | **~3,400 (2.7%)** | **0** | **~96 (71%)** |

Clock target 100 MHz. Fallback XC7A35T: 784-128-10 needs 28 + 4 RAMB36; G = 4 caps speedup at 4×.

## Training co-design

1. Integer-faithful forward pass (fake-quantized INT8, shift-subtract leak, soft reset); trainer and golden model share one kernel.
2. Permutation clustering into 8-neuron sub-blocks, then 32-neuron blocks (zero accuracy cost).
3. Gate in the loop: STE on g_c, subgradient through max for P.
4. Losses: exceedance γ·mean relu(Ê_c − θ_h); dispersion δ·Σ_j (max_i W_ij − mean_i W_ij) per sub-block.
5. Sweep θ_h from θ upward; report accuracy-vs-ρ Pareto.

Report per dataset: (a) ungated INT8, (b) gated without retraining, (c) after gated fine-tuning, (d) predictive mode at the Pareto knee. Workloads: MNIST 784-400-10; N-MNIST 578-512-10; SHD 700-256-20 feed-forward first.

## Verification and validation

| Check | Method | Pass criterion |
| --- | --- | --- |
| Golden models | Python integer REF, GATED, ORACLE | Shared kernel with training |
| Invariant in simulation | cocotb + Verilator with shadow ungated datapath | Zero violations on full test sets |
| Formal proof | SymbiYosys, small sizes, BMC + k-induction | Invariant proved |
| Bit-exact equivalence | RTL vs GATED | 100% identical |
| Saturation | Directed tests | Saturates, never wraps |
| Performance counters | Cycles, column enables, awake sub-blocks | Within 1% of cycle model |

Validation: WNS ≥ 0 at 100 MHz; SAIF over ≥100 samples per dataset; board ΔP BASE vs HUSH, ≥30 s × 5 runs; cross-check measured vs Vivado vs enable-count energy within 25%.

## Evaluation protocol

| Name | Mask | Envelope | Purpose |
| --- | --- | --- | --- |
| BASE | Forced on, ETU off | None | Baseline |
| HUSH-32 | Block gates | Per 32 neurons | Block skipping |
| HUSH-8/32 | Sub-block gates | Per 8 neurons | Column gating |
| ORACLE | True max of U | None | Lower bound on ρ |

External baseline: Spiker+ regenerated for the same topologies on the XC7A100T. Sweeps: input activity, B_env ∈ {4, 8, 16, 32}, θ_h, T.

## Roadmap and gates (19 Oct 2026 → 21 Feb 2027)

1. **G0, 8 Nov.** ORACLE ρ ≤ 0.6 and HUSH ρ ≤ 0.5 after clustering on ≥2 datasets; Early, SPARSH, C-STEP read.
2. **G1, 29 Nov.** ρ ≤ 0.35 at ≤1 point loss on ≥2 datasets.
3. **G2, 27 Dec.** RTL bit-exact vs GATED, formal proof passing, counters within 1%.
4. **G3, 24 Jan.** WNS ≥ 0 at 100 MHz; measured energy ≥30% below BASE on ≥2 datasets.

## Risks and publication

| Risk | Signal | Response |
| --- | --- | --- |
| Envelope too loose | G0 fails | B_env = 4, dispersion loss; else characterization paper |
| Dropped drive costs accuracy | G1 fails | Gated fine-tuning; report modes separately |
| Prior art covers it | Week-1 reading | Narrow claim to BRAM-matched hierarchy, pipeline, silicon |
| BRAM cascade limits Fmax | WNS | Registered BRAM outputs |
| ΔP too small | Std > ΔP | Longer integration, counter-based energy |
| Recurrent SHD breaks look-ahead | FC-R throughput | Feed-forward SHD first |

Publication path: TCAS-II brief → DATE/FCCM/FPL full paper → ISCAS/AICAS fallback.
