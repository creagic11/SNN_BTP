// L1 gate-level SAIF testbench for the routed functional netlist of top_net (STREAM = 0, 20 samples on chip,
// autorun). Counts inferences on led[1] rising edges; prints "I <idx> <cycles>"; stops after NS inferences.
`timescale 1ns/1ps
module tb_netl1;
    localparam int NS = 20;
    logic clk = 0, rn = 0;
    always #5 clk = ~clk;
    wire [7:0] led;
    top_net u_top (.clk100(clk), .cpu_resetn(rn), .uart_rx(1'b1), .led(led));
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
