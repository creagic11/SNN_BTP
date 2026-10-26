#!/bin/bash
# P1.2: honest baselines under the validation protocol (10% held out, best-val checkpoint, clip 1).
cd "$(dirname "$0")/.."
base="--dataset shd --model rec --sizes 700 256 20 --T 250 --k 5 --lr 0.02 --drop 0.15 --readout umax --bs 64 --clip 1 --val_frac 0.1"
go() { tag=$1; shift; [ -f results/$tag/metrics.json ] && grep -q "\"epoch\": $EP," results/$tag/metrics.json && { echo "skip $tag"; return; }
       python3 train/train_snn.py $base "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
EP=20; go shd_rec_v --epochs 20
EP=30; go shd_rec_v_augm --epochs 30 --aug_shift 4 --aug_stretch 0.05 --aug_jitter 1
