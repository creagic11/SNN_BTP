#!/bin/bash
# Mean-field hibernation co-design on SHD T=250 (asleep neurons integrate the shared sub-block mean drive).
cd "$(dirname "$0")/.."
run() { tag=$1; shift; python3 train/train_snn.py --dataset shd --sizes 700 256 20 --T 250 --k 5 --epochs 15 \
        --init results/shd_T250/weights.npz --lr 0.02 --tag $tag "$@" > results/train_$tag.log 2>&1; echo "done $tag"; }
run shd_T250_mf_e2_d1    --gate_benv 8 --asleep_drive mean --exc_lam 2 --env_lam 1 --rate_target 0.05 --rate_lam 5
run shd_T250_mf_e05_d025 --gate_benv 8 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25 --rate_target 0.05 --rate_lam 5
