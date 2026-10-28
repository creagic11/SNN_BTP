"""Rewrite xsim gate-level SAIF net names into the form Vivado's read_saif matches (A3, 28 Oct 2026).
xsim writes escaped netlist identifiers as  \\name\[i\]_n_0\   (leading double backslash, trailing escaped
space) and escaped buses as  \\name\ \[k\] ; Vivado matches  name\[i\]_n_0  and  name\[k\] . Left as is, those
nets (31-38% of the design: LIF lane adders, accumulators, spike outputs) are unmatched and fall back to
vectorless activity. Lines with Vivado's "(null)" generate-scope names cannot be parsed at all and are dropped.
Usage: python3 fix_saif_names.py act.saif act_fixed.saif"""
import re, sys
src, dst = sys.argv[1], sys.argv[2]
bus = re.compile(r'\(\\\\(\S+?)\\ \\\[(\d+)\\\] \(T0')
sca = re.compile(r'\(\\\\(\S+?)\\  \(T0')
n = dict(bus=0, scalar=0, null_dropped=0, left_escaped=0); out = []
for ln in open(src):
    if '(null' in ln: n['null_dropped'] += 1; continue
    ln2, k = bus.subn(r'(\1\\[\2\\] (T0', ln); n['bus'] += k
    if not k:
        ln2, k = sca.subn(r'(\1 (T0', ln); n['scalar'] += k
    if re.search(r'\(\\\\', ln2): n['left_escaped'] += 1
    out.append(ln2)
s = ''.join(out); open(dst, 'w').write(s)
print(src, n, 'paren balance', s.count('(') - s.count(')'))
