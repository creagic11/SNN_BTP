// A3 gate-level SAIF testbench: drives the post-implementation functional netlist of top_hush (NSMP samples on
// chip, autorun) for NS inferences, counting done pulses on led[1]. Writes "I <idx> <cycles>" per inference.
// NS is baked in by run_power.tcl (Windows .bat wrappers split command-line arguments at '=').
`timescale 1ns/1ps
module tb_net;
    localparam int NS = 20;
    logic clk = 0, rn = 0;
    always #5 clk = ~clk;
    wire [7:0] led;
    top_hush u_top (.clk100(clk), .cpu_resetn(rn), .led(led));
    longint c = 0, c0 = 0; int inf = 0; logic dq = 0;
    always @(posedge clk) c++;
    always @(posedge clk) begin
        dq <= led[1];
        if (rn && led[1] && !dq) begin
            $display("I %0d %0d", inf, c - c0); c0 = c; inf++;
            if (inf == NS) $finish;
        end
    end
    initial begin repeat (40) @(posedge clk); rn = 1; c0 = c; end   // > 100 ns GSR of glbl
endmodule
