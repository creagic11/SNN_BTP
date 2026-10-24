#!/bin/bash
# Pareto sweep of gate-in-the-loop co-design on SHD T=250 (warm start from the ungated baseline).
cd "$(dirname "$0")/.."
run() { tag=$1; shift; python3 train/train_snn.py --dataset shd --sizes 700 256 20 --T 250 --k 5 --epochs 15 \
        --init results/shd_T250/weights.npz --lr 0.02 --tag $tag "$@" > results/train_$tag.log 2>&1; echo "done $tag"; }
run shd_T250_g_e05_d025 --gate_benv 8 --exc_lam 0.5 --env_lam 0.25 --rate_target 0.05 --rate_lam 5
run shd_T250_g_e025    --gate_benv 8 --exc_lam 0.25 --rate_target 0.05 --rate_lam 5
run shd_T250_ungated_r013 --rate_target 0.013 --rate_lam 20
run shd_T250_g_e0       --gate_benv 8 --rate_target 0.05 --rate_lam 5
