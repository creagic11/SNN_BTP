#!/bin/bash
# Delay-SNN probes on full SHD (4 epochs each); one change at a time.
cd "$(dirname "$0")/.."
c="--dataset shd --model delay --pool 5 --T 100 --epochs 4 --bs 64 --lr 0.02 --lr_pos 0.1 --drop 0.4 --readout umax --clip 1"
run() { tag=dabl_$1; shift; [ -f results/$tag/metrics.json ] && grep -q '"epoch": 4,' results/$tag/metrics.json && return
        python3 train/train_snn.py $c "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
run nodelay_k2   --sizes 140 256 256 20 --k 2 --dmax 1
run delay_k2_s2  --sizes 140 256 256 20 --k 2 --dmax 25 --sigma0 2
run delay_k4_s2  --sizes 140 256 256 20 --k 4 --dmax 25 --sigma0 2
run delay_k2_hard --sizes 140 256 256 20 --k 2 --dmax 25 --sig_frac 0.0001
