"""Integer-faithful SNN layers for training (PyTorch).

All quantities are kept in *integer units* so the trained network maps one-to-one onto the
golden model in golden/hush.py:

* weights: w_int = clamp(round(w), -128, 127)      (straight-through estimator)
* leak:    L(V)  = V - floor(V / 2**k)             (floor with straight-through gradient)
* soft reset, threshold theta (integer), surrogate gradient for the Heaviside step.

Every forward value is an exact integer stored in float32 (|x| < 2**24), so evaluating the trained
network in PyTorch and in the numpy golden REF model gives identical spikes.
"""

from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F


class RoundClampSTE(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x, lo, hi):
        return torch.clamp(torch.round(x), lo, hi)

    @staticmethod
    def backward(ctx, g):
        return g, None, None


class FloorSTE(torch.autograd.Function):
    @staticmethod
    def forward(ctx, x):
        return torch.floor(x)

    @staticmethod
    def backward(ctx, g):
        return g


class SpikeFn(torch.autograd.Function):
    """Heaviside forward, fast-sigmoid surrogate backward (slope in units of 1/theta)."""

    @staticmethod
    def forward(ctx, x, scale):
        ctx.save_for_backward(x)
        ctx.scale = scale
        return (x >= 0).to(x.dtype)

    @staticmethod
    def backward(ctx, g):
        (x,) = ctx.saved_tensors
        s = ctx.scale
        return g / (s * (1.0 + (x / s).abs()) ** 2), None


def leak(V, k: int):
    return V - FloorSTE.apply(V / (1 << k))


class QLinearLIF(nn.Module):
    """Fully connected LIF layer with INT8 fake-quantized weights, integer state, soft reset."""

    def __init__(self, n_in: int, n_out: int, theta: int = 64, k: int = 3,
                 wbits: int = 8, init_std: float | None = None, surrogate_scale: float | None = None):
        super().__init__()
        self.theta, self.k = theta, k
        self.lo, self.hi = -(1 << (wbits - 1)), (1 << (wbits - 1)) - 1
        std = init_std if init_std is not None else 2.0 * theta / (n_in ** 0.5)
        self.w = nn.Parameter(torch.randn(n_in, n_out) * std)
        self.sscale = surrogate_scale if surrogate_scale is not None else theta / 4

    def w_int(self):
        return RoundClampSTE.apply(self.w, self.lo, self.hi)

    gate_benv = 0          # >0: run HUSH envelope-gated dynamics with sub-blocks of this size
    theta_h = None         # gate threshold (None = theta, exact mode)
    asleep_drive = "none"  # "mean": asleep neurons integrate the sub-block mean drive (mean-field hibernation)

    def forward(self, S):
        """S: (T, B, n_in) spikes. Returns spikes (T, B, n_out) and pre-reset potentials U.

        With gate_benv > 0 the forward pass matches golden.hush.run_gated (resync=True): a sub-block
        whose envelope L(max V) + relu(sum_j s_j P_jc) is below theta_h drops this step's drive.
        Also records self.exceed (mean relu(E - theta_h)/theta, differentiable) and self.work
        (fraction of sub-block column reads kept, weighted by active inputs)."""
        T, B, _ = S.shape
        W = self.w_int()
        N = W.shape[1]
        V = torch.zeros(B, N, device=S.device)
        spikes, Us = [], []
        gb = self.gate_benv
        if gb:
            C = N // gb
            P = W.reshape(W.shape[0], C, gb).max(dim=2).values
            Q = FloorSTE.apply(W.reshape(W.shape[0], C, gb).sum(dim=2) / gb) if self.asleep_drive == "mean" else None
            th_h = self.theta if self.theta_h is None else self.theta_h
            exc, kept, tot = [], 0.0, 0.0
        for t in range(T):
            LV = leak(V, self.k)
            U = LV + S[t] @ W
            if gb:
                R = V.reshape(B, C, gb).max(dim=2).values
                E = leak(R, self.k) + torch.relu(S[t] @ P)
                g = (E >= th_h).detach()
                exc.append(torch.relu(E - th_h).mean() / self.theta)
                n_t = S[t].sum(dim=1, keepdim=True)
                kept += float((g.float() * n_t).sum())
                tot += float(n_t.sum()) * C
                gn = g.repeat_interleave(gb, dim=1).to(U.dtype)
                U_sleep = LV if Q is None else LV + (S[t] @ Q).repeat_interleave(gb, dim=1)
                U = gn * U + (1 - gn) * U_sleep
                s = SpikeFn.apply(U - self.theta, self.sscale) * gn
            else:
                s = SpikeFn.apply(U - self.theta, self.sscale)
            V = U - self.theta * s
            spikes.append(s)
            Us.append(U)
        if gb:
            self.exceed = torch.stack(exc).mean()
            self.work = kept / max(1.0, tot)
        return torch.stack(spikes), torch.stack(Us)


class QSNN(nn.Module):
    def __init__(self, sizes: list[int], theta: int = 64, k: int = 3):
        super().__init__()
        self.layers = nn.ModuleList(QLinearLIF(a, b, theta=theta, k=k) for a, b in zip(sizes[:-1], sizes[1:]))

    def forward(self, S):
        hidden = []
        for layer in self.layers:
            S, U = layer(S)
            hidden.append((S, U))
        return S, U, hidden

    def export_int(self):
        """Integer weights, shape (M, N) per layer, as numpy int64."""
        return [l.w_int().detach().cpu().numpy().astype("int64") for l in self.layers]


class QRecAdLIF(nn.Module):
    """Recurrent adaptive LIF layer, integer-faithful to golden.hush_rec.run_rec.

        z_t = [x_t ; s_{t-1}],  B = L_k(V) - w,  U = clamp(B + z Wc),  s = U >= theta,  V' = U - theta s
        w'  = clamp(L_kw(w) + floor(a V' / 2**sa) + b s)
    a (amin..amax) and b (0..bmax) are learned per-neuron integers (STE rounding).

    Stability: the subthreshold (V, w) map has Jacobian [[lam, -1], [c lam, mu - c]], c = a / 2**sa,
    lam = 1 - 2**-k, mu = 1 - 2**-kw, det = lam mu. Both eigenvalues lie inside the unit circle iff
    -c < (1 - lam)(1 - mu) = 2**-(k + kw); so any practical negative a is unstable (growth ~1.14 per
    step at a = -8, sa = 8, k = kw = 5) and gradients explode over T = 250. Default amin = 0."""

    def __init__(self, n_in: int, n_out: int, theta: int = 64, k: int = 5, kw: int = 5, sa: int = 8,
                 recurrent: bool = True, adapt: bool = True, amax: int = 32, bmax: int = 32, amin: int = 0,
                 vbits: int = 16, wbits_ad: int = 16, rec_std: float | None = None):
        super().__init__()
        self.theta, self.k, self.kw, self.sa = theta, k, kw, sa
        self.recurrent, self.adapt, self.amax, self.bmax, self.amin = recurrent, adapt, amax, bmax, amin
        self.vmin, self.vmax = -(1 << (vbits - 1)), (1 << (vbits - 1)) - 1
        self.wmin, self.wmax = -(1 << (wbits_ad - 1)), (1 << (wbits_ad - 1)) - 1
        self.w = nn.Parameter(torch.randn(n_in, n_out) * 2.0 * theta / n_in ** 0.5)
        if recurrent:
            self.wr = nn.Parameter(torch.randn(n_out, n_out) * (rec_std or 0.1 * theta / n_out ** 0.5))
        if adapt:
            self.a = nn.Parameter(torch.empty(n_out).uniform_(max(amin, -amax / 4), amax / 4))
            self.b = nn.Parameter(torch.empty(n_out).uniform_(0, bmax / 8))
        # theta/4 learns best (ablation 26 Oct: theta/4 82.1%, theta/2 59.8%, theta 64.9% at 6 epochs) even
        # though theta/2 bounds the reset-path factor (Lemma 3); see docs/theorem1_prime.md.
        self.sscale = theta / 4
        self.drop = 0.0
        self.detach_reset = False
        # per-neuron leak shifts (heterogeneous time constants); default homogeneous
        self.register_buffer("kv", torch.full((n_out,), float(k)))
        self.register_buffer("kwv", torch.full((n_out,), float(kw)))

    def set_heterogeneous(self, spread: int, seed: int = 0):
        """Draw per-neuron k in [k - spread, k + spread] and kw likewise (fixed, not learned)."""
        g = torch.Generator().manual_seed(seed)
        n = self.kv.numel()
        self.kv.copy_(torch.randint(self.k - spread, self.k + spread + 1, (n,), generator=g).float())
        self.kwv.copy_(torch.randint(self.kw - spread, self.kw + spread + 1, (n,), generator=g).float())  # stop the gradient through reset and spike-triggered adaptation

    gate_benv = 0
    theta_h = None
    asleep_drive = "none"
    signed_drive = True

    def W_int(self):
        W = RoundClampSTE.apply(self.w, -128, 127)
        if self.recurrent:
            W = torch.cat([W, RoundClampSTE.apply(self.wr, -128, 127)], 0)
        return W

    def ab_int(self, dev):
        if not self.adapt:
            z = torch.zeros(self.w.shape[1], device=dev)
            return z, z
        return RoundClampSTE.apply(self.a, self.amin, self.amax), RoundClampSTE.apply(self.b, 0, self.bmax)

    def forward(self, S):
        T, Bs, _ = S.shape
        Wc = self.W_int()
        N = Wc.shape[1]
        a, b = self.ab_int(S.device)
        V = torch.zeros(Bs, N, device=S.device)
        wad = torch.zeros(Bs, N, device=S.device)
        s = torch.zeros(Bs, N, device=S.device)
        gb = self.gate_benv
        if gb:
            C = Wc.shape[1] // gb
            P = Wc.reshape(Wc.shape[0], C, gb).max(dim=2).values
            Q = (FloorSTE.apply(Wc.reshape(Wc.shape[0], C, gb).sum(dim=2) / gb)
                 if self.asleep_drive == "mean" else None)
            # "lr1": rounded mean, clamped to the envelope drive bound D_c (golden asleep_drive="lr1")
            Qr = (RoundClampSTE.apply(Wc.reshape(Wc.shape[0], C, gb).sum(dim=2) / gb, -128, 127)
                  if self.asleep_drive == "lr1" else None)
            th_h = self.theta if self.theta_h is None else self.theta_h
            exc, kept, tot = [], 0.0, 0.0
        mask = None
        if self.training and self.drop > 0:
            mask = (torch.rand(Bs, N, device=S.device) >= self.drop).float() / (1 - self.drop)
        spikes, Us = [], []
        for t in range(T):
            z = torch.cat([S[t], s], 1) if self.recurrent else S[t]
            Bv = V - FloorSTE.apply(V / 2 ** self.kv) - wad
            U = torch.clamp(Bv + z @ Wc, self.vmin, self.vmax)
            if gb:
                Bmax = Bv.reshape(Bs, C, gb).max(dim=2).values
                D = z @ P
                lhs = torch.clamp(Bmax, self.vmin, self.vmax) + (D if self.signed_drive else torch.relu(D))
                g = ((lhs >= th_h) | (Bmax > self.vmax)).detach()
                exc.append(torch.relu(lhs - th_h).mean() / self.theta)
                n_t = z.sum(dim=1, keepdim=True)
                kept += float((g.float() * n_t).sum())
                tot += float(n_t.sum()) * C
                gn = g.repeat_interleave(gb, dim=1).to(U.dtype)
                if Q is not None:
                    U_sleep = torch.clamp(Bv + (z @ Q).repeat_interleave(gb, dim=1), self.vmin, self.vmax)
                elif Qr is not None:
                    A = torch.minimum(z @ Qr, D).repeat_interleave(gb, dim=1)
                    U_sleep = torch.clamp(Bv + A, self.vmin, self.vmax)
                else:
                    U_sleep = torch.clamp(Bv, self.vmin, self.vmax)
                U = gn * U + (1 - gn) * U_sleep
                s = SpikeFn.apply(U - self.theta, self.sscale) * gn
            else:
                s = SpikeFn.apply(U - self.theta, self.sscale)
            sr = s.detach() if self.detach_reset else s
            V = U - self.theta * sr
            if self.adapt:
                wad = torch.clamp(wad - FloorSTE.apply(wad / 2 ** self.kwv) + FloorSTE.apply(a * V / (1 << self.sa)) + b * sr,
                                  self.wmin, self.wmax)
            s_out = s if mask is None else s * mask
            spikes.append(s_out)
            Us.append(U)
            s = s_out if mask is None else s   # recurrence sees the undropped spikes
        if gb:
            self.exceed = torch.stack(exc).mean()
            self.work = kept / max(1.0, tot)
        return torch.stack(spikes), torch.stack(Us)


class QRSNN(nn.Module):
    """Recurrent adLIF hidden layers + non-recurrent LIF readout (QLinearLIF)."""

    def __init__(self, sizes: list[int], theta: int = 64, k: int = 5, kw: int = 5, sa: int = 8,
                 recurrent: bool = True, adapt: bool = True, k_out: int | None = None):
        super().__init__()
        hid = [QRecAdLIF(a, b, theta=theta, k=k, kw=kw, sa=sa, recurrent=recurrent, adapt=adapt)
               for a, b in zip(sizes[:-2], sizes[1:-1])]
        out = QLinearLIF(sizes[-2], sizes[-1], theta=theta, k=k if k_out is None else k_out)
        self.layers = nn.ModuleList(hid + [out])

    def forward(self, S):
        hidden = []
        for layer in self.layers:
            S, U = layer(S)
            hidden.append((S, U))
        return S, U, hidden

    def export_int(self):
        d = {}
        for i, l in enumerate(self.layers):
            d[f"W{i}"] = l.w_int().detach().cpu().numpy().astype("int64") if isinstance(l, QLinearLIF) \
                else RoundClampSTE.apply(l.w, -128, 127).detach().cpu().numpy().astype("int64")
            if isinstance(l, QRecAdLIF):
                if l.recurrent:
                    d[f"R{i}"] = RoundClampSTE.apply(l.wr, -128, 127).detach().cpu().numpy().astype("int64")
                a, b = l.ab_int("cpu")
                d[f"K{i}"] = l.kv.cpu().numpy().astype("int64")
                d[f"KW{i}"] = l.kwv.cpu().numpy().astype("int64")
                d[f"A{i}"] = a.detach().cpu().numpy().astype("int64")
                d[f"Bad{i}"] = b.detach().cpu().numpy().astype("int64")
        return d


class AxonDelay(nn.Module):
    """Learned per-input (axonal) delay, d_j in [0, dmax-1] steps: z_t[j] = x_{t - d_j}[j].

    Forward is always exact for hard delays (one-hot kernel at round(p_j)), so the trained network equals the
    integer golden model. Gradient w.r.t. the delay position p_j:
      * sigma > 0 ("gauss" phase, DCLS-style): forward uses a normalised Gaussian kernel of width sigma
        centred at p_j (soft, fractional inputs), annealed towards 0 by the trainer;
      * sigma == 0 ("hard" phase): forward one-hot, backward through a triangular interpolation kernel (STE).
    Events delayed past the last step are dropped (fixed T)."""

    def __init__(self, n: int, dmax: int, init: str = "uniform"):
        super().__init__()
        self.dmax = dmax
        p = torch.empty(n).uniform_(0, dmax - 1) if init == "uniform" else torch.zeros(n)
        self.pos = nn.Parameter(p)
        self.sigma = 0.0

    def d_int(self):
        return torch.clamp(torch.round(self.pos), 0, self.dmax - 1)

    def kernel(self):
        tau = torch.arange(self.dmax, dtype=self.pos.dtype, device=self.pos.device)[None, :]
        p = torch.clamp(self.pos, 0, self.dmax - 1)[:, None]
        if self.sigma > 0:
            K = torch.exp(-0.5 * ((tau - p) / self.sigma) ** 2)
            return K / K.sum(1, keepdim=True)
        hard = (tau == self.d_int()[:, None]).to(p.dtype)
        soft = torch.relu(1 - (tau - p).abs())
        return soft + (hard - soft).detach()

    def forward(self, S):
        T, B, M = S.shape
        K = self.kernel()                                       # (M, dmax), K[j, tau]
        x = S.permute(1, 2, 0)                                  # (B, M, T)
        x = F.pad(x, (self.dmax - 1, 0))
        z = F.conv1d(x, K.flip(-1)[:, None, :], groups=M)       # z[t] = sum_tau K[tau] x[t - tau]
        return z.permute(2, 0, 1)


class QDSNN(nn.Module):
    """Feed-forward integer LIF network with learned axonal delays before every layer (HUSH-friendly:
    no recurrence, no subthreshold adaptation). Hidden layers are QRecAdLIF(recurrent=False, adapt=False)."""

    def __init__(self, sizes: list[int], theta: int = 64, k: int = 2, dmax: int = 25, k_out: int | None = None):
        super().__init__()
        self.delays = nn.ModuleList(AxonDelay(n, dmax) for n in sizes[:-1])
        hid = [QRecAdLIF(a, b, theta=theta, k=k, recurrent=False, adapt=False) for a, b in zip(sizes[:-2], sizes[1:-1])]
        self.layers = nn.ModuleList(hid + [QLinearLIF(sizes[-2], sizes[-1], theta=theta, k=k if k_out is None else k_out)])

    def set_sigma(self, s: float):
        for d in self.delays:
            d.sigma = s

    def forward(self, S):
        hidden = []
        for dl, layer in zip(self.delays, self.layers):
            S, U = layer(dl(S))
            hidden.append((S, U))
        return S, U, hidden

    def export_int(self):
        d = {}
        for i, (dl, l) in enumerate(zip(self.delays, self.layers)):
            d[f"W{i}"] = (l.w_int() if isinstance(l, QLinearLIF) else RoundClampSTE.apply(l.w, -128, 127)
                          ).detach().cpu().numpy().astype("int64")
            d[f"D{i}"] = dl.d_int().detach().cpu().numpy().astype("int64")
        return d
