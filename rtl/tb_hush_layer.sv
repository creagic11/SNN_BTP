// Testbench (run from the directory holding the .hex files): runs hush_layer once and logs every block write-back to OUT_FILE:
//   S <t> <blk> <spikes hex32> <state hex512>
// followed by a final counter line:  C <cycles> <col_reads> <word_reads> <awake_sub>
`timescale 1ns/1ps
module tb_hush_layer;
    parameter int M = 64, N = 64, T = 8, K = 3, THETA = 64, THETA_H = 64, GATE = 1, MF = 0, NEV = 1024;
    parameter string OUT_FILE = "rtl_out.txt";
    parameter int LOAD = 0;          // 1: DUT memories start empty and are filled through the ld_* port
    localparam int G = N / 32, C = N / 8;
    localparam string NO = "none.hex";

    logic clk = 0, rst = 1, start = 0;
    always #5 clk = ~clk;

    logic done, out_valid, v_valid;
    logic [15:0] out_t, out_blk;
    logic [31:0] out_spk;
    logic [32*16-1:0] v_data;
    logic [47:0] cyc, colr, wordr, awk;

    hush_layer #(.M(M), .N(N), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA_H), .GATE(GATE), .MF(MF), .NEV(NEV),
                 .W0_FILE(LOAD ? NO : "w0.hex"), .W1_FILE(LOAD ? NO : "w1.hex"), .W2_FILE(LOAD ? NO : "w2.hex"),
                 .W3_FILE(LOAD ? NO : "w3.hex"), .P_FILE(LOAD ? NO : "p.hex"), .Q_FILE(LOAD ? NO : "q.hex"),
                 .EV_FILE(LOAD ? NO : "ev.hex"), .TS2_FILE(LOAD ? NO : "ts2.hex")) dut (
        .clk, .rst, .start, .smp(16'd0), .ld_we, .ld_sel, .ld_addr, .ld_data, .done, .out_valid, .out_t, .out_blk, .out_spk, .v_valid, .v_data,
        .cnt_cycles(cyc), .cnt_col_reads(colr), .cnt_word_reads(wordr), .cnt_awake_sub(awk));

    logic ld_we = 0; logic [2:0] ld_sel = 0; logic [15:0] ld_addr = 0; logic [255:0] ld_data = 0;
    logic [255:0] img_w [G*M];
    logic [8*C-1:0] img_p [M], img_q [M];
    logic [15:0] img_ev [NEV];
    logic [31:0] img_ts [T+1];
    task automatic ld(input int sel, input int a, input logic [255:0] d);
        @(negedge clk) begin ld_we = 1; ld_sel = 3'(sel); ld_addr = 16'(a); ld_data = d; end
        @(negedge clk) ld_we = 0;
    endtask

    int fd;
    initial begin
        fd = $fopen(OUT_FILE, "w");
        repeat (3) @(posedge clk);
        if (LOAD) begin                              // fill every table through the host load port
            $readmemh("w.hex", img_w); $readmemh("p.hex", img_p); $readmemh("q.hex", img_q);
            $readmemh("ev.hex", img_ev); $readmemh("ts2.hex", img_ts);
            for (int i = 0; i < G*M; i++) ld(0, i, img_w[i]);
            for (int i = 0; i < M; i++) begin ld(1, i, 256'(img_p[i])); ld(2, i, 256'(img_q[i])); end
            for (int i = 0; i < NEV; i++) if (img_ev[i] !== 16'hxxxx) ld(3, i, 256'(img_ev[i]));
            for (int i = 0; i <= T; i++) ld(4, i, 256'(img_ts[i]));
        end
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
