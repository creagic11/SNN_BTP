#!/bin/bash
# P1.2: recurrent adLIF SHD baselines (one job at a time: 2 cores).
cd "$(dirname "$0")/.."
shd="--dataset shd --model rec --sizes 700 256 20 --T 250 --k 5 --readout u --bs 64 --lr 0.02"
go() { tag=$1; shift; [ -f results/$tag/metrics.json ] && grep -q "\"epoch\": $EP," results/$tag/metrics.json && { echo "skip $tag"; return; }
       python3 train/train_snn.py "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
EP=30; go shd_rec_T250 $shd --epochs 30
EP=30; go shd_rec_T250_d1_r05 $shd --epochs 30 --drop 0.1 --rate_target 0.05 --rate_lam 5
