# Gate G0 report — feasibility of HUSH (24 Oct 2026)

**Decision: GO, with a narrowed scope.** HUSH pays off on event-driven workloads once the gate is trained in and sleeping neurons keep a shared mean drive. It does not pay off on rate-coded MNIST, which becomes a negative control in the paper.

## Headline numbers (single seed per point; error bars pending)

Reads = weight-BRAM column reads of the hidden layer relative to the dense baseline engine; cycles = hidden-layer cycle model with the overlapped envelope, PE pass and leak sweep. All gated results are bit-exact between the PyTorch trainer and the golden integer model.

| Dataset (network) | Configuration | Accuracy | Reads | Cycle speedup |
| --- | --- | --- | --- | --- |
| MNIST rate-coded (784-400-10, T 25) | baseline | 97.53% | 1.00 | 1.00× |
| | HUSH-8/32, any grouping | 97.8% (1k) | 0.96 | 1.00× |
| SHD (700-256-20, T 250) | baseline | 70.8% | 1.00 | 1.00× |
| | co-design, mean-field, gentle | **70.8%** | **0.64** | 1.04× |
| | co-design, mean-field, aggressive | 64.4% | 0.18 | 2.05× |
| N-MNIST (578-256-10, T 100) | baseline | 97.59% | 1.00 | 1.00× |
| | co-design, mean-field, gentle | **95.32%** | **0.155** | **2.17×** |
| | co-design, mean-field, aggressive | 92.72% | 0.058 | 3.86× |

## Against the gate criteria in the proposal

| Criterion | Status |
| --- | --- |
| G0: ORACLE ρ ≤ 0.6 and HUSH ρ ≤ 0.5 on ≥ 2 datasets | **Pass** on SHD and N-MNIST after co-design (HUSH ρ_sub 0.26 and 0.12); **fail** on rate-coded MNIST and on any untrained (ungated) network |
| G0: Early, SPARSH, C-STEP read | Done, plus SITRA, PS4 (`docs/literature/novelty_check.md`) |
| G1 preview: ρ ≤ 0.35 at ≤ 1 point loss on ≥ 2 datasets | SHD passes (0.26 at 0.0 points); N-MNIST needs a gentler point (0.12 at −2.3 points) |

## What we learned (and what changes in the design)

1. **The envelope only works with few active inputs per timestep.** The drive gap is about 1.4 σ_W per active input. At 90 inputs/step (rate-coded MNIST) it is 8 θ and nothing ever sleeps; at 27–32 inputs/step (SHD, N-MNIST, 3–4 ms bins) training brings it down to about 1 θ.
2. **Untrained networks give almost nothing.** Gating must be in the training loop, with an exceedance loss and an envelope-drive loss.
3. **Exact resync replaces the v1 carried bound.** The leak sweep already reads every sleeping neuron, so R_c is the exact max V each step and envelope error never accumulates (v1 could accumulate 2^k × per-step error).
4. **Dropping sub-threshold drive is the main accuracy cost** (control: an ungated network at the same low firing rate loses only ~1 point). **Mean-field hibernation** — sleeping neurons add the shared sub-block mean drive Q = floor(mean_i W_ij) ≤ P — fixes most of it at the cost of one more proxy table and one adder per sub-block, and keeps Theorem 1.
5. **Report work-weighted metrics.** Awake fraction per (block, timestep) overstates savings because silent timesteps are free anyway.
6. **Block-level cycle savings need aggressive settings**; column-gating energy savings come first. The paper's primary metric should be energy per inference, cycles secondary.

## Revised contribution list for the paper

1. A provably safe (no false negatives in exact mode) block envelope with exact resync, matched to RAMB36 columns.
2. Mean-field hibernation: sleeping neurons keep integrating a shared drive without fetching their weights.
3. Gate-in-the-loop co-design training (bit-exact with hardware) and the accuracy–energy Pareto front.
4. Measured FPGA silicon on SHD and N-MNIST, with rate-coded MNIST as a documented negative regime.

## Next (Phase 1, target G1 on 29 Nov)

- 3 seeds per Pareto point on SHD and N-MNIST (error bars).
- Gentler N-MNIST points to reach ≤ 1 point loss.
- Bin-size sweep (SHD T = 500/1000; N-MNIST T = 200) to test the "fewer inputs per step" lever.
- T1.5: SITRA-style and Early-style heuristic gates at equal read reduction — count false-negative spikes and accuracy.
- Energy model: convert column reads + cycles + envelope overhead into estimated dynamic energy before RTL.
