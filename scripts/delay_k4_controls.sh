#!/bin/bash
# Disentangle accuracy loss: rate regulariser vs gating (k = 4 folded delay net, 15 epochs, val protocol).
cd "$(dirname "$0")/.."
c="--dataset shd --model delay --pool 5 --sizes 140 256 256 20 --T 100 --k 4 --dmax 25 --readout umax --bs 64 --lr 0.01 --lr_pos 0.02 --lr_bias 1.0 --sig_frac 0 --drop 0.4 --clip 1 --val_frac 0.1 --init results/shd_delay_fold_k4/weights.npz --epochs 15"
go() { tag=$1; shift; [ -f results/$tag/metrics.json ] && grep -q '"epoch": 15,' results/$tag/metrics.json && return
       python3 train/train_snn.py $c "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
go shd_delay_k4_nogate_rate05   --rate_target 0.05 --rate_lam 5
go shd_delay_k4_mf_e05_d025_norate --gate_benv 8 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25
