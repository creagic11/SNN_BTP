# A3 (proper flow): gate-level SAIF power for BASE, HUSH-MF gentle and HUSH-MF aggressive on the XC7A100T.
# One command, unattended (~1.5-3 h). From the Vivado Tcl Shell:
#     cd C:/Users/Anubhav/hush_fpga/fpga
#     vivado -mode batch -source run_power.tcl
# Per case: (1) build with NSMP = 20 on-chip N-MNIST samples (autorun steps through them); (2) write the routed
# functional netlist; (3) xsim the netlist over the 20 samples, recording switching activity (SAIF); (4) annotate
# the routed design and report power. SAIF names come from the netlist itself, so they match the routed design.
# Outputs: ../out_pwr/summary.txt, ../out_pwr/<case>/power_saif.rpt, sim.log, util.rpt, timing.rpt, read_saif.log
set NSMP 20
set NEV 65536
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set out  $root/out_pwr
file mkdir $out
set fp [open $out/summary.txt w]; puts $fp "vivado: [version -short]  samples on chip: $NSMP  started: [clock format [clock seconds]]"; close $fp
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp "[clock format [clock seconds] -format %H:%M:%S] $msg"; close $fp; puts $msg }
set glbl [file normalize $::env(XILINX_VIVADO)/data/verilog/src/glbl.v]

foreach cfg {{base 0 0} {mf_gentle 1 1} {mf_aggr 1 1}} {
    lassign $cfg case g m
    set d $out/$case
    file mkdir $d
    # (1) build
    if {![file exists $d/routed.dcp]} {
        set argv [list $here/pwr/$case $d $g $m 578 256 100 4 $NSMP $NEV]
        set argc [llength $argv]
        if {[catch {source $here/build.tcl} err]} { note "$case build FAILED: $err"; catch {close_project}; cd $here; continue }
        catch {close_project}
        cd $here
        note "$case build OK"
    } else { note "$case: reuse existing build" }
    # (2) netlist
    if {[catch {
        open_checkpoint $d/routed.dcp
        write_verilog -mode funcsim -force $d/net.v
        close_design
    } err]} { note "$case netlist FAILED: $err"; catch {close_design}; continue }
    # (3) gate-level simulation with SAIF
    cd $d
    set fo [open $d/saif.tcl w]
    puts $fo "open_saif $d/act.saif"
    puts $fo "log_saif \[get_objects -r /tb_net/u_top/*\]"
    puts $fo "run all"
    puts $fo "close_saif"
    puts $fo "quit"
    close $fo
    if {[catch {
        exec -ignorestderr {*}[auto_execok xvlog] $d/net.v $glbl > $d/xvlog_net.log
        exec -ignorestderr {*}[auto_execok xvlog] -sv $here/tb_net.sv > $d/xvlog_tb.log
        exec -ignorestderr {*}[auto_execok xelab] tb_net glbl -L unisims_ver -timescale 1ns/1ps -debug typical -s snap_net > $d/xelab_out.log
        exec -ignorestderr {*}[auto_execok xsim] snap_net -tclbatch $d/saif.tcl -log $d/sim.log
    } err]} { note "$case simulation FAILED: $err (see $d/xvlog.log, $d/xelab.log, $d/sim.log)"; cd $here; continue }
    if {![file exists $d/act.saif]} { note "$case: no SAIF written (see $d/sim.log)"; cd $here; continue }
    note "$case simulation OK"
    # (4) power
    if {[catch {
        open_checkpoint $d/routed.dcp
        read_saif -strip_path tb_net/u_top $d/act.saif -out_file $d/read_saif.log
        report_power -file $d/power_saif.rpt
        close_design
    } err]} { note "$case power FAILED: $err"; catch {close_design}; cd $here; continue }
    note "$case power OK"
    cd $here
}
note "ALL DONE"
