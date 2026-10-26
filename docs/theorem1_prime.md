# HUSH-G: safety of envelope gating for recurrent adaptive LIF (Theorem 1′)

Status: proved on paper (below), property-tested (`tests/test_hush_rec.py`, 9 tests, about 2,500 random layers per run), mutation-checked. Formal (SymbiYosys) extension is P2.

## Model (integer, per layer, per timestep t)

| Symbol | Definition |
| --- | --- |
| z_t | [x_t ; s_{t−1}] ∈ {0,1}^{M+N}: FF spikes and the layer's own previous spikes |
| Wc | [Wff ; Wrec] ∈ ℤ^{(M+N)×N}, INT8; recurrence adds input rows, nothing else |
| L_k(x) | x − (x ≫ k), monotone (Lemma 1) |
| B_i | L_k(V_i) − w_i, the drive-free part of the next potential |
| U_i | clip(B_i + z_t·Wc[:, i]), with clip the same monotone saturation to `vbits` |
| s_i, V_i′ | s_i = [U_i ≥ θ], V_i′ = U_i − θ s_i (soft reset) |
| w_i′ | clip_w(L_kw(w_i) + ((a_i V_i′) ≫ sa) + b_i s_i): integer adLIF adaptation |
| P_jc | max_{i∈c} Wc_ji (signed proxy) |
| Q_jc | ⌊mean_{i∈c} Wc_ji⌋ ≤ P_jc (mean-field table) |

## Gate (headroom envelope)

Before the inputs of step t are fetched, the state sweep has every B_i exactly, so

- Bmax_c = max_{i∈c} B_i
- D_c = z_t · P[:, c] (signed). The v1 rule used max(0, D_c).
- g_c = [clip(Bmax_c) + D_c ≥ θ_h] ∨ [Bmax_c > v_max]

## Theorem 1′ (exact mode, θ_h ≤ θ)

If g_c = 0, then for every neuron i in sub-block c, the ungated update from the same state gives U_i < θ. Gating therefore removes no spike at step t.

**Proof.**

1. Since g_c = 0, Bmax_c ≤ v_max, so B_i ≤ Bmax_c ≤ clip(Bmax_c). The clip only raises values below v_min.
2. Because z ≥ 0 elementwise and Wc_ji ≤ P_jc, z·Wc[:, i] ≤ z·P[:, c] = D_c.
3. Therefore B_i + z·Wc[:, i] ≤ clip(Bmax_c) + D_c < θ_h ≤ θ.
4. clip is monotone and θ ≤ v_max, so U_i = clip(B_i + z·Wc[:, i]) < θ. ∎

**Corollary (mean-field).** An asleep neuron gets U_i = clip(B_i + z·Q[:, c]) ≤ clip(B_i + z·P[:, c]) < θ, so it never spikes, and its state stays exact for its own (approximate) dynamics.

**Corollary (spike equality per step).** From the same state, the gated layer emits exactly the ungated layer's spikes. Tested as `test_gated_spikes_equal_ungated_spikes_same_state`.

**What the theorem does not claim.** Under drop or mean-field semantics, an asleep neuron's state differs from REF, because it skipped or approximated sub-threshold drive. Future spikes can therefore differ. Accuracy, not spike equality, is the end-to-end measure. This is the same scope as v1.

### Why each ingredient is needed (mutation results)

| Mutation | Tests that fail |
| --- | --- |
| Gate uses L(V) without −w (ignore adaptation) | 5 / 9 |
| No forced wake on Bmax > v_max (saturating register with a negative D) | 2 / 9 |
| Recurrent rows left out of P | 6 / 9 |

### Notes for hardware (P2)

- **Bmax saturation.** The gate needs a saturation flag (Bmax > v_max ⇒ awake) because D is signed. With the v1 rule (D ≥ 0), a saturated register always gates on anyway.
- **Signed D: no measured gain.** On the trained FF nets (N-MNIST and SHD, gentle and aggressive), the signed-D gate gave identical reads (0.155, 0.638, 0.058, 0.180) and identical accuracy to the v1 rule. Co-trained proxies are almost never net-negative. Keep it only if recurrent inhibition changes this; otherwise keep v1's cheaper unsigned compare.
- **Sweep work.** The state sweep must now produce B_i = L_k(V_i) − w_i and the w update per neuron: one 16-bit subtract plus a (a_i·V′) ≫ sa product per neuron per step.

## Lemma 2 (adLIF stability, used by the trainer)

The subthreshold linear map (V, w) ↦ (λV − w, μw + cλV − c·w) has c = a/2^sa, λ = 1 − 2^−k and μ = 1 − 2^−kw. Its Jacobian is [[λ, −1], [cλ, μ − c]], with determinant λμ and trace λ + μ − c.

Both eigenvalues lie inside the unit circle iff −c < (1 − λ)(1 − μ) = 2^−(k+kw), together with det = λμ < 1 (always true) and c < (1 + λ)(1 + μ) (always true for c ≤ a_max/2^sa = 1/8). This is the Jury criterion for a 2×2 map: |det| < 1 and |tr| < 1 + det.

So any practical negative coupling is unstable. For example, a = −8, sa = 8, k = kw = 5 gives a spectral radius of 1.14 per step, and at T = 250 that made BPTT gradients reach 1e9 to 1e27. The trainer therefore constrains a ∈ [0, a_max]. For a ≥ 0 the eigenvalues are either complex with modulus √(λμ) < 1, or real and below 1. **Relation to SE-adLIF.** Our integer update computes w′ from the freshly updated V′. That is the symplectic-Euler (SE) discretisation of Baronig et al., "Advancing spatio-temporal processing in SNNs through adaptation", *Nature Communications* 2025 (arXiv 2408.07517). It explains why det = λμ is independent of the coupling. They show that SE-adLIF has a decay rate of √(αβ) for every a ≥ 0, whereas Euler-forward adLIF diverges once a > (1 − αβ)/((1 − α)(1 − β)).

Our blow-up came only from allowing a < 0, an anti-adaptive positive feedback. Constraining a ≥ 0 restores the SE guarantee.

Their SHD reference points:

| Model | Layers | Parameters | SHD test accuracy |
| --- | --- | --- | --- |
| SE-adLIF | 1 | 37.5k | 94.59 ± 0.27% |
| SE-adLIF | 2 | 0.45M | 95.81 ± 0.56% |
| LIF | — | 450k | 90.27% |

These numbers are float, not quantised, and no hardware was reported.

## Lemma 3 (reset-path gradient bound, used by the trainer)

With soft reset V′ = U − θ·s and the surrogate s′ = σ′(U − θ), where σ′(x) = 1/(c·(1 + |x|/c)²) peaks at 1/c, the BPTT factor along the state is ∂V′/∂U = 1 − θ·σ′(U − θ) ∈ [1 − θ/c, 1].

- With c = θ/4, the factor can reach −3. A neuron that sits near threshold for many steps, which is likely with slow leaks such as k = 7 under heterogeneous τ, then amplifies the gradient by up to 3^n. We measured max |∇W| of 1e27 to 1e30, or NaN, on 3 of 4 seeds at initialisation.
- With c = θ/2, the factor stays in [−1, 1] and the same seeds give 3e−4 to 7e−4.
- Detaching the reset also works, giving 4e−3 to 1e−2.

The default for recurrent adLIF layers is now c = θ/2. The first homogeneous baseline used θ/4, and its loss spike at epoch 8 (0.80 → 1.46) is consistent with this.
