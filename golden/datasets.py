"""Dataset loaders that return integer spike rasters (T, M) uint8, shared by trainer and golden models."""

from __future__ import annotations

import os
from pathlib import Path

import numpy as np

from golden.encode import if_encode

DATA_DIR = Path(os.environ.get("DATA_DIR", Path.home() / "data"))


# ---------------- MNIST ----------------

def mnist_arrays(train: bool):
    import torchvision
    ds = torchvision.datasets.MNIST(DATA_DIR, train=train, download=False)
    return ds.data.reshape(-1, 784).numpy(), ds.targets.numpy()


def mnist_spikes(train: bool, T: int, gain: int = 1, n: int | None = None):
    X, Y = mnist_arrays(train)
    if n:
        X, Y = X[:n], Y[:n]
    return if_encode(X, T, gain), Y


# ---------------- SHD ----------------

class SHD:
    """Spiking Heidelberg Digits as event lists; binned on demand into T bins over [0, t_max) seconds."""

    def __init__(self, train: bool, t_max: float = 1.0, pool: int = 1):
        import h5py
        f = h5py.File(DATA_DIR / "shd" / f"shd_{'train' if train else 'test'}.h5", "r")
        self.times = [np.asarray(t) for t in f["spikes"]["times"]]
        self.units = [np.asarray(u, dtype=np.int64) for u in f["spikes"]["units"]]
        self.labels = np.asarray(f["labels"], dtype=np.int64)
        self.t_max = t_max
        self.pool = pool                       # OR of `pool` adjacent cochlea channels
        self.M = -(-700 // pool)

    def __len__(self):
        return len(self.labels)

    def raster(self, i: int, T: int) -> np.ndarray:
        """(T, M) uint8, M = ceil(700 / pool); a channel is 1 in a bin if any of its pooled cochlea channels
        spiked in it (events after t_max dropped)."""
        t, u = self.times[i], self.units[i]
        keep = t < self.t_max
        b = (t[keep] / self.t_max * T).astype(np.int64)
        r = np.zeros((T, self.M), np.uint8)
        r[b, u[keep] // self.pool] = 1
        return r

    def batch(self, idx, T: int) -> np.ndarray:
        return np.stack([self.raster(i, T) for i in idx])


# ---------------- N-MNIST ----------------

class NMNIST:
    """N-MNIST events (34x34x2), binned into T bins over the first t_max microseconds; 2*34*34 = 2312
    inputs, or downsampled by ``pool`` (2 -> 2*17*17 = 578 inputs)."""

    def __init__(self, train: bool, t_max_us: int = 300_000, pool: int = 2):
        import tonic
        self.ds = tonic.datasets.NMNIST(save_to=str(DATA_DIR), train=train)
        self.t_max = t_max_us
        self.pool = pool
        self.side = 34 // pool
        self.M = 2 * self.side * self.side
        self._cache = {}

    def __len__(self):
        return len(self.ds)

    def raster(self, i: int, T: int) -> tuple[np.ndarray, int]:
        ev, y = self.ds[i]
        keep = ev["t"] < self.t_max
        ev = ev[keep]
        b = (ev["t"].astype(np.int64) * T // self.t_max)
        ch = ev["p"].astype(np.int64) * self.side * self.side + (ev["y"] // self.pool) * self.side + ev["x"] // self.pool
        r = np.zeros((T, self.M), np.uint8)
        r[b, ch] = 1
        return r, int(y)
