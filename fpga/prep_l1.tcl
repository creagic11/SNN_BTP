# Laptop run L1 (10 Nov 2026), step 1 of run_l1.bat (Vivado batch). Output: ../out_l1/
#   netpwr/<case>   : whole network (top_net, STREAM = 0), 20 N-MNIST samples on chip -> build, routed functional
#                     netlist, xsim snapshot (simulation runs outside Vivado)   [A6.3 + whole-network power]
#   netstream/<case>: whole network in stream mode (STREAM = 1, ring of 1,024 events) -> timing/area only   [A9.5]
#   spiker          : Spiker+ generated 578-256-10 network in top_spiker, 20 samples -> build, netlist, snapshot [A4.5]
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set out  $root/out_l1
file mkdir $out
proc note {msg} { global out; set fp [open $out/summary.txt a]; puts $fp "[clock format [clock seconds] -format %H:%M:%S] $msg"; close $fp; puts $msg }
note "prep_l1 start, vivado [version -short]"
set glbl [file normalize $::env(XILINX_VIVADO)/data/verilog/src/glbl.v]
proc wns_of {d} { set fp [open $d/timing.rpt r]; set rpt [read $fp]; close $fp
    set w "?"; regexp {WNS\(ns\)[^\n]*\n[^\n]*\n\s*(-?[0-9.]+)} $rpt -> w; return $w }
proc snapshot {d tbfile tbtop netlist_extra} {
    global glbl here
    open_checkpoint $d/routed.dcp
    write_verilog -mode funcsim -force $d/net.v
    close_design
    cd $d
    exec -ignorestderr {*}[auto_execok xvlog] $d/net.v $glbl > $d/xvlog_net.log
    exec -ignorestderr {*}[auto_execok xvlog] -sv $tbfile > $d/xvlog_tb.log
    exec -ignorestderr {*}[auto_execok xelab] $tbtop glbl -L unisims_ver -timescale 1ns/1ps -debug typical -s snap_net > $d/xelab_out.log
    cd $here
    set fo [open $d/saif.tcl w]
    puts $fo "open_saif $d/act.saif"
    puts $fo "log_saif \[get_objects -r /$tbtop/u_top/*\]"
    puts $fo "run all"
    puts $fo "close_saif"
    puts $fo "quit"
    close $fo
}
# kind case GATE MF NSMP NEV STREAM
foreach cfg {{netpwr base 0 0 20 65536 0} {netpwr mf_gentle12 1 1 20 65536 0} {netpwr mf_gentler12 1 1 20 65536 0}
             {netpwr mf_aggr 1 1 20 65536 0} {netstream base 0 0 1 1024 1} {netstream mf_gentle12 1 1 1 1024 1}} {
    lassign $cfg kind name g m nsmp nev strm
    set d $out/$kind/$name
    file mkdir $d
    if {[file exists $d/routed.dcp]} { note "$kind/$name: reuse existing build" } else {
        set argv [list $here/$kind/$name $d $g $m $nsmp $nev $strm]
        set argc [llength $argv]
        if {[catch {source $here/build_net.tcl} err]} { note "$kind/$name build FAILED: $err"; catch {close_project}; cd $here; continue }
        catch {close_project}
        cd $here
        note "$kind/$name build OK  WNS=[wns_of $d] ns"
    }
    if {$kind ne "netpwr"} continue
    if {[catch {snapshot $d $here/tb_netl1.sv tb_netl1 {}} err]} { note "$kind/$name netlist/snapshot FAILED: $err"; catch {close_design}; cd $here; continue }
    note "$kind/$name netlist + snapshot OK"
}
# Spiker+ (A4.5)
set sp $root/spikerplus/fpga
set d $out/spiker
file mkdir $d
if {[file exists $d/routed.dcp]} { note "spiker: reuse existing build" } else {
    set argv [list $sp/gen $sp/gen $d 20]
    set argc [llength $argv]
    if {[catch {source $sp/build_spiker.tcl} err]} { note "spiker build FAILED: $err"; catch {close_project}; cd $here
    } else { catch {close_project}; cd $here; note "spiker build OK  WNS=[wns_of $d] ns" }
}
if {[file exists $d/routed.dcp]} {
    if {[catch {snapshot $d $sp/tb_spk_net.sv tb_spk_net {}} err]} { note "spiker netlist/snapshot FAILED: $err"; catch {close_design}; cd $here
    } else { note "spiker netlist + snapshot OK" }
}
note "prep_l1 done"
