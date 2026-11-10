// Testbench for hush_net in STREAM mode (A9.3/A9.4): replays a sensor stimulus file and logs, per inference,
//   A/B lines as tb_hush_net, plus
//   K <window> <cycle the end-of-window marker was presented>
//   L <window> <cycle the output layer finished that window>
//   R <class> <cycles start->done> <drops> <input-FIFO peak> <ring peak> <cycle of done>
// Stimulus (STIM_FILE): one line per item, sorted by cycle (>= 1 apart): "<cycle> 0 <x> <y> <p>" (event) or
// "<cycle> 1 0 0 0" (end of window). Cycle 0 = the first cycle after start.
`timescale 1ns/1ps
module tb_hush_stream;
    parameter int M1 = 578, N1 = 256, N2 = 32, NOUT = 10, T = 100, K = 4, THETA = 64, THETA_H = 64, GATE = 1, MF = 1;
    parameter int NEV1 = 1024, NEV2 = 4096, FIFO_D = 32, IN_D = 64, SIDE = 17, POOL = 2;
    parameter string STIM_FILE = "stim.txt";
    parameter string OUT_FILE = "stream_out.txt";
    logic clk = 0, rst = 1, start = 0;
    always #5 clk = ~clk;
    logic done, l1_valid, l2_valid;
    logic [7:0] cls;
    logic [15:0] l1_t, l1_blk, l2_t, peak, in_peak, ring_peak;
    logic [31:0] l1_spk, l2_spk, drops;
    logic [511:0] l1_v, l2_v;
    logic [47:0] cyc, l1c, l1cyc;
    logic ev_valid = 0, ev_p = 0, eow = 0;
    logic [5:0] ev_x = 0, ev_y = 0;
    hush_net #(.M1(M1), .N1(N1), .N2(N2), .NOUT(NOUT), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA_H), .GATE(GATE),
               .MF(MF), .NEV1(NEV1), .NEV2(NEV2), .FIFO_D(FIFO_D), .STREAM(1), .SIDE(SIDE), .POOL(POOL), .IN_D(IN_D),
               .EV_FILE("none.hex"), .TS2_FILE("none.hex")) dut (
        .clk, .rst, .start, .smp(16'd0), .ld_we(1'b0), .ld_sel(3'd0), .ld_addr(16'd0), .ld_data(256'd0),
        .done, .cls, .l1_valid, .l1_t, .l1_blk, .l1_spk, .l1_v, .l2_valid, .l2_t, .l2_spk, .l2_v,
        .cnt_cycles(cyc), .l1_col_reads(l1c), .l1_cycles(l1cyc), .fifo_peak(peak),
        .ev_valid, .ev_x, .ev_y, .ev_p, .eow, .drops, .in_peak, .ring_peak);
    int fd, sf, r, c, typ, x, y, p, nw;
    longint now;
    initial begin
        fd = $fopen(OUT_FILE, "w");
        sf = $fopen(STIM_FILE, "r");
        repeat (3) @(posedge clk);
        @(negedge clk) rst = 0;
        @(negedge clk) start = 1;
        @(negedge clk) start = 0;
        now = 0; nw = 0;
        r = 5;
        while (!$feof(sf) && r == 5) begin
            r = $fscanf(sf, "%d %d %d %d %d\n", c, typ, x, y, p);
            if (r == 5) begin
            while (now < c) begin @(negedge clk); now++; end
            ev_valid = (typ == 0); eow = (typ == 1); ev_x = 6'(x); ev_y = 6'(y); ev_p = p[0];
            if (typ == 1) begin $fdisplay(fd, "K %0d %0d", nw, now); nw++; end
            @(negedge clk); now++;
            ev_valid = 0; eow = 0;
            end
        end
        wait (done);
        @(posedge clk);
        $fdisplay(fd, "R %0d %0d %0d %0d %0d %0d", cls, cyc, drops, in_peak, ring_peak, cyc);
        $fclose(fd);
        $finish;
    end
    always @(posedge clk) if (l1_valid) $fdisplay(fd, "A %0d %0d %08h %0128h", l1_t, l1_blk, l1_spk, l1_v);
    always @(posedge clk) if (l2_valid) begin
        $fdisplay(fd, "B %0d %08h %0128h", l2_t, l2_spk, l2_v);
        $fdisplay(fd, "L %0d %0d", l2_t, now);
    end
    parameter longint TIMEOUT_CYC = 200000000;
    initial begin #(TIMEOUT_CYC * 10); $display("TIMEOUT"); $finish; end
endmodule
