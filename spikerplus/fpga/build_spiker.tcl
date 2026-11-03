# A4.5: non-project Vivado flow for the Spiker+ generated network (VHDL-2008) in top_spiker, XC7A100T-1CSG324C,
# 100 MHz. Same steps and reports as fpga/build.tcl.
#   vivado -mode batch -source build_spiker.tcl -tclargs <generated output dir> <dir with spk.mem> <outdir> [NSMP]
set gen    [file normalize [lindex $argv 0]]
set memdir [file normalize [lindex $argv 1]]
set outdir [file normalize [lindex $argv 2]]
set NSMP   [expr {[llength $argv] > 3 ? [lindex $argv 3] : 20}]
set here [file dirname [file normalize [info script]]]
file mkdir $outdir
cd $memdir
read_vhdl -vhdl2008 [concat [glob $gen/*.vhd] [list $here/top_spiker.vhd]]
read_xdc $here/nexys_spiker.xdc
synth_design -top top_spiker -part xc7a100tcsg324-1 -generic NSMP=$NSMP -flatten_hierarchy rebuilt
report_utilization -hierarchical -file $outdir/util_synth_hier.rpt
opt_design
place_design
phys_opt_design
route_design
report_utilization -file $outdir/util.rpt
report_utilization -hierarchical -file $outdir/util_hier.rpt
report_timing_summary -max_paths 20 -file $outdir/timing.rpt
report_power -file $outdir/power_vectorless.rpt
catch {report_ram_utilization -file $outdir/ram_util.rpt}
write_checkpoint -force $outdir/routed.dcp
puts "DONE: reports in $outdir"
