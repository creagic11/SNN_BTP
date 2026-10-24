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

### Running

Gated co-design fine-tune: gate in the forward pass, exceedance loss (λ = 2), envelope-drive loss (λ = 1), 5% rate target, warm start from the baseline. Log: `results/train_shd_T250_gated.log`.
