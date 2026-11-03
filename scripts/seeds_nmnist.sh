#!/bin/bash
# A5 (3 Nov 2026): seeds 1 and 2 for the three N-MNIST points (seed 0 = results/nmnist_T100{,_mf_e05_d025,_mf_e2_d1}).
# Each gated point fine-tunes from the ungated net of the SAME seed. Two seeds run in parallel, one thread each.
cd "$(dirname "$0")/.."
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
nm="--dataset nmnist --sizes 578 256 10 --T 100 --k 4 --t_max 0.3 --bs 128"
seed() { s=$1
  python3 train/train_snn.py $nm --epochs 10 --seed $s --rate_target 0.05 --rate_lam 5 --tag nmnist_T100_s$s > results/train_nmnist_T100_s$s.log 2>&1
  for e in "0.5 0.25 e05_d025" "2 1 e2_d1"; do set -- $e
    python3 train/train_snn.py $nm --epochs 6 --init results/nmnist_T100_s$s/weights.npz --lr 0.02 --seed $s --gate_benv 8 \
      --asleep_drive mean --exc_lam $1 --env_lam $2 --rate_target 0.05 --rate_lam 5 --tag nmnist_T100_mf_$3_s$s > results/train_nmnist_T100_mf_$3_s$s.log 2>&1
  done
  echo "seed $s done $(date)"
}
seed 1 & seed 2 & wait
echo "A5 trainings done $(date)"
