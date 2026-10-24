#!/bin/bash
# N-MNIST (2x17x17 = 578 inputs, T=100 bins over the first 300 ms): baseline, then mean-field co-design.
cd "$(dirname "$0")/.."
common="--dataset nmnist --sizes 578 256 10 --T 100 --k 4 --t_max 0.3 --bs 128"
python3 train/train_snn.py $common --epochs 10 --rate_target 0.05 --rate_lam 5 --tag nmnist_T100 > results/train_nmnist_T100.log 2>&1; echo done base
run() { tag=$1; shift; python3 train/train_snn.py $common --epochs 6 --init results/nmnist_T100/weights.npz --lr 0.02 \
        --tag $tag "$@" > results/train_$tag.log 2>&1; echo "done $tag"; }
run nmnist_T100_mf_e05_d025 --gate_benv 8 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25 --rate_target 0.05 --rate_lam 5
run nmnist_T100_mf_e2_d1    --gate_benv 8 --asleep_drive mean --exc_lam 2 --env_lam 1 --rate_target 0.05 --rate_lam 5
