"""Generic trainer for the ungated INT8 LIF baselines (MNIST, SHD, N-MNIST) with firing-rate control.

    python train/train_snn.py --dataset shd --sizes 700 256 20 --T 250 --k 5 --epochs 20 \
        --rate_target 0.05 --rate_lam 20 --tag shd_T250

Writes results/<tag>/weights.npz (+ metrics.json). Weights are INT8, all arithmetic integer-faithful.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from train.qsnn import QRSNN, QSNN  # noqa: E402
from train.train_mnist import if_encode_torch, predict_torch  # noqa: E402


class Data:
    def __init__(self, name, T, gain=1, limit=0, t_max=1.0, pool=2):
        self.name, self.T, self.gain = name, T, gain
        if name == "mnist":
            from golden.datasets import mnist_arrays
            Xtr, Ytr = mnist_arrays(True)
            Xte, Yte = mnist_arrays(False)
            self.tr = (torch.tensor(Xtr), torch.tensor(Ytr))
            self.te = (torch.tensor(Xte), torch.tensor(Yte))
        elif name == "shd":
            from golden.datasets import SHD
            self.str_, self.ste = SHD(True, t_max), SHD(False, t_max)
            self.tr = (None, torch.tensor(self.str_.labels))
            self.te = (None, torch.tensor(self.ste.labels))
        elif name == "nmnist":
            self.tr = self._nmnist_cache(True, pool, t_max)
            self.te = self._nmnist_cache(False, pool, t_max)
        if limit:
            self.tr = tuple(x[:limit] if x is not None else None for x in self.tr)

    def _nmnist_cache(self, train, pool, t_max):
        from golden.datasets import NMNIST
        p = ROOT / "data_cache" / f"nmnist_{'tr' if train else 'te'}_T{self.T}_p{pool}_t{int(t_max * 1e6)}.npz"
        if p.exists():
            z = np.load(p)
            return torch.tensor(z["X"]), torch.tensor(z["Y"])
        ds = NMNIST(train, int(t_max * 1e6), pool)
        X, Y = [], []
        for i in range(len(ds)):
            r, y = ds.raster(i, self.T)
            X.append(np.packbits(r, axis=1))
            Y.append(y)
        X, Y = np.stack(X), np.array(Y)
        p.parent.mkdir(exist_ok=True)
        np.savez(p, X=X, Y=Y, M=ds.M)
        return torch.tensor(X), torch.tensor(Y)

    @property
    def M(self):
        return {"mnist": 784, "shd": 700}.get(self.name) or 578

    def n(self, train):
        return len((self.tr if train else self.te)[1])

    def batch(self, idx, train):
        X, Y = self.tr if train else self.te
        if self.name == "mnist":
            S = if_encode_torch(X[idx], self.T, self.gain)
        elif self.name == "shd":
            ds = self.str_ if train else self.ste
            S = torch.tensor(ds.batch(idx.tolist(), self.T)).float().transpose(0, 1)
        else:
            S = torch.tensor(np.unpackbits(X[idx].numpy(), axis=2)[:, :, :self.M]).float().transpose(0, 1)
        return S, Y[idx]


def envelope_drive_loss(model, S, hid, benv, theta):
    """Expected positive drive bound per timestep, in units of theta, averaged over sub-blocks and
    hidden layers: mean_c sum_j r_j * relu(max_{i in c} W_ij) / theta, with r_j the input firing rate
    of that layer in this batch. Gradient reaches the arg-max neuron of each (j, c): it shrinks the
    largest positive weight in each sub-block, which is exactly what loosens the HUSH envelope."""
    terms = []
    inp = S
    for li, layer in enumerate(model.layers[:-1]):
        if hasattr(layer, "W_int"):                        # recurrent adLIF: rows = [inputs; own spikes]
            W = layer.W_int()
            r = inp.detach().mean(dim=(0, 1))
            if layer.recurrent:
                r = torch.cat([r, hid[li][0].detach().mean(dim=(0, 1))])
        else:
            W = layer.w_int()                              # (M, N) integer values, STE gradient
            r = inp.detach().mean(dim=(0, 1))              # (M,) firing probability per input
        M, N = W.shape
        P = W.reshape(M, N // benv, benv).max(dim=2).values
        terms.append((r[:, None] * F.relu(P)).sum(0).mean() / theta)
        inp = hid[li][0]
    return torch.stack(terms).mean()


U_THETA = 1 << 14   # output threshold for the non-spiking readout (never reached in practice; checked)


def readout_logits(So, Uo, a):
    if a.readout == "u":
        return Uo.mean(0) / a.theta * a.u_scale
    return (So.sum(0) + 0.01 * Uo.mean(0) / a.theta) * (25.0 / a.T)


def predict_any(So, Uo, readout):
    if readout == "u":
        return Uo.sum(0).argmax(dim=1)
    return predict_torch(So, Uo)


def evaluate(model, data, bs=500):
    model.eval()
    correct, rh, n, wk = 0, 0.0, data.n(False), 0.0
    with torch.no_grad():
        for i in range(0, n, bs):
            idx = torch.arange(i, min(n, i + bs))
            S, Y = data.batch(idx, False)
            So, Uo, hid = model(S)
            correct += (predict_any(So, Uo, getattr(model, "readout", "spk")) == Y).sum().item()
            rh += hid[0][0].mean().item() * len(idx)
            if model.layers[0].gate_benv:
                wk += np.mean([l.work for l in model.layers[:-1]]) * len(idx)
    model.eval_read_frac = wk / n
    return correct / n, rh / n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dataset", default="shd", choices=["mnist", "shd", "nmnist"])
    ap.add_argument("--sizes", type=int, nargs="+", default=[700, 256, 20])
    ap.add_argument("--T", type=int, default=250)
    ap.add_argument("--k", type=int, default=5)
    ap.add_argument("--theta", type=int, default=64)
    ap.add_argument("--gain", type=int, default=1)
    ap.add_argument("--t_max", type=float, default=1.0)
    ap.add_argument("--epochs", type=int, default=20)
    ap.add_argument("--bs", type=int, default=64)
    ap.add_argument("--lr", type=float, default=0.05)
    ap.add_argument("--rate_target", type=float, default=0.0)
    ap.add_argument("--rate_lam", type=float, default=0.0)
    ap.add_argument("--env_lam", type=float, default=0.0, help="weight of the envelope drive loss")
    ap.add_argument("--env_benv", type=int, default=8)
    ap.add_argument("--gate_benv", type=int, default=0, help="train with HUSH-gated dynamics in hidden layers")
    ap.add_argument("--asleep_drive", default="none", choices=["none", "mean", "lr1"])
    ap.add_argument("--exc_lam", type=float, default=0.0, help="weight of the envelope exceedance loss")
    ap.add_argument("--init", default="", help="initialise from a weights.npz")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--tag", default="")
    ap.add_argument("--model", default="ff", choices=["ff", "rec"], help="rec: recurrent adLIF hidden layers")
    ap.add_argument("--no_rec", action="store_true", help="rec model without recurrent weights")
    ap.add_argument("--no_adapt", action="store_true", help="rec model without adaptation")
    ap.add_argument("--kw", type=int, default=5)
    ap.add_argument("--sa", type=int, default=8)
    ap.add_argument("--drop", type=float, default=0.0, help="dropout on hidden spikes (training only)")
    ap.add_argument("--readout", default="spk", choices=["spk", "u"],
                    help="u: non-spiking readout, class = argmax sum_t U (output theta set out of reach)")
    ap.add_argument("--k_out", type=int, default=0)
    ap.add_argument("--u_scale", type=float, default=0.125, help="logit scale for the u readout")
    ap.add_argument("--signed_drive", type=int, default=1)
    ap.add_argument("--threads", type=int, default=2)
    ap.add_argument("--clip", type=float, default=0.0, help="gradient-norm clip (0 = off)")
    ap.add_argument("--het", type=int, default=0, help="per-neuron leak shifts k +- het, kw +- het")
    ap.add_argument("--detach_reset", action="store_true")
    ap.add_argument("--log_grad", action="store_true", help="log per-batch grad norms; checkpoint at the first spike")
    ap.add_argument("--sscale_div", type=float, default=0.0, help="surrogate scale = theta / div (0: layer default)")
    a = ap.parse_args()
    torch.manual_seed(a.seed)
    data = Data(a.dataset, a.T, a.gain, a.limit, a.t_max)
    torch.set_num_threads(a.threads)
    if a.model == "rec":
        model = QRSNN(a.sizes, theta=a.theta, k=a.k, kw=a.kw, sa=a.sa, recurrent=not a.no_rec,
                      adapt=not a.no_adapt, k_out=a.k_out or None)
    else:
        model = QSNN(a.sizes, theta=a.theta, k=a.k)
    if a.readout == "u":
        model.layers[-1].theta = U_THETA
    model.readout = a.readout
    for layer in model.layers[:-1]:
        layer.gate_benv = a.gate_benv
        layer.asleep_drive = a.asleep_drive
        layer.signed_drive = bool(a.signed_drive)
        layer.drop = a.drop
        if hasattr(layer, "detach_reset"):
            layer.detach_reset = a.detach_reset
        if a.sscale_div:
            layer.sscale = a.theta / a.sscale_div
        if a.het and hasattr(layer, "set_heterogeneous"):
            layer.set_heterogeneous(a.het, a.seed)
    if a.init:
        z0 = np.load(a.init)
        with torch.no_grad():
            for i, layer in enumerate(model.layers):
                layer.w.copy_(torch.tensor(z0[f"W{i}"].astype(np.float32)))
                for key, attr in ((f"R{i}", "wr"), (f"A{i}", "a"), (f"Bad{i}", "b"), (f"K{i}", "kv"), (f"KW{i}", "kwv")):
                    if key in z0 and hasattr(layer, attr):
                        getattr(layer, attr).copy_(torch.tensor(z0[key].astype(np.float32)))
    opt = torch.optim.Adam(model.parameters(), lr=a.lr)
    ntr = data.n(True)
    steps = a.epochs * ((ntr + a.bs - 1) // a.bs)
    sched = torch.optim.lr_scheduler.OneCycleLR(opt, max_lr=a.lr, total_steps=steps, pct_start=0.15)
    out = ROOT / "results" / (a.tag or f"{a.dataset}_T{a.T}")
    out.mkdir(parents=True, exist_ok=True)
    log = []
    for ep in range(a.epochs):
        model.train()
        perm = torch.randperm(ntr)
        t0, tot, n = time.time(), 0.0, 0
        for i in range(0, ntr, a.bs):
            idx = perm[i:i + a.bs]
            S, Y = data.batch(idx, True)
            So, Uo, hid = model(S)
            logits = readout_logits(So, Uo, a)
            loss = F.cross_entropy(logits, Y)
            if a.rate_lam:
                rate = torch.stack([h[0].mean() for h in hid[:-1]]).mean()
                loss = loss + a.rate_lam * F.relu(rate - a.rate_target)
            if a.exc_lam and a.gate_benv:
                loss = loss + a.exc_lam * torch.stack([l.exceed for l in model.layers[:-1]]).mean()
            if a.env_lam:
                loss = loss + a.env_lam * envelope_drive_loss(model, S, hid, a.env_benv, a.theta)
            opt.zero_grad()
            loss.backward()
            if a.log_grad:
                gn = {n: float(p.grad.norm()) for n, p in model.named_parameters() if p.grad is not None}
                tot_g = sum(v * v for v in gn.values()) ** 0.5
                hist = getattr(model, "_ghist", [])
                med = float(np.median(hist[-200:])) if hist else tot_g
                hist.append(tot_g)
                model._ghist = hist
                if len(hist) > 50 and tot_g > 50 * med and not getattr(model, "_spiked", False):
                    model._spiked = True
                    torch.save({"state": model.state_dict(), "idx": idx}, out / "spike_ckpt.pt")
                    print(json.dumps({"grad_spike": True, "epoch": ep + 1, "batch": i // a.bs, "total": tot_g,
                                      "median": med, "per_param": gn, "loss": loss.item()}), flush=True)
                if (i // a.bs) % 32 == 0:
                    print(json.dumps({"ep": ep + 1, "b": i // a.bs, "loss": round(loss.item(), 3),
                                      "gnorm": round(tot_g, 4)}), flush=True)
            if a.clip:
                torch.nn.utils.clip_grad_norm_(model.parameters(), a.clip)
            opt.step()
            sched.step()
            tot += loss.item() * len(idx)
            n += len(idx)
        acc, rate = evaluate(model, data)
        rec = {"epoch": ep + 1, "loss": tot / n, "test_acc": acc, "hidden_rate": rate, "sec": round(time.time() - t0, 1)}
        if a.gate_benv:
            rec["read_frac"] = float(model.eval_read_frac)
        if a.env_lam:
            with torch.no_grad():
                S0, _ = data.batch(torch.arange(min(256, data.n(False))), False)
                _, _, h0 = model(S0)
                rec["env_drive_theta"] = float(envelope_drive_loss(model, S0, h0, a.env_benv, a.theta))
        log.append(rec)
        print(json.dumps(rec), flush=True)
        Ws = model.export_int()
        if isinstance(Ws, list):
            Ws = {f"W{i}": W for i, W in enumerate(Ws)}
        Ws = {key: (v.astype(np.int8) if key[0] in "WR" or key.startswith("K") else v.astype(np.int16)) for key, v in Ws.items()}
        np.savez(out / "weights.npz", **Ws, T=a.T, k=a.k, theta=a.theta, gain=a.gain, dataset=a.dataset,
                 t_max=a.t_max, model=a.model, kw=a.kw, sa=a.sa, readout=a.readout,
                 k_out=a.k_out or a.k, out_theta=model.layers[-1].theta)
        json.dump({"args": vars(a), "log": log}, open(out / "metrics.json", "w"), indent=2)
    print("saved", out)


if __name__ == "__main__":
    main()
