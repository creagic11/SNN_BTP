#!/bin/bash
# P1.4: gated co-training of the recurrent adLIF SHD model (warm start from the ungated baseline).
cd "$(dirname "$0")/.."
INIT=${INIT:-results/shd_rec_v/weights.npz}
shd="--dataset shd --model rec --sizes 700 256 20 --T 250 --k 5 --readout umax --drop 0.15 --bs 64 --lr 0.01 --clip 1 --val_frac 0.1 --init $INIT --gate_benv 8 --rate_target 0.05 --rate_lam 5"
go() { tag=$1; shift; [ -f results/$tag/metrics.json ] && grep -q "\"epoch\": $EP," results/$tag/metrics.json && { echo "skip $tag"; return; }
       python3 train/train_snn.py "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
EP=12; go shd_rec_mf_e05_d025 $shd --epochs 12 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25
EP=12; go shd_rec_lr1_e05_d025 $shd --epochs 12 --asleep_drive lr1 --exc_lam 0.5 --env_lam 0.25
EP=12; go shd_rec_mf_e2_d1 $shd --epochs 12 --asleep_drive mean --exc_lam 2 --env_lam 1
