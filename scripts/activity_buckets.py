"""A9.1b: HUSH speedup per 3 ms bin vs bin activity (500 test samples). python scripts/activity_buckets.py <weights.npz>"""
import sys, numpy as np
sys.path.insert(0,"."); sys.path.insert(0,"rtl/sim")
from cycle_model import rtl_cycles
from golden.datasets import NMNIST
from golden.hush import LIFParams, run_gated, run_ref
from scripts.measure_rho import pad_hidden
from scripts.rtl_perf import pad_out
z=np.load(sys.argv[1]); T=int(z["T"]); tm=int(float(z["t_max"])*1e6)
Ws=[z[f"W{i}"].astype(np.int64) for i in range(10) if f"W{i}" in z]
Ws[0],Ws[1],_=pad_hidden(Ws[0],Ws[1],32); Wo,_=pad_out(Ws[1])
pg=LIFParams(k=4,theta=64,b_env=8,b_blk=32,asleep_drive="mean"); pr=LIFParams(k=4,theta=64,b_env=8,b_blk=32)
d=NMNIST(False,tm); idx=np.random.default_rng(0).permutation(len(d))[:500]
A=[];B=[];H=[];AW=[]
for i in idx:
    S,_=d.raster(i,T); n0=S.sum(1)
    for mode in ("B","H"):
        h=run_gated(Ws[0],S,pg,shadow=False) if mode=="H" else run_ref(Ws[0],S,pr)
        n=h.n_active.astype(np.int64)
        c=np.array([rtl_cycles(n[t:t+1],h.awake_blk[t:t+1],envelope=(mode=="H")) for t in range(T)])
        o=run_ref(Wo,h.spikes,pr); m=o.n_active.astype(np.int64)
        c+=np.array([rtl_cycles(m[t:t+1],o.awake_blk[t:t+1],envelope=False) for t in range(T)])
        (B if mode=="B" else H).append(c)
        if mode=="H": AW.append(h.awake_blk.mean(1))
    A.append(n0)
A,B,H,AW=map(np.concatenate,(A,B,H,AW))
print("bucket(active inputs) | share of bins | BASE cyc | HUSH cyc | speedup | awake fraction")
for lo,hi in [(0,1),(1,10),(10,20),(20,30),(30,40),(40,60),(60,200)]:
    k=(A>=lo)&(A<hi)
    if k.sum(): print(f"{lo}-{hi-1} | {k.mean()*100:.1f}% | {B[k].mean():.0f} | {H[k].mean():.0f} | {B[k].mean()/H[k].mean():.2f} | {AW[k].mean():.2f}")
print("all", B.mean()/H.mean())
