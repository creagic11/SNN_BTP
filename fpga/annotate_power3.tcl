# A3 fix 2 (28 Oct): re-annotate the routed power builds with the gate-level SAIF, no re-simulation.
# Fix 1 (annotate_power2.tcl): drop the 32 bit-lines named "\(null)[0].(null)[0].b2..." that read_saif cannot parse.
# Fix 2 (this script): act_fixed.saif from scripts/fix_saif_names.py also rewrites xsim's escaped names
# ("\\acc\[0\]\[3\]_i_3_n_0\ ") into the form read_saif matches ("acc\[0\]\[3\]_i_3_n_0"). Before, 31-38% of
# design nets (LIF lane adders, accumulators, spike outputs) were unmatched and fell back to vectorless activity.
# Writes out_pwr/<case>/power_saif_fixed.rpt, unmatched_fixed.txt and out_pwr/summary4.txt.
set here [file dirname [file normalize [info script]]]
set out  [file normalize $here/../out_pwr]
set fp [open $out/summary4.txt w]; puts $fp "annotate_power3 [clock format [clock seconds]]"; close $fp
proc note {msg} { global out; set fp [open $out/summary4.txt a]; puts $fp $msg; close $fp; puts $msg }
foreach case {base mf_gentle mf_aggr} {
    set d $out/$case
    set saif $d/act_fixed.saif
    if {![file exists $saif] || [file size $saif] == 0} { note "$case: no act_fixed.saif, skipped"; continue }
    if {[catch {
        open_checkpoint $d/routed.dcp
        if {[catch {read_saif -strip_path tb_net/u_top -out_file $d/unmatched_fixed.txt $saif}]} {
            read_saif -strip_path tb_net/u_top $saif
        }
        report_power -file $d/power_saif_fixed.rpt
        close_design
    } err]} { note "$case power FAILED: $err"; catch {close_design}; continue }
    set fp [open $d/power_saif_fixed.rpt r]; set rpt [read $fp]; close $fp
    set m "?"; set p "?"
    regexp -line {Design Nets Matched\s*\|\s*([^|]*)\|} $rpt -> m
    regexp -line {Total On-Chip Power \(W\)\s*\|\s*([0-9.]+)} $rpt -> p
    note "$case power OK  saif=[file tail $saif]  total=${p} W  matched=[string trim $m]"
}
note "ALL DONE"
