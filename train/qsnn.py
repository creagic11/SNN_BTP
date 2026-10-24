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

    def forward(self, S):
        """S: (T, B, n_in) spikes. Returns spikes (T, B, n_out) and pre-reset potentials U."""
        T, B, _ = S.shape
        W = self.w_int()
        V = torch.zeros(B, W.shape[1], device=S.device)
        spikes, Us = [], []
        for t in range(T):
            U = leak(V, self.k) + S[t] @ W
            s = SpikeFn.apply(U - self.theta, self.sscale)
            V = U - self.theta * s
            spikes.append(s)
            Us.append(U)
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
