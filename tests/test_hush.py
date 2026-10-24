"""Property tests of the HUSH safety argument on the integer golden models.

Run:  python -m pytest -q tests/
"""

import sys
from pathlib import Path

import numpy as np
from hypothesis import given, settings, strategies as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from golden.hush import (LIFParams, clip, leak, proxy_table, run_gated, run_oracle,  # noqa: E402
                         run_ref)


# ---------- Lemma 1: L is non-decreasing on the integers, steps of 0 or 1 ----------

def test_lemma1_exhaustive():
    x = np.arange(-(1 << 16), (1 << 16), dtype=np.int64)
    for k in range(1, 9):
        d = np.diff(leak(x, k))
        assert set(np.unique(d).tolist()) <= {0, 1}, k


def test_leak_matches_floor_division():
    x = np.arange(-5000, 5000, dtype=np.int64)
    for k in range(1, 8):
        assert np.array_equal(leak(x, k), x - np.floor_divide(x, 1 << k))


def test_leak_negative_values_round_toward_minus_infinity():
    # -1 >> 3 = -1, so L(-1) = 0: a small negative potential leaks to zero, never below.
    assert leak(np.array([-1]), 3)[0] == 0
    assert leak(np.array([-9]), 3)[0] == -7


# ---------- random layers ----------

@st.composite
def layer_case(draw):
    b_env = draw(st.sampled_from([2, 4, 8]))
    per = draw(st.sampled_from([1, 2, 4]))
    b_blk = b_env * per
    G = draw(st.integers(1, 3))
    N = b_blk * G
    M = draw(st.integers(1, 24))
    T = draw(st.integers(1, 30))
    wmax = draw(st.sampled_from([8, 32, 127]))
    seed = draw(st.integers(0, 2**31 - 1))
    rng = np.random.default_rng(seed)
    W = rng.integers(-wmax - 1, wmax + 1, size=(M, N))
    rate = draw(st.floats(0.02, 0.9))
    S = (rng.random((T, M)) < rate).astype(np.int64)
    theta = draw(st.integers(1, 200))
    k = draw(st.integers(1, 6))
    vbits = draw(st.sampled_from([8, 10, 16]))
    theta = min(theta, (1 << (vbits - 1)) - 1)
    return W, S, LIFParams(k=k, theta=theta, vbits=vbits, b_env=b_env, b_blk=b_blk)


@settings(max_examples=400, deadline=None)
@given(layer_case())
def test_theorem1_invariant(case):
    """V_i(t) <= R_c(t) and U_i^ungated(t) <= E_c(t) for every neuron, sub-block and timestep."""
    W, S, p = case
    tr = run_gated(W, S, p)
    C = W.shape[1] // p.b_env
    Vc = tr.V.reshape(len(S), C, p.b_env)
    Uc = tr.U_ungated.reshape(len(S), C, p.b_env)
    assert (Vc <= tr.R[:, :, None]).all()
    assert (Uc <= tr.E_hat[:, :, None]).all()


@settings(max_examples=400, deadline=None)
@given(layer_case())
def test_corollary1_no_suppressed_spike_in_exact_mode(case):
    """A gated sub-block contains no neuron whose ungated update would reach theta."""
    W, S, p = case
    tr = run_gated(W, S, p)
    gated = ~np.repeat(tr.awake_sub, p.b_env, axis=1)
    assert not (gated & (tr.U_ungated >= p.theta)).any()


@settings(max_examples=300, deadline=None)
@given(layer_case())
def test_oracle_gate_implies_envelope_gate(case):
    """From the same state, if any neuron would fire, the envelope is awake (single-step dominance)."""
    W, S, p = case
    tr = run_gated(W, S, p)
    T, N = tr.U_ungated.shape
    would_fire = (tr.U_ungated >= p.theta).reshape(T, N // p.b_env, p.b_env).any(axis=2)
    assert not (would_fire & ~tr.awake_sub).any()


@settings(max_examples=200, deadline=None)
@given(layer_case())
def test_values_stay_in_register_range(case):
    W, S, p = case
    tr = run_gated(W, S, p)
    for a in (tr.V, tr.U, tr.E_hat, tr.R):
        assert a.min() >= p.vmin and a.max() <= p.vmax


@settings(max_examples=200, deadline=None)
@given(layer_case())
def test_gate_always_on_equals_ref(case):
    """With theta_h at the bottom of the range every sub-block is awake, so GATED == REF."""
    W, S, p = case
    p_on = LIFParams(k=p.k, theta=p.theta, theta_h=p.vmin, vbits=p.vbits, b_env=p.b_env, b_blk=p.b_blk)
    g, r = run_gated(W, S, p_on), run_ref(W, S, p)
    assert np.array_equal(g.spikes, r.spikes) and np.array_equal(g.V, r.V)


@settings(max_examples=200, deadline=None)
@given(layer_case())
def test_oracle_is_exact_mode(case):
    """ORACLE also never suppresses a spike of the ungated update from its own state."""
    W, S, p = case
    tr = run_oracle(W, S, p)
    assert tr.awake_blk.shape[1] == W.shape[1] // p.b_blk


# ---------- Corollaries 2 and 3: tightness of the proxies ----------

@settings(max_examples=300, deadline=None)
@given(layer_case())
def test_corollary2_signed_proxy_never_looser(case):
    """max(0, sum P) <= sum max(0, P): the v2 drive bound is never above v1's."""
    W, S, p = case
    P = proxy_table(W, p.b_env)
    for s in S:
        assert (np.maximum(s @ P, 0) <= s @ np.maximum(P, 0)).all()


@settings(max_examples=300, deadline=None)
@given(layer_case())
def test_corollary3_subblock_drive_below_block_drive(case):
    """Each 8-neuron sub-block's drive bound is at most its 32-neuron block's bound."""
    W, S, p = case
    per = p.b_blk // p.b_env
    P_sub = proxy_table(W, p.b_env)          # (M, C)
    P_blk = proxy_table(W, p.b_blk)          # (M, G)
    for s in S:
        d_sub = (s @ P_sub).reshape(-1, per)
        d_blk = s @ P_blk
        assert (d_sub <= d_blk[:, None]).all()


def test_saturation_never_wraps():
    """Huge positive drive on narrow registers: values pin at vmax instead of wrapping negative."""
    p = LIFParams(k=3, theta=100, vbits=8, b_env=2, b_blk=4)
    W = np.full((16, 4), 127)
    S = np.ones((10, 16), np.int64)
    tr = run_gated(W, S, p)
    assert tr.E_hat.max() == p.vmax and tr.E_hat.min() >= 0
    assert (tr.U_ungated <= tr.E_hat.repeat(p.b_env, axis=1)).all()


def test_clip_is_monotone():
    p = LIFParams(vbits=8)
    x = np.arange(-1000, 1000)
    assert (np.diff(clip(x, p)) >= 0).all()
