#!/bin/bash
# T1.6: repeat runs (seeds 1, 2) for error bars, plus gentler N-MNIST points (seed 0).
cd "$(dirname "$0")/.."
shd="--dataset shd --sizes 700 256 20 --T 250 --k 5"
nm="--dataset nmnist --sizes 578 256 10 --T 100 --k 4 --t_max 0.3 --bs 128"
go() { tag=$1; shift; [ -f results/$tag/weights.npz ] && grep -q '"epoch"' results/train_$tag.log 2>/dev/null && [ "$(grep -c epoch results/train_$tag.log)" -ge "$EP" ] && { echo "skip $tag"; return; }
       python3 train/train_snn.py "$@" --tag $tag > results/train_$tag.log 2>&1; echo "done $tag"; }
EP=6;  for e in "0.25 0" "0.1 0"; do set -- $e; go nmnist_T100_mf_e${1}_d${2} $nm --epochs 6 --init results/nmnist_T100/weights.npz --lr 0.02 --gate_benv 8 --asleep_drive mean --exc_lam $1 --env_lam $2 --rate_target 0.05 --rate_lam 5; done
for s in 1 2; do
  EP=15; go shd_T250_mf_e05_d025_s$s $shd --epochs 15 --init results/shd_T250/weights.npz --lr 0.02 --seed $s --gate_benv 8 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25 --rate_target 0.05 --rate_lam 5
  EP=6;  go nmnist_T100_mf_e05_d025_s$s $nm --epochs 6 --init results/nmnist_T100/weights.npz --lr 0.02 --seed $s --gate_benv 8 --asleep_drive mean --exc_lam 0.5 --env_lam 0.25 --rate_target 0.05 --rate_lam 5
  EP=15; go shd_T250_mf_e2_d1_s$s $shd --epochs 15 --init results/shd_T250/weights.npz --lr 0.02 --seed $s --gate_benv 8 --asleep_drive mean --exc_lam 2 --env_lam 1 --rate_target 0.05 --rate_lam 5
done
for s in 1 2; do
  EP=25; go shd_T250_s$s $shd --epochs 25 --seed $s --rate_target 0.05 --rate_lam 5
  EP=10; go nmnist_T100_s$s $nm --epochs 10 --seed $s --rate_target 0.05 --rate_lam 5
done
