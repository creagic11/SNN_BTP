// HUSH full network on chip (A9.2, 10 Nov 2026): hidden layer -> output layer -> integer class decision.
//
//   L1  hush_layer (M1 inputs, N1 neurons, GATE/MF as given): the hidden layer; its input events are preloaded (batch)
//       and it runs all T timesteps.
//   Spike FIFO + drain: every L1 block result (t, b, 32 spikes) enters a FIFO; the drain turns each set bit into an
//       event index 32*b + l and writes it into L2's event memory through L2's load port (one per cycle). When the
//       last block of timestep t is drained, it writes L2's ts2 entry {end, start} for t and sets avail = t + 1.
//       L1 is held before its next block while the FIFO is almost full (out_ready).
//   L2  hush_layer (N1 inputs, N2 = 32 neurons, GATE = MF = 0, STREAM = 1): the output layer, dense in both designs;
//       it starts timestep t only when t < avail, so it runs one timestep behind L1, overlapped with it.
//   Classifier: per output neuron i < NOUT, spike count and summed pre-reset potential U = Vnew + THETA*spike;
//       after L2's last timestep, argmax = golden.hush.predict (most spikes, then larger summed U, then lower index).
//
// Event order inside a timestep does not matter: the layer accumulates exact sums before the single clip.
//
// STREAM = 1 (A9.3, 10 Nov): live sensor input instead of preloaded events. Front-end:
//   raw DVS event (x, y, p) -> pooled index p*SIDE*SIDE + (y/POOL)*SIDE + x/POOL; dropped if already seen in this
//   window (the model's input is a 0/1 raster per window); accepted events and end-of-window markers go through a
//   small FIFO into L1's ring event memory (NEV1 entries, power of two) and ts2, written only when L1's port A is
//   free (ld_free). A marker closes window w: ts2[w] = {end, start}, avail = w + 1, and the seen-bitmap clears.
//   L1 (STREAM = 1, EVRING = 1) starts its envelope pass and its timestep w only when window w is closed.
//   An event is dropped (counted in drops) if the FIFO is full or the ring holds NEV1 events not yet consumed;
//   drops = 0 is required for a valid run. The host load port still loads weights and tables while idle.
`default_nettype none
module hush_net #(
    parameter int M1 = 578, N1 = 256, N2 = 32, NOUT = 10, T = 100, K = 4, THETA = 64, THETA_H = 64,
    parameter int GATE = 1, MF = 1, NEV1 = 4096, NEV2 = 4096, NSMP = 1, FIFO_D = 32,
    parameter int STREAM = 0, SIDE = 17, POOL = 2, IN_D = 64,
    parameter W0_FILE = "w0.hex", W1_FILE = "w1.hex", W2_FILE = "w2.hex", W3_FILE = "w3.hex",
    parameter P_FILE = "p.hex", Q_FILE = "q.hex", EV_FILE = "ev.hex", TS2_FILE = "ts2.hex",
    parameter O0_FILE = "o0.hex", O1_FILE = "o1.hex", O2_FILE = "o2.hex", O3_FILE = "o3.hex"
) (
    input  wire logic          clk,
    input  wire logic          rst,
    input  wire logic          start,
    input  wire logic [15:0]   smp,
    // host load port for L1 (as hush_layer; only while idle)
    input  wire logic          ld_we,
    input  wire logic [2:0]    ld_sel,
    input  wire logic [15:0]   ld_addr,
    input  wire logic [255:0]  ld_data,
    output logic               done,          // class valid; held until the next start
    output logic [7:0]         cls,
    // observation of both layers (bit-exact checks, LED fold)
    output logic               l1_valid,
    output logic [15:0]        l1_t, l1_blk,
    output logic [31:0]        l1_spk,
    output logic [32*16-1:0]   l1_v,
    output logic               l2_valid,
    output logic [15:0]        l2_t,
    output logic [31:0]        l2_spk,
    output logic [32*16-1:0]   l2_v,
    output logic [47:0]        cnt_cycles,    // start -> done
    output logic [47:0]        l1_col_reads,
    output logic [47:0]        l1_cycles,
    output logic [15:0]        fifo_peak,
    // live sensor port (STREAM = 1): one raw event or one end-of-window marker per cycle
    input  wire logic          ev_valid,
    input  wire logic [5:0]    ev_x, ev_y,
    input  wire logic          ev_p,
    input  wire logic          eow,
    output logic [31:0]        drops,
    output logic [15:0]        in_peak,       // peak input-FIFO occupancy
    output logic [15:0]        ring_peak      // peak ring occupancy (events accepted, not yet consumed)
);
    localparam int G1 = N1 / 32;
    // The layers leave DONE on a start pulse and need start again in IDLE (hush_layer protocol), so each net
    // start is a two-cycle pulse to the layers; in any other state the layers ignore it.
    logic start_q;
    always_ff @(posedge clk) start_q <= rst ? 1'b0 : start;
    wire lstart = start || start_q;
    localparam int FW = $clog2(FIFO_D);
    localparam string NO = "none.hex";

    // ---------------- sensor front-end (STREAM = 1) ----------------
    localparam int IW1 = $clog2(M1);
    localparam int RW  = $clog2(NEV1) + 1;               // ring pointer width (= L1's EAW for a power-of-two NEV1)
    localparam int IFW = $clog2(IN_D);
    logic          l1_free;
    logic [15:0]   l1_rd;
    logic          fe_we;
    logic [2:0]    fe_sel;
    logic [15:0]   fe_addr;
    logic [15:0]   fe_data;
    logic [15:0]   avail1, avail1_p;
    logic [M1-1:0] seen;
    logic [16:0]   inq [IN_D];                            // {eow, index}
    logic [IFW:0]  iq_w, iq_r, iq_n;
    logic [RW-1:0] acc_ptr, wptr1, wstart1, base1;
    logic [15:0]   win;
    logic          got_rd;                                // L1 has read ts2 of this inference (rd_ptr valid)
    assign iq_n = iq_w - iq_r;
    wire [15:0] pidx = 16'(ev_p) * 16'(SIDE * SIDE) + 16'(ev_y / POOL) * 16'(SIDE) + 16'(ev_x / POOL);
    wire [RW-1:0] occ = acc_ptr - (got_rd ? RW'(l1_rd) : base1);
    wire iq_full = (iq_n == (IFW+1)'(IN_D));
    assign fe_we   = (STREAM != 0) && (iq_n != 0) && l1_free;
    wire [16:0] iq_head = inq[iq_r[IFW-1:0]];
    assign fe_sel  = iq_head[16] ? 3'd4 : 3'd3;
    assign fe_addr = iq_head[16] ? win : 16'(wptr1);
    assign fe_data = iq_head[15:0];
    if (STREAM) begin : g_fe
        always_ff @(posedge clk) begin
            if (rst || start) begin
                iq_w <= '0; iq_r <= '0; seen <= '0; win <= '0; avail1 <= '0; avail1_p <= '0; got_rd <= 0;
                base1 <= acc_ptr; wstart1 <= wptr1; in_peak <= '0; ring_peak <= '0;
                if (rst) begin acc_ptr <= '0; wptr1 <= '0; base1 <= '0; wstart1 <= '0; drops <= '0; end
                else drops <= '0;
            end else begin
                avail1 <= avail1_p;
                if (l1_valid) got_rd <= 1;                      // first COMBINE has latched pe_ts
                if (16'(iq_n) > in_peak) in_peak <= 16'(iq_n);
                if (16'(occ) > ring_peak) ring_peak <= 16'(occ);
                // accept (one raw event or one marker per cycle)
                if (eow) begin
                    if (!iq_full) begin inq[iq_w[IFW-1:0]] <= {1'b1, 16'(acc_ptr)}; iq_w <= iq_w + 1'b1; end
                    else drops <= drops + 1'b1;
                    seen <= '0;
                end else if (ev_valid && !seen[pidx[IW1-1:0]]) begin
                    if (!iq_full && occ < RW'(NEV1)) begin
                        inq[iq_w[IFW-1:0]] <= {1'b0, pidx};
                        iq_w <= iq_w + 1'b1;
                        acc_ptr <= acc_ptr + 1'b1;
                        seen[pidx[IW1-1:0]] <= 1'b1;
                    end else drops <= drops + 1'b1;
                end
                // write into L1 (event -> ring, marker -> ts2[win] = {end, start})
                if (fe_we) begin
                    iq_r <= iq_r + 1'b1;
                    if (iq_head[16]) begin
                        wstart1 <= wptr1; win <= win + 1'b1; avail1_p <= win + 1'b1;
                    end else wptr1 <= wptr1 + 1'b1;
                end
            end
        end
    end else begin : g_nofe
        assign drops = '0; assign in_peak = '0; assign ring_peak = '0; assign avail1 = 16'hFFFF;
    end
    // L1 load port: front-end while streaming, host otherwise
    wire          l1_we   = fe_we || ld_we;
    wire [2:0]    l1_sel  = fe_we ? fe_sel : ld_sel;
    wire [15:0]   l1_addr = fe_we ? fe_addr : ld_addr;
    wire [255:0]  l1_data = fe_we ? (iq_head[16] ? 256'({16'(wptr1), 16'(wstart1)}) : 256'(fe_data)) : ld_data;

    // ---------------- L1 ----------------
    logic l1_done, l1_ready;
    logic [47:0] l1_wr, l1_aw;
    hush_layer #(.M(M1), .N(N1), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA_H), .GATE(GATE), .MF(MF),
                 .NEV(NEV1), .NSMP(NSMP), .STREAM(STREAM), .EVRING(STREAM),
                 .W0_FILE(W0_FILE), .W1_FILE(W1_FILE), .W2_FILE(W2_FILE), .W3_FILE(W3_FILE),
                 .P_FILE(P_FILE), .Q_FILE(Q_FILE), .EV_FILE(EV_FILE), .TS2_FILE(TS2_FILE)) u_l1 (
        .clk, .rst, .start(lstart), .smp, .ld_we(l1_we), .ld_sel(l1_sel), .ld_addr(l1_addr), .ld_data(l1_data), .done(l1_done),
        .avail(avail1), .out_ready(l1_ready), .ld_free(l1_free), .rd_ptr(l1_rd),
        .out_valid(l1_valid), .out_t(l1_t), .out_blk(l1_blk), .out_spk(l1_spk), .v_valid(), .v_data(l1_v),
        .cnt_cycles(l1_cycles), .cnt_col_reads(l1_col_reads), .cnt_word_reads(l1_wr), .cnt_awake_sub(l1_aw));

    // ---------------- spike FIFO ----------------
    logic [64:0] fifo [FIFO_D];   // {last, t[15:0], b[15:0], spikes[31:0]}
    logic [FW:0] wp, rp, cnt;
    assign cnt = wp - rp;
    // L1 checks out_ready in BLK_SEL, >= 3 cycles before that block's out_valid, and at most one block is in flight
    assign l1_ready = (cnt <= (FW+1)'(FIFO_D - 3));
    wire pop;

    // ---------------- drain -> L2 load port ----------------
    logic        d_busy;          // an entry is being drained
    logic        cur_last;
    logic [15:0] cur_t, cur_b;
    logic [31:0] cur_m;
    logic [15:0] wptr, tstart;    // next L2 event address; first event of the current timestep
    logic [15:0] avail, avail_p;   // avail follows avail_p one cycle later, after the ts2 write has landed
    logic        l2_we;
    logic [2:0]  l2_sel;
    logic [15:0] l2_addr;
    logic [255:0] l2_data;
    logic [4:0]  low;             // lowest set bit of cur_m
    always_comb begin
        low = '0;
        for (int l = 31; l >= 0; l--) if (cur_m[l]) low = 5'(l);
    end
    assign pop = !d_busy && (cnt != 0);

    always_ff @(posedge clk) begin
        if (rst) begin
            wp <= '0; rp <= '0; d_busy <= 0; wptr <= '0; tstart <= '0; avail <= '0; avail_p <= '0; l2_we <= 0; fifo_peak <= '0;
        end else begin
            l2_we <= 0;
            if (start) begin wp <= '0; rp <= '0; d_busy <= 0; wptr <= '0; tstart <= '0; avail <= '0; avail_p <= '0; fifo_peak <= '0; end
            else begin
                if (l1_valid) begin
                    fifo[wp[FW-1:0]] <= {(l1_blk == 16'(G1 - 1)), l1_t, l1_blk, l1_spk};
                    wp <= wp + 1'b1;
                end
                if (16'(cnt) > fifo_peak) fifo_peak <= 16'(cnt);
                avail <= avail_p;
                if (pop) begin {cur_last, cur_t, cur_b, cur_m} <= fifo[rp[FW-1:0]]; rp <= rp + 1'b1; d_busy <= 1; end
                else if (d_busy) begin
                    if (cur_m != 0) begin                                  // one event per cycle
                        l2_we <= 1; l2_sel <= 3'd3; l2_addr <= wptr;
                        l2_data <= 256'({cur_b[10:0], low});               // index = 32*b + l
                        wptr <= wptr + 1'b1;
                        cur_m[low] <= 1'b0;
                    end else begin
                        if (cur_last) begin                               // timestep complete: ts2[t] = {end, start}
                            l2_we <= 1; l2_sel <= 3'd4; l2_addr <= cur_t;
                            l2_data <= 256'({wptr, tstart});
                            tstart <= wptr;
                            avail_p <= cur_t + 1'b1;                      // L2 may read ts2[t] 2 edges later
                        end
                        d_busy <= 0;
                    end
                end
            end
        end
    end

    // ---------------- L2 ----------------
    logic l2_done, l2_ov;
    logic [15:0] l2_blk;
    logic [47:0] l2_c0, l2_c1, l2_c2, l2_c3;
    hush_layer #(.M(N1), .N(N2), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA), .GATE(0), .MF(0),
                 .NEV(NEV2), .NSMP(1), .STREAM(1),
                 .W0_FILE(O0_FILE), .W1_FILE(O1_FILE), .W2_FILE(O2_FILE), .W3_FILE(O3_FILE),
                 .P_FILE(NO), .Q_FILE(NO), .EV_FILE(NO), .TS2_FILE(NO)) u_l2 (
        .clk, .rst, .start(lstart), .smp(16'd0),
        .ld_we(l2_we), .ld_sel(l2_sel), .ld_addr(l2_addr), .ld_data(l2_data), .done(l2_done),
        .avail(avail), .out_ready(1'b1),
        .out_valid(l2_valid), .out_t(l2_t), .out_blk(l2_blk), .out_spk(l2_spk), .v_valid(l2_ov), .v_data(l2_v),
        .cnt_cycles(l2_c0), .cnt_col_reads(l2_c1), .cnt_word_reads(l2_c2), .cnt_awake_sub(l2_c3));

    // ---------------- classifier ----------------
    localparam int CW = 32;                      // |U| < 2^15, T <= 2^16 steps
    logic [15:0]          cnt_s [NOUT];
    logic signed [CW-1:0] usum  [NOUT];
    logic [7:0]           ci, best;
    logic                 cls_run, busy;
    logic [15:0]          n2;                    // output-layer timesteps finished in this inference
    always_ff @(posedge clk) begin
        if (rst) begin
            done <= 0; cls_run <= 0; busy <= 0; cnt_cycles <= '0; cls <= '0;
        end else begin
            if (busy) cnt_cycles <= cnt_cycles + 1'b1;
            if (start) begin
                done <= 0; busy <= 1; cls_run <= 0; cnt_cycles <= '0; n2 <= '0;
                for (int i = 0; i < NOUT; i++) begin cnt_s[i] <= '0; usum[i] <= '0; end
            end else begin
                if (l2_valid) n2 <= n2 + 1'b1;
                if (l2_valid)
                    for (int i = 0; i < NOUT; i++) begin
                        cnt_s[i] <= cnt_s[i] + 16'(l2_spk[i]);
                        usum[i]  <= usum[i] + CW'($signed(l2_v[16*i +: 16])) + (l2_spk[i] ? CW'(THETA) : CW'(0));
                    end
                if (busy && !cls_run && n2 == 16'(T) && l2_done) begin cls_run <= 1; ci <= 8'd1; best <= 8'd0; end
                if (cls_run && !done) begin
                    if (ci == 8'(NOUT)) begin cls <= best; done <= 1; busy <= 0; end
                    else begin
                        if (cnt_s[ci] > cnt_s[best] || (cnt_s[ci] == cnt_s[best] && usum[ci] > usum[best])) best <= ci;
                        ci <= ci + 1'b1;
                    end
                end
            end
        end
    end
endmodule
`default_nettype wire
