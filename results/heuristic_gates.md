# T1.5: HUSH vs heuristic output-skip gates at equal weight-read reduction

Same networks (co-designed with HUSH-8/32 + mean-field), same 8-neuron sub-block granularity and the same mean-field semantics for sleeping neurons; only the predictor changes. Heuristic thresholds are bisected so their read fraction matches HUSH's. "Suppressed spikes" = neurons in a sleeping sub-block whose ungated update from the same state would have fired (false negatives). Script: `scripts/heuristic_gates.py`.

| Dataset (samples) | Gate | Accuracy | Reads vs BASE | Suppressed spikes |
| --- | --- | --- | --- | --- |
| N-MNIST (200) | **HUSH** | **95.5%** | 0.157 | **0** |
| | SITRA-style (negative-weight count < τ, state-free) | 66.0% | 0.149 | 15,121 |
| | Early-style (L(V) + top-8 active weights ≥ V_sth) | 93.5% | 0.153 | 36 |
| SHD (150) | **HUSH** | **70.7%** | 0.638 | **0** |
| | SITRA-style | 48.0% | 0.637 | 7,576 |
| | Early-style | 65.3% | 0.626 | 2 |

## Reading it

- HUSH is the only gate with zero false negatives, by construction (Theorem 1), and the best accuracy at equal savings on both datasets.
- The state-free SITRA-style predictor collapses: it ignores the membrane potential, so it puts neurons to sleep that are about to fire.
- The Early-style predictor is close in false negatives because it uses the membrane state and an importance-ordered partial sum. Two caveats work in HUSH's favour and must be stated: (1) its predictor reads the top-K weights of every neuron each step (up to K × 8 extra rows per sub-block), which this read count does not charge; (2) the networks were co-trained with the HUSH gate, so heuristic gates run on a network not adapted to them. A fully fair comparison trains each gate in the loop (future work, cost ~1 GPU-hour each).
