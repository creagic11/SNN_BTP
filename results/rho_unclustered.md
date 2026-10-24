# T0.6–T0.8 results: MNIST 784-400-10, rate-coded (first G0 data point)

Date 2026-10-24. Network: INT8 weights, θ = 64, k = 3 (λ = 0.875), T = 25, deterministic IF encoder (gain 1).
Training: 15 epochs, Adam + one-cycle, spike-count cross-entropy (`results/mnist_400/metrics.json`).

## Baseline (T0.6)

| Metric | Value |
| --- | --- |
| Test accuracy, PyTorch, 10k images | 97.53% |
| Test accuracy, golden REF, first 1,000 images | 97.8% |
| Bit-exact check, 2,000 images | 0 hidden-spike and 0 prediction mismatches; max |U| = 3,415 (fits INT16) |
| Mean input activity | 11.8% (≈ 90 active inputs per timestep) |
| Mean hidden firing rate | 18.7% |

## Awake fractions (T0.7 unclustered, T0.8 clustered), hidden layer, 500–1,000 test images

| Grouping | Gate | Accuracy | ρ_sub | ρ_blk | PE speedup |
| --- | --- | --- | --- | --- | --- |
| none | REF (ungated) | 97.8% | 1.00 | 1.00 | 1.00× |
| none | ORACLE (8) | 96.1% | 0.67 | 0.95 | 1.01× |
| none | HUSH-8/32 | 97.8% | 0.96 | 0.96 | 1.00× |
| weight k-means | ORACLE (8) | 97.0% | 0.59 | 0.91 | 1.04× |
| weight k-means | HUSH-8/32 | 98.2% | 0.96 | 0.96 | 1.00× |
| co-activity k-means | ORACLE (8) | 95.8% | 0.39 | 0.80 | 1.18× |
| co-activity k-means | HUSH-8/32 | 98.2% | 0.96 | 0.96 | 1.00× |

The constant 0.96 for HUSH is an artefact: timestep 0 has no input spikes (the IF encoder needs one step to charge), so all sub-blocks sleep then; at every other timestep every sub-block is awake. **HUSH gates nothing on this workload.**

## Why (envelope_gap.py)

| Quantity (per sub-block decision) | Value |
| --- | --- |
| Mean drive gap, max(0, ΣP) − max_i ΣW | 517–542 (8–8.5 θ) |
| Mean state gap, L(R) − max_i L(V) | 0 (blocks are always awake, so R is exact) |
| False wakes where the drive bound alone exceeds θ | 100% |

The drive gap is about 5.8 integer units per active input. With ≈ 90 active inputs per timestep it is 8× the threshold, so the envelope always exceeds θ. The bound grows linearly with active inputs per timestep, while the real potential grows far slower.

## Verdict for G0 on this workload: FAIL

1. Even the ORACLE keeps 80–95% of 32-neuron blocks awake: with an 18.7% hidden firing rate, almost every block has a neuron firing every timestep.
2. The proxy envelope is 8θ loose at 90 inputs per step.

Consequence: HUSH needs few active inputs per timestep (fine time bins, event data, deeper sparse layers) and sparse hidden firing. Next experiments test exactly that: activity-per-step sweep on MNIST (lower encoder rate, longer T), SHD and N-MNIST at fine time bins, and firing-rate regularisation.
