// Testbench for hush_net (A9.2): one inference from preloaded memories; logs
//   A <t> <blk> <spikes hex32> <state hex512>   (hidden layer, every block)
//   B <t> <spikes hex32> <state hex512>         (output layer)
//   R <class> <cycles start->done> <L1 cycles> <L1 col reads> <fifo peak>
`timescale 1ns/1ps
module tb_hush_net;
    parameter int M1 = 64, N1 = 64, N2 = 32, NOUT = 10, T = 8, K = 4, THETA = 64, THETA_H = 64, GATE = 1, MF = 1;
    parameter int NEV1 = 1024, NEV2 = 4096, FIFO_D = 32;
    parameter string OUT_FILE = "net_out.txt";
    logic clk = 0, rst = 1, start = 0;
    always #5 clk = ~clk;
    logic done, l1_valid, l2_valid;
    logic [7:0] cls;
    logic [15:0] l1_t, l1_blk, l2_t, peak;
    logic [31:0] l1_spk, l2_spk;
    logic [511:0] l1_v, l2_v;
    logic [47:0] cyc, l1c, l1cyc;
    hush_net #(.M1(M1), .N1(N1), .N2(N2), .NOUT(NOUT), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA_H), .GATE(GATE),
               .MF(MF), .NEV1(NEV1), .NEV2(NEV2), .FIFO_D(FIFO_D)) dut (
        .clk, .rst, .start, .smp(16'd0), .ld_we(1'b0), .ld_sel(3'd0), .ld_addr(16'd0), .ld_data(256'd0),
        .done, .cls, .l1_valid, .l1_t, .l1_blk, .l1_spk, .l1_v, .l2_valid, .l2_t, .l2_spk, .l2_v,
        .cnt_cycles(cyc), .l1_col_reads(l1c), .l1_cycles(l1cyc), .fifo_peak(peak));
    int fd;
    initial begin
        fd = $fopen(OUT_FILE, "w");
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        wait (done);
        @(posedge clk);
        $fdisplay(fd, "R %0d %0d %0d %0d %0d", cls, cyc, l1cyc, l1c, peak);
        $fclose(fd);
        $finish;
    end
    always @(posedge clk) if (l1_valid) $fdisplay(fd, "A %0d %0d %08h %0128h", l1_t, l1_blk, l1_spk, l1_v);
    always @(posedge clk) if (l2_valid) $fdisplay(fd, "B %0d %08h %0128h", l2_t, l2_spk, l2_v);
    initial begin #2000000000; $display("TIMEOUT"); $finish; end
endmodule
