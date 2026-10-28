`timescale 1ns/1ps
module tb_uart;
    logic clk = 0, rst = 1, rx = 1; always #5 clk = ~clk;
    logic we; logic [2:0] sel; logic [15:0] addr; logic [255:0] data;
    uart_loader #(.CLKS_PER_BIT(16)) u (.clk, .rst, .rx, .ld_we(we), .ld_sel(sel), .ld_addr(addr), .ld_data(data));
    task automatic sendb(input logic [7:0] b);
        rx = 0; repeat (16) @(posedge clk);
        for (int i = 0; i < 8; i++) begin rx = b[i]; repeat (16) @(posedge clk); end
        rx = 1; repeat (16) @(posedge clk);
    endtask
    logic [255:0] ref_d; int nwe = 0;
    always @(posedge clk) if (we) begin nwe++;
        if (sel == 3'd4 && addr == 16'h1234 && data == ref_d) $display("PASS"); else $display("FAIL sel=%0d addr=%h data=%h", sel, addr, data); end
    initial begin
        for (int i = 0; i < 32; i++) ref_d[8*i +: 8] = 8'(i * 37 + 5);
        repeat (5) @(posedge clk); rst = 0; repeat (5) @(posedge clk);
        sendb(8'h00); sendb(8'hA5); sendb(8'h04); sendb(8'h34); sendb(8'h12);
        for (int i = 0; i < 32; i++) sendb(ref_d[8*i +: 8]);
        repeat (50) @(posedge clk); $display("writes=%0d", nwe); $finish;
    end
endmodule
