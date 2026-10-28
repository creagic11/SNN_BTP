# A3 fix (28 Oct): re-annotate the routed power builds with the gate-level SAIF, no re-simulation.
# Why: Vivado's write_verilog named two wires of the MF max tree "\(null)[0].(null)[0].b2" (unnamed
# generate scopes in hush_layer.sv). xsim logged them, and read_saif cannot parse that name: it stopped at
# that line, so only 105 of 43,473 nets were annotated for mf_gentle and mf_aggr. act_clean.saif is act.saif
# with those 32 bit-lines removed (they get Vivado's default activity); everything else is unchanged.
# Writes out_pwr/<case>/power_saif.rpt and out_pwr/summary3.txt (with the matched-net count per case).
set here [file dirname [file normalize [info script]]]
set out  [file normalize $here/../out_pwr]
set fp [open $out/summary3.txt w]; puts $fp "annotate_power2 [clock format [clock seconds]]"; close $fp
proc note {msg} { global out; set fp [open $out/summary3.txt a]; puts $fp $msg; close $fp; puts $msg }
foreach case {base mf_gentle mf_aggr} {
    set d $out/$case
    set saif $d/act.saif
    if {[file exists $d/act_clean.saif]} { set saif $d/act_clean.saif }
    if {![file exists $saif] || [file size $saif] == 0} { note "$case: no SAIF, skipped"; continue }
    if {[catch {
        open_checkpoint $d/routed.dcp
        read_saif -strip_path tb_net/u_top $saif
        report_power -file $d/power_saif.rpt
        close_design
    } err]} { note "$case power FAILED: $err"; catch {close_design}; continue }
    set fp [open $d/power_saif.rpt r]; set rpt [read $fp]; close $fp
    regexp -line {Design Nets Matched\s*\|\s*([^|]*)\|} $rpt -> m
    regexp -line {Total On-Chip Power \(W\)\s*\|\s*([0-9.]+)} $rpt -> p
    note "$case power OK  saif=[file tail $saif]  total=${p} W  matched=[string trim $m]"
}
note "ALL DONE"
