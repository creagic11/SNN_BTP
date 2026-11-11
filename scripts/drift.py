"""Review point "provably safe": per-timestep safety vs whole-recording equivalence, measured (11 Nov 2026).

For each gated point (seed 0) over n test samples:
  (A) same-state safety: spikes the ungated update from HUSH's own state would emit but HUSH suppresses
      (golden shadow mode, U_ungated >= theta while HUSH did not spike) -> must be 0;
  (B) trajectory drift vs the same weights run ungated from the start: fraction of hidden-layer spike bits that
      differ, first timestep of divergence, and agreement of the final class.
    python scripts/drift.py --n 1000  -> results/drift.json
"""
import argparse, json, sys
from pathlib import Path
import numpy as np
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from golden.hush import LIFParams, LayerTrace, predict, run_gated, run_ref  # noqa: E402
from scripts.measure_rho import pad_hidden, test_rasters  # noqa: E402
P = {"gentler 12ep": "nmnist_T100_mf_e025_d01_ep12", "gentle 12ep": "nmnist_T100_mf_e05_d025_ep12",
     "aggressive": "nmnist_T100_mf_e2_d1"}

def cls(o, nout):
    return predict(LayerTrace(spikes=o.spikes[:, :nout], V=o.V[:, :nout], U=o.U[:, :nout], awake_sub=o.awake_sub,
                              awake_blk=o.awake_blk, n_active=o.n_active))

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--n", type=int, default=1000); a = ap.parse_args()
    res = {}
    for name, tag in P.items():
        z = np.load(ROOT / "results" / tag / "weights.npz")
        W1, W2, _ = pad_hidden(z["W0"].astype(np.int64), z["W1"].astype(np.int64), 32)
        nout = W2.shape[1]
        pg = LIFParams(k=4, theta=64, b_env=8, b_blk=32, asleep_drive="mean")
        pr = LIFParams(k=4, theta=64, b_env=8, b_blk=32)
        R, Y = test_rasters(z, a.n)
        supp = tot_g = tot_r = diffbits = bits = same_cls = acc_g = acc_r = 0
        first = []
        for S, y in zip(R, Y):
            h = run_gated(W1, S, pg, shadow=True)
            r = run_ref(W1, S, pr)
            supp += int(((h.U_ungated >= 64) & (h.spikes == 0)).sum())
            tot_g += int(h.spikes.sum()); tot_r += int(r.spikes.sum())
            d = h.spikes != r.spikes
            diffbits += int(d.sum()); bits += d.size
            t = np.flatnonzero(d.any(1)); first.append(int(t[0]) if len(t) else S.shape[0])
            cg = cls(run_ref(W2, h.spikes.astype(np.int64), pr), nout)
            cr = cls(run_ref(W2, r.spikes.astype(np.int64), pr), nout)
            same_cls += cg == cr; acc_g += cg == y; acc_r += cr == y
        n = len(Y)
        res[name] = {"n": n, "suppressed_vs_same_state": supp, "hidden_spikes_gated": tot_g / n,
                     "hidden_spikes_ungated_same_weights": tot_r / n,
                     "spike_bits_differing_pct": 100 * diffbits / bits,
                     "first_divergence_window_median": float(np.median(first)),
                     "same_class_pct": 100 * same_cls / n, "acc_gated": acc_g / n, "acc_ungated_same_weights": acc_r / n}
        print(name, json.dumps(res[name]), flush=True)
    json.dump(res, open(ROOT / "results" / "drift.json", "w"), indent=1)

if __name__ == "__main__":
    main()
