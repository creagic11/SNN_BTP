# A3b (28 Oct 2026): hush_layer v5 (writable RAMs with a load port, per-column weight-RAM enables, ts2 pairs in
# block RAM, named generate scopes). Rebuilds everything from the same RTL, unattended; called by run_v5.bat.
#   (1) timing/area builds, 1 sample on chip (as in the paper table): base, hush_drop, hush_mf -> ../out_v5c/timing/
#   (2) power builds, 20 N-MNIST samples on chip: base, mf_gentle, mf_aggr -> ../out_v5c/pwr/
#       + routed functional netlist + compiled xsim snapshot (simulation itself runs outside Vivado, see run_v5.bat)
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set out  $root/out_v5c
file mkdir $out/timing $out/pwr
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp "[clock format [clock seconds] -format %H:%M:%S] $msg"; close $fp; puts $msg }
note "prep_v5 start, vivado [version -short]"
set glbl [file normalize $::env(XILINX_VIVADO)/data/verilog/src/glbl.v]
foreach cfg {{timing base 0 0 hex 1 4096} {timing hush_drop 1 0 hex 1 4096} {timing hush_mf 1 1 hex 1 4096}
             {pwr base 0 0 pwr/base 20 65536} {pwr mf_gentle 1 1 pwr/mf_gentle 20 65536} {pwr mf_aggr 1 1 pwr/mf_aggr 20 65536}} {
    lassign $cfg kind name g m hex nsmp nev
    set d $out/$kind/$name
    file mkdir $d
    if {[file exists $d/routed.dcp]} { note "$kind/$name: reuse existing build" } else {
        set argv [list $here/$hex $d $g $m 578 256 100 4 $nsmp $nev]
        set argc [llength $argv]
        if {[catch {source $here/build.tcl} err]} { note "$kind/$name build FAILED: $err"; catch {close_project}; cd $here; continue }
        catch {close_project}
        cd $here
        set fp [open $d/timing.rpt r]; set rpt [read $fp]; close $fp
        set wns "?"; regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s*(-?[0-9.]+)} $rpt -> wns
        note "$kind/$name build OK  WNS=$wns ns"
    }
    if {$kind ne "pwr"} continue
    if {[catch {
        open_checkpoint $d/routed.dcp
        write_verilog -mode funcsim -force $d/net.v
        close_design
        cd $d
        exec -ignorestderr {*}[auto_execok xvlog] $d/net.v $glbl > $d/xvlog_net.log
        exec -ignorestderr {*}[auto_execok xvlog] -sv $here/tb_net.sv > $d/xvlog_tb.log
        exec -ignorestderr {*}[auto_execok xelab] tb_net glbl -L unisims_ver -timescale 1ns/1ps -debug typical -s snap_net > $d/xelab_out.log
        cd $here
    } err]} { note "$kind/$name netlist/snapshot FAILED: $err"; catch {close_design}; cd $here; continue }
    set fo [open $d/saif.tcl w]
    puts $fo "open_saif $d/act.saif"
    puts $fo "log_saif \[get_objects -r /tb_net/u_top/*\]"
    puts $fo "run all"
    puts $fo "close_saif"
    puts $fo "quit"
    close $fo
    note "$kind/$name netlist + snapshot OK"
}
note "prep_v5 done"
