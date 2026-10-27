// Bit-exact check of a multi-sample power build (top_hush, NSMP samples on chip): logs every block write-back
// with its inference index and the cycles of each inference.  Run from the folder that holds the .hex files.
`timescale 1ns/1ps
module tb_pwr;
    parameter int GATE = 1, MF = 1, NSMP = 20, NEV = 65536;
    logic clk = 0, rn = 0; always #5 clk = ~clk;
    logic [7:0] led;
    top_hush #(.M(578), .N(256), .T(100), .K(4), .GATE(GATE), .MF(MF), .NEV(NEV), .NSMP(NSMP)) u_top (.clk100(clk), .cpu_resetn(rn), .led(led));
    int fd, inf = 0; longint c = 0, c0 = 0; logic dq = 0;
    always @(posedge clk) c++;
    always @(posedge clk) begin
        if (u_top.u_layer.out_valid) $fdisplay(fd, "S %0d %0d %0d %08h %0128h", inf, u_top.u_layer.out_t, u_top.u_layer.out_blk, u_top.u_layer.out_spk, u_top.u_layer.v_data);
        dq <= led[1];
        if (led[1] && !dq) begin $fdisplay(fd, "I %0d %0d", inf, c - c0); c0 = c; inf++; if (inf == NSMP) begin $fclose(fd); $finish; end end
    end
    initial begin fd = $fopen("pwr_out.txt", "w"); repeat (5) @(posedge clk); rn = 1; end
endmodule
