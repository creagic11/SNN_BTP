#!/bin/bash
# A6 (accuracy push, 3 Nov 2026): run-level resumable trainings. usage: a6_run.sh gentler|longer|gentler12|h384|h384_gentle|first|second
cd "$(dirname "$0")/.."; export PYTHONUNBUFFERED=1
TH=${A6_THREADS:-1}
nm="--dataset nmnist --T 100 --k 4 --t_max 0.3 --bs 128 --threads $TH"
done_ep() { python3 -c "import json;m=json.load(open('results/$1/metrics.json'));print(len(m['log']))" 2>/dev/null || echo 0; }
g() { tag=$1; ep=$2; shift 2; [ "$(done_ep $tag)" -ge $ep ] && { echo "skip $tag"; return 0; }
      python3 -u train/train_snn.py $nm --epochs $ep --tag $tag "$@" > results/train_$tag.log 2>&1; echo "done $tag rc=$? $(date)"; }
gate="--lr 0.02 --gate_benv 8 --asleep_drive mean --rate_target 0.05 --rate_lam 5"
case $1 in
  gentler)     g nmnist_T100_mf_e025_d01 6  --sizes 578 256 10 --init results/nmnist_T100/weights.npz $gate --exc_lam 0.25 --env_lam 0.1 ;;
  longer)      g nmnist_T100_mf_e05_d025_ep12 12 --sizes 578 256 10 --init results/nmnist_T100/weights.npz $gate --exc_lam 0.5 --env_lam 0.25 ;;
  h384)        g nmnist_T100_h384 10 --sizes 578 384 10 --rate_target 0.05 --rate_lam 5 ;;
  h384_gentle) g nmnist_T100_h384_mf_e05_d025 6 --sizes 578 384 10 --init results/nmnist_T100_h384/weights.npz $gate --exc_lam 0.5 --env_lam 0.25 ;;
  gentler12)   g nmnist_T100_mf_e025_d01_ep12 12 --sizes 578 256 10 --init results/nmnist_T100/weights.npz $gate --exc_lam 0.25 --env_lam 0.1 ;;
  first)  "$0" gentler && "$0" longer ;;
  second) "$0" h384 && "$0" h384_gentle ;;
esac
