# T0.9 Regime study (in progress)

## SHD 700-256-20, feed-forward, T = 250 (4 ms bins over 1 s), k = 5, θ = 64, INT8

Trained 25 epochs with a 5% hidden firing-rate target: **70.8% test accuracy** (PyTorch, full test set). Spiker+ reports 72.99% with a recurrent 700-200-20 network and second-order LIF.

Gates on the hidden layer, 300 random test samples (`results/shd_T250/rho_unclustered.json`):

| Gate | Accuracy | ρ_sub | ρ_blk | Column reads vs BASE | Cycle speedup |
| --- | --- | --- | --- | --- | --- |
| REF | 71.7% | 1.00 | 1.00 | 1.00 | 1.00× |
| ORACLE (8) | 60.3% | 0.24 | 0.40 | 0.61 | 1.08× |
| HUSH-4/32, exact resync | 62.0% | 0.38 | 0.48 | 0.91 | 1.01× |
| HUSH-8/32, exact resync | 64.3% | 0.45 | 0.51 | 0.97 | 1.01× |
| HUSH-8/32, carried (v1) | 70.0% | 0.52 | 0.62 | 0.98 | 1.00× |
| HUSH-32, exact resync | 70.0% | 0.58 | 0.58 | 0.99 | 1.01× |

Mean active inputs per timestep 32.4; hidden firing rate 5%.

### What this shows

1. **ρ per (block, timestep) is a misleading metric.** Blocks mostly sleep on timesteps with no or few inputs, which cost nothing anyway. The quantity that matters is work-weighted: column reads and cycles. On that measure HUSH-8/32 saves 3% of reads and ~1% of cycles.
2. **Block-level skipping is nearly impossible here even for a perfect gate.** The ORACLE gives a 1.08× cycle speedup: whenever input arrives, about 7.4 of 8 blocks hold at least one neuron that will fire or is close to it. Sub-block column gating has at most 39% read savings (ORACLE).
3. **Dropping sub-threshold drive costs accuracy on a temporal task.** ORACLE gating costs 11.4 points (71.7 → 60.3%): SHD relies on integrating sub-threshold input over time, and the gated model throws exactly that away. The exact-resync envelope wakes more blocks after a skip and so loses accuracy faster than the carried bound.
4. **Envelope looseness at 32 inputs/step**: expected positive drive bound ≈ 3.7 θ per step (envelope-drive metric), still well above θ.

## Co-design: gate in the training loop (SHD, T = 250)

Fine-tuned 15 epochs from the baseline with the HUSH-8/32 gate in the forward pass (bit-exact with the golden GATED model, checked on 200 samples: 0 spike and 0 prediction mismatches), exceedance loss λ = 2, envelope-drive loss λ = 1, 5% rate target (`results/train_shd_T250_gated.log`).

| Network | Gate at inference | Accuracy | Column reads vs BASE | Cycle speedup |
| --- | --- | --- | --- | --- |
| Baseline (ungated training) | none | 70.8% (full test) | 1.00 | 1.00× |
| Baseline | HUSH-8/32 | 64.3% (300 samples) | 0.97 | 1.01× |
| Gated co-design | HUSH-8/32 | **64.9%** (full test), 66.4% (500 samples) | **0.26** | **1.70×** |
| Gated co-design | ORACLE-8 | 51.0% (500 samples) | 0.15 | 2.52× |

Training with the gate turns HUSH from useless into a **3.8× reduction in weight-column reads and 1.7× fewer cycles**, at **−5.9 accuracy points**. The envelope-drive bound fell from 3.7 θ to 1.1 θ per timestep and hidden firing from 5% to 1.3%. The epoch-to-epoch accuracy is noisy (58–65%), so the final number needs repeat runs.

Running: a λ sweep to trace the accuracy-vs-reads Pareto front, plus an ungated network trained to the same 1.3% firing rate to separate "sparser firing" from "gating" as the cause of the accuracy loss (`scripts/sweep_shd.sh`).

## Pareto sweep, SHD T = 250, HUSH-8/32, single seed each

Accuracy on the full test set (2,264) from the trainer; reads and cycles from the golden model on 300 samples.

| Run | Training | Accuracy | Column reads vs BASE | Cycle speedup | Hidden rate |
| --- | --- | --- | --- | --- | --- |
| baseline | ungated, 5% rate target | 70.8% | 0.97 (gate at inference) | 1.01× | 5.0% |
| g_e0 | gate in loop, no envelope losses | 70.5% | 0.97 | ≈1.01× | 5.1% |
| g_e025 | gate, exceedance λ 0.25 | 68.8% | 0.86 | 1.01× | 3.8% |
| g_e05_d025 | gate, exceedance 0.5, drive 0.25 | 68.7% | 0.68 | 1.02× | 2.8% |
| gated (g_e2_d1) | gate, exceedance 2, drive 1 | 64.9% | 0.26 | 1.70× | 1.3% |
| ungated_r013 (control) | ungated, 1.3% rate target (reached 2.2%) | 69.5% | — | — | 2.2% |

Reading the front: about 2 points buy a 32% read reduction; 6 points buy 74% and the first real cycle gain. The control network at 2.2% firing keeps 69.5%, so most of the loss at the aggressive end comes from gating (dropped sub-threshold drive), not from sparser firing. That points at the asleep-neuron semantics as the lever: mean-field hibernation training is running (`scripts/sweep_shd_mf.sh`).
