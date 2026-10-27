# A3: annotate the routed power builds with the gate-level SAIF from run_power2.bat and report power.
set here [file dirname [file normalize [info script]]]
set out  [file normalize $here/../out_pwr]
proc note {msg} { global out; set fp [open $out/summary2.txt a]; puts $fp $msg; close $fp; puts $msg }
foreach case {base mf_gentle mf_aggr} {
    set d $out/$case
    set ok 0
    foreach lg {sim_try1.log sim_try2.log} {
        if {[file exists $d/$lg]} { set fp [open $d/$lg r]; set txt [read $fp]; close $fp
            if {[regexp -line {^I 19 } $txt]} { set ok 1 } }
    }
    if {!$ok || ![file exists $d/act.saif] || [file size $d/act.saif] == 0} { note "$case: no complete SAIF, skipped"; continue }
    if {[catch {
        open_checkpoint $d/routed.dcp
        if {[catch {read_saif -strip_path tb_net/u_top -out_file $d/read_saif_unmatched.txt $d/act.saif}]} {
            read_saif -strip_path tb_net/u_top $d/act.saif
        }
        report_power -file $d/power_saif.rpt
        close_design
    } err]} { note "$case power FAILED: $err"; catch {close_design}; continue }
    note "$case power OK"
}
