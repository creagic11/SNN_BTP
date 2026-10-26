#!/bin/bash
# P1.4 (delay path): gated co-training from the folded integer delay network (warm start), validation protocol.
cd "$(dirname "$0")/.."
INIT=${INIT:-results/shd_delay_fold/weights.npz}
K=${K:-2}; SUF=${SUF:-}
c="--dataset shd --model delay --pool 5 --sizes 140 256 256 20 --T 100 --k $K --dmax 25 --readout umax --bs 64 --lr 0.01 --lr_pos 0.02 --lr_bias 1.0 --sig_frac 0 --drop 0.4 --clip 1 --val_frac 0.1 --init $INIT --gate_benv 8 --rate_target 0.05 --rate_lam 5"
go() { tag=$1; shift; [ -f results/$tag/metrics.json ] && grep -q "\"epoch\": $EP," results/$tag/metrics.json && { echo "skip $tag"; return; }
       python3 train/train_snn.py $c "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
EP=15; go shd_delay${SUF}_mf_e05_d025 --epochs 15 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25
EP=15; go shd_delay${SUF}_mf_e2_d1    --epochs 15 --asleep_drive mean --exc_lam 2 --env_lam 1
EP=15; go shd_delay${SUF}_drop_e05_d025 --epochs 15 --asleep_drive none --exc_lam 0.5 --env_lam 0.25
