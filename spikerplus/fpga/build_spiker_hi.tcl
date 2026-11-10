# L2 (10 Nov 2026): Spiker+ build with Vivado's high-effort directives, to check whether it closes 100 MHz
# (L1, default directives: WNS -0.241 ns). Same sources, constraints and reports as build_spiker.tcl.
#   vivado -mode batch -source build_spiker_hi.tcl -tclargs <generated output dir> <dir with spk.mem> <outdir> [NSMP]
set gen    [file normalize [lindex $argv 0]]
set memdir [file normalize [lindex $argv 1]]
set outdir [file normalize [lindex $argv 2]]
set NSMP   [expr {[llength $argv] > 3 ? [lindex $argv 3] : 20}]
set here [file dirname [file normalize [info script]]]
file mkdir $outdir
cd $memdir
read_vhdl -vhdl2008 [concat [glob $gen/*.vhd] [list $here/top_spiker.vhd]]
read_xdc $here/nexys_spiker.xdc
synth_design -top top_spiker -part xc7a100tcsg324-1 -generic NSMP=$NSMP -flatten_hierarchy rebuilt -directive PerformanceOptimized
opt_design -directive Explore
place_design -directive ExtraTimingOpt
phys_opt_design -directive AggressiveExplore
route_design -directive AggressiveExplore
phys_opt_design -directive AggressiveExplore
report_utilization -file $outdir/util.rpt
report_utilization -hierarchical -file $outdir/util_hier.rpt
report_timing_summary -max_paths 20 -file $outdir/timing.rpt
report_power -file $outdir/power_vectorless.rpt
write_checkpoint -force $outdir/routed.dcp
puts "DONE: reports in $outdir"
