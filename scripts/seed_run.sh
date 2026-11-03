#!/bin/bash
# A5: one training run, resumable at run level (skips a tag whose metrics.json already holds all epochs).
# usage: seed_run.sh <seed> ungated|e05_d025|e2_d1|all   (all = the three runs of one seed in order, ~55 min)
cd "$(dirname "$0")/.."
export PYTHONUNBUFFERED=1   # one run at a time on both cores (two 1-thread runs in parallel were ~10x slower per epoch)
s=$1; kind=$2
if [ "$kind" = all ]; then for k in ungated e05_d025 e2_d1; do "$0" $s $k || exit 1; done; exit 0; fi
nm="--dataset nmnist --sizes 578 256 10 --T 100 --k 4 --t_max 0.3 --bs 128"
done_ep() { python3 -c "import json,sys;m=json.load(open('results/$1/metrics.json'));print(len(m['log']))" 2>/dev/null || echo 0; }
if [ "$kind" = ungated ]; then tag=nmnist_T100_s$s; ep=10
  [ "$(done_ep $tag)" -ge $ep ] && { echo "skip $tag"; exit 0; }
  python3 -u train/train_snn.py $nm --epochs $ep --seed $s --rate_target 0.05 --rate_lam 5 --tag $tag > results/train_$tag.log 2>&1
else tag=nmnist_T100_mf_${kind}_s$s; ep=6
  [ "$(done_ep $tag)" -ge $ep ] && { echo "skip $tag"; exit 0; }
  case $kind in e05_d025) exc=0.5; env=0.25;; e2_d1) exc=2; env=1;; esac
  python3 -u train/train_snn.py $nm --epochs $ep --init results/nmnist_T100_s$s/weights.npz --lr 0.02 --seed $s --gate_benv 8 \
    --asleep_drive mean --exc_lam $exc --env_lam $env --rate_target 0.05 --rate_lam 5 --tag $tag > results/train_$tag.log 2>&1
fi
echo "done $tag rc=$? $(date)"
