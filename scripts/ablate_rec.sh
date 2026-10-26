#!/bin/bash
# P1.2 controlled ablation: one change at a time from the plain recurrent adLIF recipe, 6 epochs each.
cd "$(dirname "$0")/.."
base="--dataset shd --model rec --sizes 700 256 20 --T 250 --k 5 --readout u --bs 64 --lr 0.02 --epochs 6"
run() { tag=abl_$1; shift; [ -f results/$tag/metrics.json ] && grep -q '"epoch": 6,' results/$tag/metrics.json && return
        python3 train/train_snn.py $base "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
run base   --sscale_div 4
run s2     --sscale_div 2
run s1     --sscale_div 1
run het    --sscale_div 4 --het 2
run drop   --sscale_div 4 --drop 0.15
run lr01   --sscale_div 4 --lr 0.01
