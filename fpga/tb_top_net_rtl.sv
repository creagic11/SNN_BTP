// RTL check of fpga/top_net.sv (STREAM = 0): back-to-back autorun over the on-chip samples. Run in a netpwr/<case>
// directory; prints "I <idx> <class> <cycles start->done>" per inference.
`timescale 1ns/1ps
module tb_top_net_rtl;
    parameter int NS = 3, GATE = 1, MF = 1;
    logic clk = 0, rn = 0;
    always #5 clk = ~clk;
    wire [7:0] led;
    top_net #(.GATE(GATE), .MF(MF), .NSMP(20), .NEV(65536)) u_top (.clk100(clk), .cpu_resetn(rn), .uart_rx(1'b1), .led(led));
    int inf = 0; logic dq = 0;
    always @(posedge clk) begin
        dq <= led[1];
        if (rn && led[1] && !dq) begin
            $display("I %0d %0d %0d", inf, u_top.u_net.cls, u_top.u_net.cnt_cycles);
            inf++;
            if (inf == NS) $finish;
        end
    end
    initial begin repeat (40) @(posedge clk); rn = 1; end
    initial begin #100000000; $display("TIMEOUT"); $finish; end
endmodule
