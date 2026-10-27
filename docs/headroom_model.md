# When does HUSH gating pay? A headroom model (27 Oct 2026)

A sub-block c sleeps at step t iff clip(Bmax_c) + D_c < θ_h, with Bmax_c the drive-free part of its most excited neuron, and D_c = Σ_j z_j P_jc. Write H_c = θ − Bmax_c (headroom) and D ≈ n_t · E[P⁺] (events per step × mean positive proxy). The work-weighted sleep probability is

  ρ_sleep ≈ Pr[ D_c < H_c ], weighted by n_t.

**Headroom is set by leak memory.** For a neuron with leak L(x) = x − (x ≫ k) and a sustained net drive b per step (inhibitory input on average, or a constant bias current), the steady state of V = L(V) + b gives V* = 2^k · b and B* = L(V*) + b = 2^k · b. So a uniformly inhibited neuron holds headroom H ≈ θ + 2^k · |b|. **The leak shift multiplies hyperpolarisation into headroom.**

| Model | k | 2^k | measured headroom (mean, θ units) | D/θ (mean) | work-weighted reads |
| --- | --- | --- | --- | --- | --- |
| FF LIF, SHD 700 ch, T = 250 (co-trained, mf gentle) | 5 | 32 | 9.67 | 2.25 | 0.64 |
| recurrent adLIF, SHD 700 ch, T = 250 (co-trained) | 5 | 32 | 0.09 | 2.61 + 0.44 | 0.98 |
| FF + axonal delays, SHD 140 ch, T = 100 (folded, layer 1) | 2 | 4 | 0.43 | 4.60 | 0.997 (before co-training) |

**Two ways to lose headroom:**
- **Fast leak.** Small k means a small 2^k. Delay networks prefer near-memoryless neurons (DCLS: τ ≈ 1 step) because the delays carry the temporal structure.
- **Subthreshold adaptation with a > 0, and recurrent excitation.** These pull V back towards rest or keep it primed, so co-training cannot build a hyperpolarised reservoir.

**Design rule (to verify experimentally):** HUSH needs H ≳ n_t · E[P⁺]. For fixed accuracy, prefer the slowest leak the task tolerates, and co-train so that the bias current is inhibitory and excitation is sparse. Coarser time bins raise n_t; finer bins lower n_t but need longer delays (dmax in steps).

Next experiment: delay network with k = 4 (2^k = 16) at T = 100, then gated co-training. The question is whether accuracy holds while headroom grows.

## Measured on the delay network (27 Oct)

| Network (SHD, val protocol) | Ungated test | Gated (mf, gentle) test | Reads | Note |
| --- | --- | --- | --- | --- |
| FF LIF k = 5, 700 ch, T = 250 (Oct 24) | 70.8% | 70.8% | 0.64 | headroom 9.7θ |
| recurrent adLIF k = 5 | 83.1% | 81.6% | 0.98 | headroom 0.09θ |
| FF + delays k = 2 (folded) | 87.4% | 85.3% | 0.97 | headroom 0.43θ′ |
| FF + delays k = 4 (folded, 39-epoch checkpoint) | 84.3% | 77.6% (no rate reg) | 0.77 | headroom 1.23θ′ |

**Controls (k = 4).** Rate regulariser alone, no gate: 83.8% at rate 2.6% (−0.5 pt). Gate alone, no rate regulariser: 77.6% at reads 0.77 (−6.7 pt), with the rate falling to 1.6%. **The loss is caused by gating**, not by the rate penalty. With small headroom, the gate can only sleep if the co-training losses suppress activity network-wide, and that costs accuracy.

**Conclusion.** HUSH pays when the trained network sits in a hyperpolarised regime (headroom ≫ n_t·E[P⁺]). The networks that reach high SHD accuracy (recurrent adaptation, or fast-leak delays) do not sit there, and forcing them there costs 6–7 points or more.
