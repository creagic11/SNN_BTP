#!/bin/bash
# P1.2 ablation round 3: readout / logit scale / batch size (base: T=250, 700 ch, theta/4, drop 0.15, lr 0.02), 6 epochs.
cd "$(dirname "$0")/.."
common="--dataset shd --model rec --sizes 700 256 20 --T 250 --k 5 --lr 0.02 --drop 0.15 --epochs 6"
run() { tag=abl3_$1; shift; [ -f results/$tag/metrics.json ] && grep -q '"epoch": 6,' results/$tag/metrics.json && return
        python3 train/train_snn.py $common "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
run umax     --readout umax --bs 64
run us0625   --readout u --u_scale 0.0625 --bs 64
run us025    --readout u --u_scale 0.25 --bs 64
run bs128    --readout u --bs 128
