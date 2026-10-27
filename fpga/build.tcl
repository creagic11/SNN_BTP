# Non-project Vivado flow for the HUSH layer on XC7A100T-1CSG324C.
#   vivado -mode batch -source build.tcl -tclargs <hexdir> <outdir> <GATE> <MF> [M N T K]
# <hexdir> holds w.hex p.hex q.hex ev.hex ts.hex (from rtl/sim/run_case.py write_mems).
set hexdir [file normalize [lindex $argv 0]]
set outdir [file normalize [lindex $argv 1]]
set gate   [lindex $argv 2]
set mf     [lindex $argv 3]
set M [expr {[llength $argv] > 4 ? [lindex $argv 4] : 578}]
set N [expr {[llength $argv] > 5 ? [lindex $argv 5] : 256}]
set T [expr {[llength $argv] > 6 ? [lindex $argv 6] : 100}]
set K [expr {[llength $argv] > 7 ? [lindex $argv 7] : 4}]
set here [file dirname [file normalize [info script]]]
file mkdir $outdir
cd $hexdir
read_verilog -sv [list $here/../rtl/hush_arith.sv $here/../rtl/hush_layer.sv $here/top_hush.sv]
read_xdc $here/nexys_a7_100t.xdc
synth_design -top top_hush -part xc7a100tcsg324-1 -generic M=$M -generic N=$N -generic T=$T -generic K=$K \
             -generic GATE=$gate -generic MF=$mf -flatten_hierarchy rebuilt
report_utilization -hierarchical -file $outdir/util_synth_hier.rpt
opt_design
place_design
phys_opt_design
route_design
report_utilization -file $outdir/util.rpt
report_utilization -hierarchical -file $outdir/util_hier.rpt
report_timing_summary -max_paths 20 -file $outdir/timing.rpt
report_power -file $outdir/power_vectorless.rpt
write_checkpoint -force $outdir/routed.dcp
write_bitstream -force $outdir/top_hush.bit
puts "DONE: reports in $outdir"
