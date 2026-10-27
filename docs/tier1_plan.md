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

## Update 27 Oct 2026 — outcome of P1 and the scope decision

**Gate GA (22 Nov) will not be met as written.** Best SHD results under the validation protocol:

| SHD network | Test accuracy |
| --- | --- |
| Feed-forward + learned axonal delays (INT8, folded) | 87.4% |
| Recurrent adLIF | 83.1% |

On the high-accuracy SHD networks, gating costs accuracy:

| Network | Reads | Accuracy cost |
| --- | --- | --- |
| Recurrent adLIF | 0.98 | — |
| Delay net, k = 2 | ≥ 0.94 | — |
| Delay net, k = 4 | 0.77 | 6.7 pt |

The cause is understood and written up in `docs/headroom_model.md`: HUSH sleeps only when hyperpolarisation headroom exceeds the step's drive bound, and these networks keep neurons near threshold.

**Decision (user, 27 Oct):**

- **Paper A (tier-2, now).** The guarantee, the headroom theory, measured hardware (N-MNIST) and a full comparison against the state of the art. Target: TCAS-II or DATE.
- **Paper B (tier-1, when a GPU is available).** Extend Paper A with conv layers, DVS-Gesture and the multi-array engine. Target: ICCAD 2027 or TCAD.
- **GPU-independent work comes first.** Paper A tasks A1–A8 and Paper B tasks B1–B4 are tracked in `progress.md`.

**Done since:**

- Vivado 2024.1 P&R of all three variants meets 100 MHz on the XC7A100T (`results/vivado_2024_1/`).
- Comparison report v1: https://claude.ai/artifact/PHRvGNYWhkn9HiMooEmfsR

| Gate | Revised status |
| --- | --- |
| GA (SHD ≥ 90%, ≤ 0.5 pt at ≥ 2× fewer reads) | not met; replaced by the headroom result in Paper A |
| GB (RTL for adLIF / recurrence / low-rank) | deferred: those networks do not gate; FF/delay RTL is what Paper A needs (delay line = ring buffer, not built yet) |
| GC (Vivado ≥ 100 MHz, measured energy, Spiker+) | partly met: 100 MHz met (A1); SAIF power (A3), Spiker+ (A4) and board (A7) open |
| GD (multi-array engine) | moved to Paper B (B3) |
| GE (DVS-Gesture) | Paper B (B2), needs a GPU |
