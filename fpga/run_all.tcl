# One-shot Phase-3 build: BASE, HUSH-drop and HUSH-MF on XC7A100T (N-MNIST layer 578x256, T=100, k=4).
# Run from the Vivado Tcl Shell (Windows: Start menu -> "Vivado <ver> Tcl Shell"):
#     cd C:/path/to/hush_fpga/fpga
#     vivado -mode batch -source run_all.tcl
# or, inside an already open Vivado Tcl console:   cd .../hush_fpga/fpga ; source run_all.tcl
# Reports land in ../out_base, ../out_hush_drop, ../out_hush_mf ; a summary in ../out_summary.txt.
set here [file dirname [file normalize [info script]]]
set root [file normalize $here/..]
set hexdir $root/fpga/hex
set fp [open $root/out_summary.txt w]
puts $fp "vivado: [version -short]"
close $fp
foreach cfg {{0 0 base} {1 0 hush_drop} {1 1 hush_mf}} {
    lassign $cfg g m name
    set argv [list $hexdir $root/out_$name $g $m 578 256 100 4]
    set argc [llength $argv]
    puts "==== building $name (GATE=$g MF=$m) ===="
    if {[catch {source $here/build.tcl} err]} {
        set fp [open $root/out_summary.txt a]; puts $fp "$name FAILED: $err"; close $fp
    } else {
        set fp [open $root/out_summary.txt a]; puts $fp "$name OK"; close $fp
    }
    catch {close_project}
    cd $here
}
puts "ALL DONE - see $root/out_summary.txt"
