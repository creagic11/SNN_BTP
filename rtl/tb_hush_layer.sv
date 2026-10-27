// Testbench (run from the directory holding the .hex files): runs hush_layer once and logs every block write-back to OUT_FILE:
//   S <t> <blk> <spikes hex32> <state hex512>
// followed by a final counter line:  C <cycles> <col_reads> <word_reads> <awake_sub>
`timescale 1ns/1ps
module tb_hush_layer;
    parameter int M = 64, N = 64, T = 8, K = 3, THETA = 64, THETA_H = 64, GATE = 1, MF = 0, NEV = 1024;
    parameter string OUT_FILE = "rtl_out.txt";

    logic clk = 0, rst = 1, start = 0;
    always #5 clk = ~clk;

    logic done, out_valid, v_valid;
    logic [15:0] out_t, out_blk;
    logic [31:0] out_spk;
    logic [32*16-1:0] v_data;
    logic [47:0] cyc, colr, wordr, awk;

    hush_layer #(.M(M), .N(N), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA_H), .GATE(GATE), .MF(MF), .NEV(NEV),
                 .W_FILE("w.hex"), .P_FILE("p.hex"), .Q_FILE("q.hex"),
                 .EV_FILE("ev.hex"), .TS_FILE("ts.hex")) dut (
        .clk, .rst, .start, .smp(16'd0), .done, .out_valid, .out_t, .out_blk, .out_spk, .v_valid, .v_data,
        .cnt_cycles(cyc), .cnt_col_reads(colr), .cnt_word_reads(wordr), .cnt_awake_sub(awk));

    int fd;
    initial begin
        fd = $fopen(OUT_FILE, "w");
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        wait (done);
        @(posedge clk);
        $fdisplay(fd, "C %0d %0d %0d %0d", cyc, colr, wordr, awk);
        $fclose(fd);
        $finish;
    end

    always @(posedge clk) if ($test$plusargs("trace") && !rst)
        $display("%0t st=%0d t=%0d b=%0d etu_busy=%0d etu_go=%0d bank_ready=%b ptr=%0d end=%0d", $time,
                 dut.st, dut.t, dut.b, dut.etu_busy, dut.etu_go, dut.bank_ready, dut.etu_ptr, dut.etu_end);
    always @(posedge clk) if (out_valid) $fdisplay(fd, "S %0d %0d %08h %0128h", out_t, out_blk, out_spk, v_data);

    initial begin
        #500000000;
        $display("TIMEOUT");
        $finish;
    end
endmodule
