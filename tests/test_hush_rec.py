"""Property tests of Theorem 1' (headroom envelope) for recurrent adLIF layers (golden/hush_rec.py).

Run:  python -m pytest -q tests/
"""

import sys
from pathlib import Path

import numpy as np
from hypothesis import given, settings, strategies as st

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from golden.hush import LIFParams, run_gated, run_ref  # noqa: E402
from golden.hush_rec import AdLIFParams, RecLayer, run_rec  # noqa: E402


@st.composite
def rec_case(draw, recurrent=None, adapt=None):
    b_env = draw(st.sampled_from([2, 4, 8]))
    per = draw(st.sampled_from([1, 2, 4]))
    b_blk = b_env * per
    N = b_blk * draw(st.integers(1, 3))
    M = draw(st.integers(1, 24))
    T = draw(st.integers(1, 30))
    wmax = draw(st.sampled_from([8, 32, 127]))
    rng = np.random.default_rng(draw(st.integers(0, 2**31 - 1)))
    Wff = rng.integers(-wmax - 1, wmax + 1, size=(M, N))
    rec = draw(st.booleans()) if recurrent is None else recurrent
    Wrec = rng.integers(-wmax - 1, wmax + 1, size=(N, N)) if rec else None
    ad = draw(st.booleans()) if adapt is None else adapt
    a = rng.integers(-16, 17, size=N) if ad else None
    b = rng.integers(0, 64, size=N) if ad else None
    X = (rng.random((T, M)) < draw(st.floats(0.02, 0.9))).astype(np.int64)
    vbits = draw(st.sampled_from([8, 10, 16]))
    theta = min(draw(st.integers(1, 200)), (1 << (vbits - 1)) - 1)
    lif = LIFParams(k=draw(st.integers(1, 6)), theta=theta, vbits=vbits, b_env=b_env, b_blk=b_blk,
                    asleep_drive=draw(st.sampled_from(["none", "mean"])))
    q = AdLIFParams(lif=lif, kw=draw(st.integers(1, 6)), sa=draw(st.integers(0, 5)),
                    wbits=draw(st.sampled_from([10, 16])), signed_drive=draw(st.booleans()))
    return RecLayer(Wff, Wrec, a, b), X, q


@settings(max_examples=300, deadline=None)
@given(rec_case(recurrent=False, adapt=False))
def test_reduces_to_v1_lif_layer(case):
    """No recurrence, no adaptation, v1 drive rule: identical to golden/hush.py run_gated / run_ref."""
    L, X, q = case
    q1 = AdLIFParams(lif=q.lif, signed_drive=False)
    g_new, g_old = run_rec(L, X, q1, "gated"), run_gated(L.Wff, X, q.lif)
    for f in ("spikes", "V", "U", "awake_sub"):
        assert np.array_equal(getattr(g_new, f), getattr(g_old, f)), f
    r_new, r_old = run_rec(L, X, q1, "ref"), run_ref(L.Wff, X, q.lif)
    assert np.array_equal(r_new.spikes, r_old.spikes) and np.array_equal(r_new.V, r_old.V)


@settings(max_examples=400, deadline=None)
@given(rec_case())
def test_theorem1prime_no_suppressed_spike(case):
    """Exact mode: a gated sub-block holds no neuron whose ungated update reaches theta."""
    L, X, q = case
    tr = run_rec(L, X, q, "gated")
    gn = np.repeat(tr.awake_sub, q.lif.b_env, axis=1)
    assert not np.any(~gn & (tr.U_ungated >= q.lif.theta))


@settings(max_examples=300, deadline=None)
@given(rec_case(adapt=True))
def test_theorem1prime_under_negative_adaptation(case):
    """a_i < 0 makes -w_i a positive drive; the headroom bound must still cover it."""
    L, X, q = case
    L.a = -np.abs(L.a) - 1
    tr = run_rec(L, X, q, "gated")
    gn = np.repeat(tr.awake_sub, q.lif.b_env, axis=1)
    assert not np.any(~gn & (tr.U_ungated >= q.lif.theta))


@settings(max_examples=300, deadline=None)
@given(rec_case())
def test_gated_spikes_equal_ungated_spikes_same_state(case):
    """Per step, from the same state, the gated layer emits exactly the ungated spikes."""
    L, X, q = case
    tr = run_rec(L, X, q, "gated")
    gn = np.repeat(tr.awake_sub, q.lif.b_env, axis=1)
    ung_spk = tr.U_ungated >= q.lif.theta
    assert np.array_equal(tr.spikes.astype(bool), ung_spk & gn)
    assert np.array_equal(tr.spikes.astype(bool), ung_spk)


@settings(max_examples=200, deadline=None)
@given(rec_case())
def test_gate_always_on_equals_ref(case):
    L, X, q = case
    lif = LIFParams(**{**q.lif.__dict__, "theta_h": -(1 << 40)})   # below any signed lhs
    q2 = AdLIFParams(lif=lif, kw=q.kw, sa=q.sa, wbits=q.wbits, signed_drive=q.signed_drive)
    g, r = run_rec(L, X, q2, "gated"), run_rec(L, X, q2, "ref")
    assert g.awake_sub.all()
    for f in ("spikes", "V", "Wad"):
        assert np.array_equal(getattr(g, f), getattr(r, f)), f


@settings(max_examples=300, deadline=None)
@given(rec_case())
def test_signed_drive_never_looser(case):
    """From the same states, the signed-drive gate is awake only where the v1 (max(0, D)) gate is."""
    L, X, q = case
    q_s = AdLIFParams(lif=q.lif, kw=q.kw, sa=q.sa, wbits=q.wbits, signed_drive=True)
    tr = run_rec(L, X, q_s, "gated")
    C = tr.awake_sub.shape[1]
    from golden.hush import clip, proxy_table
    P = proxy_table(L.Wc(), q.lif.b_env)
    for t in range(X.shape[0]):
        s_prev = tr.spikes[t - 1].astype(np.int64) if t > 0 else np.zeros(L.N, np.int64)
        z = np.concatenate([X[t], s_prev]) if L.Wrec is not None else X[t]
        v1 = (clip(tr.R[t], q.lif) + np.maximum(z @ P, 0) >= q.lif.th_gate) | (tr.R[t] > q.lif.vmax)
        assert not np.any(tr.awake_sub[t] & ~v1)
        assert C == v1.size


@settings(max_examples=300, deadline=None)
@given(rec_case())
def test_mean_field_asleep_neurons_stay_below_threshold(case):
    L, X, q = case
    lif = LIFParams(**{**q.lif.__dict__, "asleep_drive": "mean"})
    q2 = AdLIFParams(lif=lif, kw=q.kw, sa=q.sa, wbits=q.wbits, signed_drive=q.signed_drive)
    tr = run_rec(L, X, q2, "gated")
    gn = np.repeat(tr.awake_sub, lif.b_env, axis=1)
    assert np.all(tr.U[~gn] < lif.theta)


@settings(max_examples=200, deadline=None)
@given(rec_case())
def test_registers_stay_in_range(case):
    L, X, q = case
    tr = run_rec(L, X, q, "gated")
    assert tr.V.min() >= q.lif.vmin - q.lif.theta and tr.V.max() <= q.lif.vmax
    assert tr.Wad.min() >= q.wmin and tr.Wad.max() <= q.wmax


def test_saturated_bound_forces_awake():
    """Bmax above the register range (w very negative) must not let a large negative D gate it off."""
    lif = LIFParams(k=1, theta=10, vbits=8, b_env=2, b_blk=2)
    q = AdLIFParams(lif=lif, kw=8, sa=0, wbits=16, signed_drive=True)
    L = RecLayer(Wff=np.array([[-128, 127]]), a=np.array([-200, -200]), b=np.array([0, 0]))
    X = np.array([[0], [0], [1], [1], [1]])
    # Drive V up so a*V makes w very negative, then B = L(V) - w far above vmax.
    L.Wff = np.array([[100, 100]])
    tr = run_rec(L, X, q, "gated")
    gn = np.repeat(tr.awake_sub, 2, axis=1)
    assert not np.any(~gn & (tr.U_ungated >= lif.theta))


@settings(max_examples=300, deadline=None)
@given(rec_case(), st.sampled_from(["lr1", "lr2", "lr3", "exact"]))
def test_clamped_hibernation_asleep_neurons_stay_below_threshold(case, drive):
    """Any asleep-drive approximation clamped to D_c keeps asleep neurons below theta."""
    L, X, q = case
    lif = LIFParams(**{**q.lif.__dict__, "asleep_drive": drive})
    q2 = AdLIFParams(lif=lif, kw=q.kw, sa=q.sa, wbits=q.wbits, signed_drive=q.signed_drive)
    tr = run_rec(L, X, q2, "gated")
    gn = np.repeat(tr.awake_sub, lif.b_env, axis=1)
    assert np.all(tr.U[~gn] < lif.theta)
    assert not np.any(~gn & (tr.U_ungated >= lif.theta))


@settings(max_examples=200, deadline=None)
@given(st.integers(1, 40), st.integers(1, 20), st.integers(0, 2**31 - 1))
def test_delay_events_matches_definition(T, M, seed):
    from golden.hush_delay import delay_events
    rng = np.random.default_rng(seed)
    S = (rng.random((T, M)) < 0.3).astype(np.int64)
    d = rng.integers(0, 30, size=M)
    Z = delay_events(S, d)
    for t in range(T):
        for j in range(M):
            assert Z[t, j] == (S[t - d[j], j] if t >= d[j] else 0)


@settings(max_examples=300, deadline=None)
@given(rec_case(), st.integers(0, 2**31 - 1))
def test_theorem1prime_with_bias_current(case, seed):
    """A per-neuron constant bias current (folded BatchNorm) is drive-free: the gate must still be safe."""
    L, X, q = case
    L.bias = np.random.default_rng(seed).integers(-3 * q.lif.theta, 2 * q.lif.theta + 1, size=L.N)
    tr = run_rec(L, X, q, "gated")
    gn = np.repeat(tr.awake_sub, q.lif.b_env, axis=1)
    assert not np.any(~gn & (tr.U_ungated >= q.lif.theta))
