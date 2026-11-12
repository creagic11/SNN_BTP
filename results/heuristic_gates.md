# HUSH against heuristic gating predictors

Exploratory comparison (Table VI of the paper). The network, the 8-neuron sub-blocks and the mean-field drive of
sleeping sub-blocks are kept; only the predictor that decides whether a sub-block sleeps is replaced.
"Suppressed spikes" counts neurons in a sleeping sub-block whose ungated update from the same state would have
reached the threshold. Script: `scripts/heuristic_gates.py`.

## Comparison with charged predictor reads (11 November 2026; used in the paper)

Network: HUSH gentle, 12 epochs, seed 0 (trained with the HUSH gate, not with the heuristics); 1,000 test samples;
mean-field drive for sleeping sub-blocks in all cases; thresholds bisected on 100 calibration samples. Traffic =
bytes read from weight-related memories relative to BASE (8 B per weight column), with each predictor charged its
own reads: HUSH 2 B (P, Q) per sub-block and active input; SITRA-inspired 1 B (sign bits); Early-style the top-8
weight columns per sub-block before deciding (lower bound). Files: `heuristic_gates_reads.json`, `heuristic_gates_traffic.json`.

| Matched on | Predictor | Accuracy | Column reads | Traffic | Suppressed spikes |
| --- | --- | --- | --- | --- | --- |
| — | **HUSH** | **94.8 %** | 0.105 | 0.355 | **0** |
| column reads | Early-style (L(V) + top-8 active weights) | 92.4 % | 0.103 | 0.350 | 485 |
| column reads | SITRA-inspired (negative-weight count, state-free) | 68.1 % | 0.102 | 0.227 | 117,450 |
| traffic | Early-style | 93.6 % | 0.116 | 0.359 | 409 |
| traffic | SITRA-inspired | 87.4 % | 0.279 | 0.404¹ | 74,095 |

¹ the SITRA-inspired threshold is an integer count, so its traffic cannot be matched more closely (next step: 0.23).
This remains an exploratory test: only the predictor is swapped on a network trained for HUSH.

## Initial comparison (24 October 2026; superseded)

Read fractions matched without charging the predictors' own reads; 6-epoch networks; 200 N-MNIST and 150 SHD
samples.

Same networks (co-designed with HUSH-8/32 + mean-field), same 8-neuron sub-block granularity and the same mean-field semantics for sleeping neurons; only the predictor changes. Heuristic thresholds are bisected so their read fraction matches HUSH's. "Suppressed spikes" = neurons in a sleeping sub-block whose ungated update from the same state would have fired (false negatives). Script: `scripts/heuristic_gates.py`.

| Dataset (samples) | Gate | Accuracy | Reads vs BASE | Suppressed spikes |
| --- | --- | --- | --- | --- |
| N-MNIST (200) | **HUSH** | **95.5%** | 0.157 | **0** |
| | SITRA-style (negative-weight count < τ, state-free) | 66.0% | 0.149 | 15,121 |
| | Early-style (L(V) + top-8 active weights ≥ V_sth) | 93.5% | 0.153 | 36 |
| SHD (150) | **HUSH** | **70.7%** | 0.638 | **0** |
| | SITRA-style | 48.0% | 0.637 | 7,576 |
| | Early-style | 65.3% | 0.626 | 2 |

### Observations at the time

- HUSH is the only gate with zero false negatives, by construction (Theorem 1), and the best accuracy at equal savings on both datasets.
- The state-free SITRA-style predictor collapses: it ignores the membrane potential, so it puts neurons to sleep that are about to fire.
- The Early-style predictor is close in false negatives because it uses the membrane state and an importance-ordered partial sum. Two caveats favour HUSH: (1) its predictor reads the top-K weights of every neuron each step (up to K × 8 extra rows per sub-block), which this read count does not charge; (2) the networks were co-trained with the HUSH gate, so heuristic gates run on a network not adapted to them. A fully fair comparison trains each gate in the loop (future work, cost ~1 GPU-hour each).

