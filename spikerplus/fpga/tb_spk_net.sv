// A4.5: gate-level testbench for the routed Spiker+ netlist (top_spiker). Counts inferences on led[1] rising
// edges and prints "I <idx> <cycles>" like fpga/tb_net.sv; stops after NS inferences.
`timescale 1ns/1ps
module tb_spk_net;
    localparam int NS = 20;
    logic clk = 0, rn = 0; always #5 clk = ~clk;
    wire [7:0] led;
    top_spiker u_top (.clk100(clk), .cpu_resetn(rn), .led(led));
    int inf = 0; longint c = 0, c0 = 0; logic dq = 1;
    always @(posedge clk) begin
        c++;
        if (led[1] && !dq) begin $display("I %0d %0d", inf, c - c0); c0 = c; inf++; if (inf == NS) $finish; end
        dq <= led[1];
    end
    initial begin repeat (40) @(posedge clk); rn = 1; end
endmodule
