# A3b: annotate the v5 power builds with their gate-level SAIF (names fixed by fix_saif_names.tcl), report power
# and energy per inference. Called by run_v5.bat after the simulations. Writes ../out_v5c/pwr/<case>/power_saif.rpt,
# unmatched.txt, ../out_v5c/energy.csv and lines in ../out_v5c/summary.txt.
set here [file dirname [file normalize [info script]]]
set out  [file normalize $here/../out_v5c]
source $here/fix_saif_names.tcl
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp "[clock format [clock seconds] -format %H:%M:%S] $msg"; close $fp; puts $msg }
set csv [open $out/energy.csv w]
puts $csv "case,inferences,mean_cycles,latency_us,total_mW,dynamic_mW,static_mW,E_total_uJ,E_dyn_uJ,nets_matched"
foreach case {base mf_gentle mf_aggr} {
    set d $out/pwr/$case
    set cyc {}
    foreach lg {sim_try1.log sim_try2.log} {
        if {[file exists $d/$lg]} { set fp [open $d/$lg r]
            while {[gets $fp ln] >= 0} { if {[regexp {^I ([0-9]+) ([0-9]+)} $ln -> i c]} { lappend cyc $c } }
            close $fp; if {[llength $cyc] >= 20} break; set cyc {} }
    }
    if {[llength $cyc] < 20 || ![file exists $d/act.saif]} { note "$case: no complete simulation, skipped"; continue }
    set r [fix_saif_names $d/act.saif $d/act_fixed.saif]
    note "$case SAIF names: bus [lindex $r 0] scalar [lindex $r 1] dropped [lindex $r 2] left-escaped [lindex $r 3] paren-balance [lindex $r 4]"
    if {[catch {
        open_checkpoint $d/routed.dcp
        if {[catch {read_saif -strip_path tb_net/u_top -out_file $d/unmatched.txt $d/act_fixed.saif}]} {
            read_saif -strip_path tb_net/u_top $d/act_fixed.saif }
        report_power -file $d/power_saif.rpt
        report_power -hierarchical_depth 4 -file $d/power_saif_hier.rpt
        close_design
    } err]} { note "$case power FAILED: $err"; catch {close_design}; continue }
    set fp [open $d/power_saif.rpt r]; set rpt [read $fp]; close $fp
    set m "?"; set pt 0; set pd 0; set ps 0
    regexp -line {Design Nets Matched\s*\|\s*([^|]*)\|} $rpt -> m
    regexp -line {Total On-Chip Power \(W\)\s*\|\s*([0-9.]+)} $rpt -> pt
    regexp -line {Dynamic \(W\)\s*\|\s*([0-9.]+)} $rpt -> pd
    regexp -line {Device Static \(W\)\s*\|\s*([0-9.]+)} $rpt -> ps
    # inference 0 includes the reset release; use inferences 1..19 for the mean
    set s 0; foreach c [lrange $cyc 1 end] { incr s $c }
    set mc [expr {double($s) / ([llength $cyc] - 1)}]
    set us [expr {$mc * 0.01}]
    set line [format "%s,%d,%.1f,%.2f,%.0f,%.0f,%.0f,%.2f,%.2f,%s" $case [llength $cyc] $mc $us [expr {$pt*1000}] [expr {$pd*1000}] [expr {$ps*1000}] [expr {$pt*$us}] [expr {$pd*$us}] [string trim $m]]
    puts $csv $line
    note "$case power OK: $line"
}
close $csv
note "ALL DONE"
