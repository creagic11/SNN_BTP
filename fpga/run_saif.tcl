# A3: activity-based (SAIF) power for BASE and HUSH-MF on the XC7A100T at 100 MHz.
# Run from the Vivado Tcl Shell:
#     cd C:/Users/Anubhav/hush_fpga/fpga
#     vivado -mode batch -source run_saif.tcl
# Steps: (1) rebuild BASE and HUSH-MF with the fixed autorun top (back-to-back inferences);
# (2) xsim RTL simulation over NS N-MNIST samples per case, recording switching activity (SAIF);
# (3) annotate the routed designs with that activity and report power.
# Cases: base (ungated network, BASE build), mf_gentle and mf_aggr (co-trained networks, HUSH-MF build).
# Outputs: ../out_saif/power_saif_<case>.rpt, ../out_saif/sim_<case>.log, ../out_saif/summary.txt
set NS 100
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set out  $root/out_saif
file mkdir $out
set fp [open $out/summary.txt w]; puts $fp "vivado: [version -short]  samples per case: $NS"; close $fp
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp $msg; close $fp; puts $msg }

# (1) rebuild with the fixed top
foreach cfg {{0 0 base_v3} {1 1 hush_mf_v3}} {
    lassign $cfg g m name
    if {[file exists $root/out_$name/routed.dcp]} { note "$name: reuse existing build"; continue }
    set argv [list $here/hex $root/out_$name $g $m 578 256 100 4]
    set argc [llength $argv]
    if {[catch {source $here/build.tcl} err]} { note "$name build FAILED: $err" } else { note "$name build OK" }
    catch {close_project}
    cd $here
}

# (2) + (3) simulate and annotate
foreach cfg {{base 0 0 base_v3} {mf_gentle 1 1 hush_mf_v3} {mf_aggr 1 1 hush_mf_v3}} {
    lassign $cfg case g m build
    set sim $out/sim_$case
    file mkdir $sim
    foreach f [glob $here/hex/*.hex] { file copy -force $f $sim }
    cd $sim
    set xsim_tcl [open $sim/saif.tcl w]
    puts $xsim_tcl "open_saif $sim/act.saif"
    puts $xsim_tcl "log_saif \[get_objects -r /tb_saif/u_top/*\]"
    puts $xsim_tcl "run all"
    puts $xsim_tcl "close_saif"
    puts $xsim_tcl "quit"
    close $xsim_tcl
    # Windows' xelab.bat / xsim.bat split arguments at '=', so no generics or plusargs on the command line:
    # write a per-case copy of the testbench with GATE, MF, the data paths and NS baked in.
    set fin [open $here/tb_saif.sv r]; set tb [read $fin]; close $fin
    set tb [string map [list "parameter int GATE = 1, MF = 1;" "parameter int GATE = $g, MF = $m;" \
        {wdir = ".";} "wdir = \"$here/saif/$case\";" \
        {sdir = ".";} "sdir = \"$here/saif/samples\";" \
        {ns = 10;} "ns = $NS;"] $tb]
    set fo [open $sim/tb_saif_case.sv w]; puts $fo $tb; close $fo
    set rtl_case [list $root/rtl/hush_arith.sv $root/rtl/hush_layer.sv $here/top_hush.sv $sim/tb_saif_case.sv]
    if {[catch {
        exec -ignorestderr {*}[auto_execok xvlog] -sv {*}$rtl_case > $sim/xvlog_out.log
        exec -ignorestderr {*}[auto_execok xelab] tb_saif -debug typical -s snap_$case > $sim/xelab_out.log
        exec -ignorestderr {*}[auto_execok xsim] snap_$case -tclbatch $sim/saif.tcl -log $out/sim_$case.log
    } err]} { note "$case simulation FAILED: $err (see $sim/xvlog.log, $sim/xelab.log, $out/sim_$case.log)"; cd $here; continue }
    if {![file exists $sim/act.saif]} { note "$case: no SAIF written (see $out/sim_$case.log)"; cd $here; continue }
    open_checkpoint $root/out_$build/routed.dcp
    if {[catch {read_saif -strip_path tb_saif/u_top $sim/act.saif} err]} { note "$case read_saif FAILED: $err" }
    report_power -file $out/power_saif_$case.rpt
    close_design
    note "$case OK"
    cd $here
}
note "ALL DONE"
