"""A4: bit-exact Python model of a Spiker+ (spikerplus 2.0.3) LIF layer stack, read from the generated VHDL.
Per timestep (one start_all pulse), each layer, all neurons in parallel:
  1. 'sample' state: fire if V > theta (strict) -> V = sat(V - theta), spike = 1; else leak V = sat(V - (V >>> k)).
  2. add the weights of the sampled excitatory inputs that spiked (saturating at 16 bits, one input per cycle).
  3. add the recurrent ('inh') weights of the layer's own previous spikes (all zero for a feed-forward lif layer).
Layer l > 0 sees layer l-1's spikes of the same step (delay = 0; fixed by the full-size GHDL run, where only
delay 0 matches all 102 output lines; small nets could not tell 0 from 1).
Cycles per step per layer (from the control units): scan of all inputs when any input spiked, + scan of the
recurrent inputs when any own spike, + handshake overhead; the network step waits for the slowest layer."""
import numpy as np
VB = 16; VMAX, VMIN = 2**(VB-1)-1, -2**(VB-1)
sat = lambda x: np.clip(x, VMIN, VMAX)

def run(Ws, S, theta=64, k=4, delay=0, Wrec=None):
    """Ws: list of (in, out) int arrays; S: (T, M) or (B, T, M) 0/1. Returns list of per-layer spike arrays (B, T, N)."""
    S = S[None] if S.ndim == 2 else S
    B, T, _ = S.shape
    x = S.astype(np.int64)
    outs = []
    for li, W in enumerate(Ws):
        N = W.shape[1]; V = np.zeros((B, N), np.int64); prev = np.zeros((B, N), np.int64)
        spk = np.zeros((B, T, N), np.int8)
        for t in range(T):
            f = V > theta
            V = np.where(f, sat(V - theta), sat(V - (V >> k)))
            spk[:, t] = f
            V = sat(V + x[:, t] @ W)            # exact if no intermediate saturation (checked: |V| stays far from 2^15)
            if Wrec is not None and Wrec[li] is not None:
                V = sat(V + prev @ Wrec[li])
            prev = f.astype(np.int64)
        outs.append(spk)
        # next layer's input at step t = this layer's spikes at step t - delay
        x = np.zeros_like(spk, dtype=np.int64)
        if delay < T: x[:, delay:] = spk[:, :T - delay]
    return outs

def predict(out_spk):
    """Class = most output spikes over the run, ties -> lower index."""
    return np.argmax(out_spk.sum(axis=1), axis=-1)
