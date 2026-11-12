# Implementation run L2 (prepared 10 Nov 2026), Vivado batch, ~1-1.5 h. Output: ../out_l2/
#   spiker_hi          : Spiker+ with high-effort directives (does it close 100 MHz?)            [A4.5 fairness]
#   netstream/<case>   : stream-mode builds again with the marker-reserve fix (IN_D 128, EVQ 64) [A9.5]
#   netpwr/base_ctrl   : power build of the paper's BASE (22-epoch control weights) + netlist + xsim snapshot
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set out  $root/out_l2
file mkdir $out
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp "[clock format [clock seconds] -format %H:%M:%S] $msg"; close $fp; puts $msg }
proc wns_of {d} { set fp [open $d/timing.rpt r]; set rpt [read $fp]; close $fp
    set w "?"; regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s*(-?[0-9.]+)} $rpt -> w; return $w }
note "prep_l2 start, vivado [version -short]"
set glbl [file normalize $::env(XILINX_VIVADO)/data/verilog/src/glbl.v]
set d $out/netpwr/base_ctrl
file mkdir $d
set argv [list $here/netpwr/base_ctrl $d 0 0 20 65536 0]; set argc [llength $argv]
if {[catch {source $here/build_net.tcl} err]} { note "netpwr/base_ctrl build FAILED: $err" } else {
    catch {close_project}; cd $here
    note "netpwr/base_ctrl build OK  WNS=[wns_of $d] ns"
    if {[catch {
        open_checkpoint $d/routed.dcp
        write_verilog -mode funcsim -force $d/net.v
        close_design
        cd $d
        exec -ignorestderr {*}[auto_execok xvlog] $d/net.v $glbl > $d/xvlog_net.log
        exec -ignorestderr {*}[auto_execok xvlog] -sv $here/tb_netl1.sv > $d/xvlog_tb.log
        exec -ignorestderr {*}[auto_execok xelab] tb_netl1 glbl -L unisims_ver -timescale 1ns/1ps -debug typical -s snap_net > $d/xelab_out.log
        cd $here
        set fo [open $d/saif.tcl w]
        puts $fo "open_saif $d/act.saif"; puts $fo "log_saif \[get_objects -r /tb_netl1/u_top/*\]"
        puts $fo "run all"; puts $fo "close_saif"; puts $fo "quit"; close $fo
    } err]} { note "netpwr/base_ctrl netlist/snapshot FAILED: $err"; catch {close_design}; cd $here } else { note "netpwr/base_ctrl netlist + snapshot OK" }
}
catch {close_project}; cd $here
foreach cfg {{base 0 0} {mf_gentle12 1 1}} {
    lassign $cfg name g m
    set d $out/netstream/$name
    file mkdir $d
    set argv [list $here/netstream/$name $d $g $m 1 1024 1]; set argc [llength $argv]
    if {[catch {source $here/build_net.tcl} err]} { note "netstream/$name build FAILED: $err" } else { note "netstream/$name build OK  WNS=[wns_of $d] ns" }
    catch {close_project}; cd $here
}
# Spiker+ last: build_spiker_hi.tcl redefines 'here'
set sp $root/spikerplus/fpga
set d $out/spiker_hi
set argv [list $sp/gen $sp/gen $d 20]; set argc [llength $argv]
if {[catch {source $sp/build_spiker_hi.tcl} err]} { note "spiker_hi build FAILED: $err" } else { note "spiker_hi build OK  WNS=[wns_of $d] ns" }
catch {close_project}; 
note "prep_l2 done"
