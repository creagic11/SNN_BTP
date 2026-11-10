# L1 (10 Nov 2026): non-project Vivado flow for the whole network (top_net / hush_net) on XC7A100T-1CSG324C.
#   vivado -mode batch -source build_net.tcl -tclargs <hexdir> <outdir> <GATE> <MF> <NSMP> <NEV> <STREAM>
# <hexdir> holds w0..w3 p q ev ts2 o0..o3 none.hex (scripts/make_net_hex.py: fpga/netpwr/<case>, fpga/netstream/<case>).
set hexdir [file normalize [lindex $argv 0]]
set outdir [file normalize [lindex $argv 1]]
set gate   [lindex $argv 2]
set mf     [lindex $argv 3]
set NSMP   [lindex $argv 4]
set NEV    [lindex $argv 5]
set STREAM [lindex $argv 6]
set here [file dirname [file normalize [info script]]]
file mkdir $outdir
cd $hexdir
read_verilog -sv [list $here/../rtl/hush_arith.sv $here/../rtl/hush_layer.sv $here/../rtl/hush_net.sv \
                       $here/uart_loader.sv $here/top_net.sv]
read_xdc $here/nexys_a7_100t.xdc
synth_design -top top_net -part xc7a100tcsg324-1 -generic GATE=$gate -generic MF=$mf -generic NSMP=$NSMP \
             -generic NEV=$NEV -generic STREAM=$STREAM -flatten_hierarchy rebuilt
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
