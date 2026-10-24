# Plan to reach tier-1 (25 Oct 2026)

Full plan (live): Claude Doc "HUSH — Plan to Reach Tier-1" — https://claude.ai/artifact/Ed78e68mpQkHAgKpNrrtAa

## Four changes
1. Competitive workloads: recurrent adaptive-LIF SHD (target ≥ 90%), conv SNN on DVS-Gesture (needs GPU).
2. Near-lossless gating: learned grouping during gated training, low-rank hibernation (mean-field = rank 1), distillation; target ≤ 0.5 pt at ≥ 3× fewer reads.
3. Scalable engine: multi-array with dynamic awake-block queue; pipelined leak sweep; cheaper envelope unit; tri-sparse (input × N:M weight × output state).
4. Measured evidence: Vivado P&R, SAIF ≥ 100 samples, board ΔP, same-topology Spiker+, comparison table, 3 seeds, ablations.
Plus: analytic model of when gating pays; formal proof extended to adLIF, recurrence, low-rank clamp, dispatcher.

## Gates
| Gate | Date | Criterion |
| --- | --- | --- |
| GA | 22 Nov 2026 | SHD adLIF ≥ 90% ungated; HUSH ≤ 0.5 pt at ≥ 2× fewer reads (3 seeds) |
| GB | 20 Dec 2026 | RTL (adLIF, recurrence, low-rank, sweep) bit-exact; proof extended |
| GC | 3 Jan 2027 | WNS ≥ 0 @100 MHz; measured energy ≥ 2× BASE; beats same-topology Spiker+ |
| GD | 31 Jan 2027 | 4-array ≥ 3× one-array throughput; tri-sparse ablation |
| GE | 14 Feb 2027 | DVS-Gesture conv ≥ 93%, ≤ 1 pt lost (conditional on GPU) |

Targets: ICCAD 2027 or IEEE TCAD (full paper, ~Apr 2027); TCAS-II brief in Jan 2027 as insurance.
