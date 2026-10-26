#!/bin/bash
# P1.2 ablation round 2 (base = round-1 winner: theta/4 surrogate, dropout 0.15, lr 0.02), 6 epochs each.
cd "$(dirname "$0")/.."
common="--dataset shd --model rec --readout u --bs 64 --lr 0.02 --drop 0.15 --epochs 6"
run() { tag=abl2_$1; shift; [ -f results/$tag/metrics.json ] && grep -q '"epoch": 6,' results/$tag/metrics.json && return
        python3 train/train_snn.py $common "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
run T100        --sizes 700 256 20 --T 100 --k 4 --kw 4
run T250p5      --sizes 140 256 20 --T 250 --k 5 --pool 5
run T100p5      --sizes 140 256 20 --T 100 --k 4 --kw 4 --pool 5
run T100p5h512  --sizes 140 512 20 --T 100 --k 4 --kw 4 --pool 5
