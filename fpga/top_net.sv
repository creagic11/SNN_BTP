// A9.5 / L1 (10 Nov 2026): board top for the WHOLE network (hush_net: hidden layer -> output layer -> class) on a
// Nexys A7-100T (XC7A100T-1CSG324C), 100 MHz.
//   STREAM = 0 (power builds): NSMP N-MNIST samples on chip, back-to-back inferences ("autorun"), as top_hush.
//   STREAM = 1 (timing/area builds of the real-time configuration): the sensor port is driven by a pseudo-random
//     event generator (LFSR; one event every 32 cycles (~94 per window, about the heaviest N-MNIST window), an end-of-window marker every WIN = 3000 cycles), the same harness
//     for BASE and HUSH; it only keeps the front-end and the stream logic in the netlist.
// LEDs: [0] heartbeat, [1] done, [7:2] XOR-fold of every hidden-layer and output-layer spike and state bit and of
// the class, so no part of either layer can be optimised away.
module top_net #(
    parameter int M = 578, parameter int N = 256, parameter int T = 100, parameter int K = 4,
    parameter int THETA = 64, parameter int GATE = 1, parameter int MF = 1, parameter int NEV = 4096,
    parameter int NSMP = 1, parameter int STREAM = 0, parameter int WIN = 3000
) (
    input  logic       clk100,
    input  logic       cpu_resetn,
    input  logic       uart_rx,
    output logic [7:0] led
);
    logic rst;
    logic [3:0] rst_sync = '1;
    always_ff @(posedge clk100) rst_sync <= {rst_sync[2:0], ~cpu_resetn};
    assign rst = rst_sync[3];

    logic        ld_we;
    logic [2:0]  ld_sel;
    logic [15:0] ld_addr;
    logic [255:0] ld_data;
    uart_loader u_ld (.clk(clk100), .rst, .rx(uart_rx), .ld_we, .ld_sel, .ld_addr, .ld_data);

    logic start, done, l1_valid, l2_valid;
    logic [7:0] cls;
    logic [15:0] l1_t, l1_blk, l2_t, fpk, inpk, rpk, smp;
    logic [31:0] l1_spk, l2_spk, drops;
    logic [511:0] l1_v, l2_v;
    logic [47:0] cyc, colr, l1cyc;
    logic ev_valid, ev_p, eow;
    logic [5:0] ev_x, ev_y;
    hush_net #(.M1(M), .N1(N), .N2(32), .NOUT(10), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA), .GATE(GATE), .MF(MF),
               .NEV1(NEV), .NEV2(4096), .NSMP(NSMP), .FIFO_D(32), .STREAM(STREAM),
               .O0_FILE("o0.hex"), .O1_FILE("o1.hex"), .O2_FILE("o2.hex"), .O3_FILE("o3.hex")) u_net (
        .clk(clk100), .rst, .start, .smp, .ld_we, .ld_sel, .ld_addr, .ld_data, .done, .cls,
        .l1_valid, .l1_t, .l1_blk, .l1_spk, .l1_v, .l2_valid, .l2_t, .l2_spk, .l2_v,
        .cnt_cycles(cyc), .l1_col_reads(colr), .l1_cycles(l1cyc), .fifo_peak(fpk),
        .ev_valid, .ev_x, .ev_y, .ev_p, .eow, .drops, .in_peak(inpk), .ring_peak(rpk));

    // pseudo-random sensor (STREAM = 1 only)
    logic [15:0] lfsr;
    logic [15:0] wcnt;
    logic [4:0]  ecnt;
    always_ff @(posedge clk100) begin
        if (rst || STREAM == 0) begin lfsr <= 16'hACE1; wcnt <= '0; ecnt <= '0; ev_valid <= 0; eow <= 0; end
        else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
            ecnt <= ecnt + 1'b1;
            wcnt <= (wcnt == 16'(WIN - 1)) ? '0 : wcnt + 1'b1;
            eow      <= (wcnt == 16'(WIN - 1));
            ev_valid <= (ecnt == 0) && (wcnt != 16'(WIN - 1));
            ev_x <= 6'(lfsr[5:0] % 34); ev_y <= 6'(lfsr[11:6] % 34); ev_p <= lfsr[12];
        end
    end

    function automatic logic [5:0] fold6(input logic [32+512-1:0] x);
        logic [5:0] f;
        f = '0;
        for (int i = 0; i < 32 + 512; i = i + 6) f = f ^ 6'(x >> i);
        return f;
    endfunction

    // autorun: start whenever the network is done (hush_net clears done on start), first start after reset
    logic [23:0] n_inf;
    logic        done_q, started;
    logic [5:0]  fx;
    always_ff @(posedge clk100) begin
        if (rst) begin start <= 0; n_inf <= '0; done_q <= 0; fx <= '0; smp <= '0; started <= 0; end
        else begin
            done_q <= done;
            start  <= (done && !start) || !started;
            if (!started) started <= 1;
            if (done && !done_q) begin
                n_inf <= n_inf + 1'b1;
                smp   <= (smp == 16'(NSMP - 1)) ? 16'd0 : smp + 16'd1;
            end
            fx <= fx ^ (l1_valid ? fold6({l1_spk, l1_v}) : 6'd0) ^ (l2_valid ? fold6({l2_spk, l2_v}) : 6'd0)
                     ^ ((done && !done_q) ? (cls[5:0] ^ 6'(drops)) : 6'd0);
        end
    end
    assign led = {fx, done, n_inf[12]};
endmodule
