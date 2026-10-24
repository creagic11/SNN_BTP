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
                U = gn * U + (1 - gn) * LV
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
