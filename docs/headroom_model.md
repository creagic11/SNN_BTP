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
