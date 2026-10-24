"""Deterministic spike encoders shared by the trainer, the golden models and the RTL testbench."""

import numpy as np


def if_encode(img_u8: np.ndarray, T: int, gain: int = 1) -> np.ndarray:
    """Integrate-and-fire rate encoder for 8-bit images.

    Each pixel adds ``gain * value`` (0..255*gain) to an accumulator every timestep and emits a
    spike when the accumulator reaches 256, subtracting 256. Deterministic and integer-only, so the
    hardware input stage can reproduce it. Spike rate per pixel = min(1, gain*value/256).

    img_u8: (..., P) uint8. Returns (..., T, P) uint8.
    """
    x = np.asarray(img_u8, dtype=np.int32) * gain
    acc = np.zeros_like(x)
    out = np.zeros(x.shape[:-1] + (T, x.shape[-1]), dtype=np.uint8)
    for t in range(T):
        acc = acc + x
        s = acc >= 256
        acc = acc - 256 * s
        out[..., t, :] = s
    return out
