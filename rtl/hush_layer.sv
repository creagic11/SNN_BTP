// HUSH v2 — one fully connected LIF layer with envelope-gated output-side skipping.
//
// Computes exactly golden/hush.py::run_gated (resync=True, asleep_drive = MF ? "mean" : "none")
// when GATE=1, and run_ref when GATE=0 (all sub-blocks forced awake, envelope unit idle).
//
// Organisation
//   * N neurons in G = N/32 blocks of 32 lanes; each block = 4 sub-blocks of 8 lanes (C = N/8).
//   * Weight memory: block-column-major, word = 32 x INT8 = 256 bits, address = b*M + j.
//     One word = four 72-bit RAMB36 columns (8 weights + 8 spare bits each), one per sub-block;
//     a sub-block that sleeps inside an awake block keeps its column disabled (counted in col_reads).
//   * Proxy memory P and mean memory Q: one row per input j, C x INT8.
//   * Input events: ev_mem holds active input indices, timestep t occupies [ts[t], ts[t+1]), stored as ts2 pairs.
//   * Envelope unit (ETU) accumulates D_c(t+1) = sum P[j][c] and Qs_c(t+1) = sum Q[j][c] for the next
//     timestep while the block loop processes timestep t (double-buffered banks).
//   * State: G words of 32 x INT16 potentials. Asleep blocks get the leak (+ mean drive if MF) in a
//     short 2-cycle pass, so R_c = exact max V of every sub-block after every timestep.
//
// Memories (v5, 28 Oct 2026, A3b): every table is a writable block RAM with a host load port (ld_*), so
// synthesis cannot shrink it from its contents (as a ROM it trimmed INT8 weights to the 6 bits the trained
// values use). Initial contents come from $readmemh. Ports per memory:
//   w   : four 64-bit column RAMs (one per sub-block), read only when that sub-block is awake (per-column
//         enable; this is what cnt_col_reads counts); write = load port.
//   p,q : one read port (ETU) + load port.
//   ev  : true dual port: A = load / ETU read, B = block-loop read.
//   ts2 : {ts[t+1], ts[t]} pairs, true dual port like ev; the ETU's read takes one extra cycle (ETU = n+4).
// Results stream out of the out_* (spikes) and v_* (state write-back) ports.

module hush_layer #(
    parameter int M        = 64,      // inputs
    parameter int N        = 64,      // neurons, multiple of 32
    parameter int T        = 8,       // timesteps
    parameter int K        = 3,       // leak shift: L(x) = x - (x >>> K)
    parameter int THETA    = 64,
    parameter int THETA_H  = 64,      // gate threshold (exact mode: = THETA)
    parameter int GATE     = 1,       // 1 = HUSH, 0 = BASE (dense output side)
    parameter int MF       = 0,       // 1 = mean-field hibernation for asleep sub-blocks
    parameter int NEV      = 1024,    // event memory depth
    parameter int NSMP     = 1,       // samples stored on chip (power runs); sample s uses ts2[s*(T+1) +: T+1]
    parameter W0_FILE = "w0.hex",
    parameter W1_FILE = "w1.hex",
    parameter W2_FILE = "w2.hex",
    parameter W3_FILE = "w3.hex",
    parameter P_FILE = "p.hex",
    parameter Q_FILE = "q.hex",
    parameter EV_FILE = "ev.hex",
    parameter TS2_FILE = "ts2.hex"
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 start,
    input  logic [15:0]          smp,              // sample select (power runs with NSMP > 1); 0 otherwise
    // host load port (only while idle): sel 0 = w (all 4 columns), 1 = p, 2 = q, 3 = ev, 4 = ts2
    input  logic                 ld_we,
    input  logic [2:0]           ld_sel,
    input  logic [15:0]          ld_addr,
    input  logic [255:0]         ld_data,
    output logic                 done,
    // output spikes of one block at one timestep
    output logic                 out_valid,
    output logic [15:0]          out_t,
    output logic [15:0]          out_blk,
    output logic [31:0]          out_spk,
    // state write-back of one block (for bit-exact checking)
    output logic                 v_valid,
    output logic [32*16-1:0]     v_data,
    // performance counters
    output logic [47:0]          cnt_cycles,
    output logic [47:0]          cnt_col_reads,    // RAMB36 column reads (one per enabled sub-block per word)
    output logic [47:0]          cnt_word_reads,   // 256-bit weight words fetched
    output logic [47:0]          cnt_awake_sub     // sum over timesteps of awake sub-blocks
);
    localparam int G   = N / 32;
    localparam int C   = N / 8;
    localparam int VB  = 16;
    // accumulator width: exact sums before the clip. |L(V) + sum of up to M INT8 weights| <= 2^15 + 128*M
    localparam int AB  = $clog2((1 << 15) + 128 * M + 1) + 1;
    localparam int IW  = $clog2(M) > 0 ? $clog2(M) : 1;
    localparam int WAW = $clog2(G * M) > 0 ? $clog2(G * M) : 1;
    localparam int EAW = $clog2(NEV + 1);             // pointers reach NEV (one past the last event)
    localparam int TW  = $clog2(T + 1) > 0 ? $clog2(T + 1) : 1;
    localparam logic signed [AB-1:0] VMAX = (1 <<< (VB - 1)) - 1;
    localparam logic signed [AB-1:0] VMIN = -(1 <<< (VB - 1));

    // ---------------- memories ----------------
    localparam int NTS = NSMP * (T + 1);
    (* ram_style = "block" *) logic [8*C-1:0] p_mem  [M];
    (* ram_style = "block" *) logic [8*C-1:0] q_mem  [M];
    (* ram_style = "block", ram_decomp = "power" *) logic [15:0] ev_mem [NEV];
    (* ram_style = "block" *) logic [31:0] ts2_mem [NTS];
    (* ram_style = "distributed" *) logic [32*VB-1:0] st_mem [G];
    logic [G-1:0]       st_valid;                 // block written since start; unwritten blocks read as 0

    initial begin
        $readmemh(P_FILE, p_mem);
        if (MF) $readmemh(Q_FILE, q_mem);
        $readmemh(EV_FILE, ev_mem);
        $readmemh(TS2_FILE, ts2_mem);
    end
    wire ld_w  = ld_we && ld_sel == 3'd0;
    wire ld_p  = ld_we && ld_sel == 3'd1;
    wire ld_q  = ld_we && ld_sel == 3'd2;
    wire ld_ev = ld_we && ld_sel == 3'd3;
    wire ld_ts = ld_we && ld_sel == 3'd4;

    // ---------------- helpers ----------------
    function automatic logic signed [AB-1:0] sat(input logic signed [AB-1:0] x);
        if (x > VMAX)      sat = VMAX;
        else if (x < VMIN) sat = VMIN;
        else               sat = x;
    endfunction

    function automatic logic signed [VB-1:0] leakf(input logic signed [VB-1:0] v);
        leakf = v - (v >>> K);
    endfunction

    // sample base in ts2, captured at start (NSMP = 1: always 0)
    localparam int TSW = $clog2(NSMP*(T+1) + 1);
    localparam int SW  = (NSMP > 1) ? $clog2(NSMP) : 1;
    logic [TSW-1:0] tsb;

    // ---------------- envelope unit (ETU) ----------------
    logic signed [AB-1:0] dacc [2][C];
    logic signed [AB-1:0] qacc [2][C];
    logic [1:0]           bank_ready;
    logic                 etu_busy, etu_go, etu_bank;
    logic [TW-1:0]        etu_t;
    logic [EAW-1:0]       etu_ptr, etu_end;
    logic                 etu_v1, etu_v2;            // pipeline valids: ev data, P/Q data
    logic                 etu_ld;                    // ts2 word for the new timestep arrives this cycle
    logic [31:0]          etu_ts;
    logic [15:0]          etu_j;
    logic [8*C-1:0]       etu_prow, etu_qrow;
    logic                 etu_clear;                 // pulse: clear bank etu_bank (handled in ETU block)
    logic                 consume_bank_valid;
    logic                 consume_bank;

    always_ff @(posedge clk) begin
        if (rst) begin
            etu_busy <= 0; etu_v1 <= 0; etu_v2 <= 0; bank_ready <= 2'b00; etu_ld <= 0;
        end else begin
            if (consume_bank_valid) bank_ready[consume_bank] <= 1'b0;
            if (etu_go && !etu_busy) begin
                etu_busy <= 1;
                etu_ld   <= 1;                               // ts2 read issued this cycle (port A)
                for (int c = 0; c < C; c++) begin dacc[etu_bank][c] <= '0; qacc[etu_bank][c] <= '0; end
            end else if (etu_ld) begin
                etu_ld  <= 0;
                etu_ptr <= EAW'(etu_ts[15:0]);
                etu_end <= EAW'(etu_ts[31:16]);
            end else if (etu_busy) begin
                // stage 0: read event index (ev port A, below)
                etu_v1 <= (etu_ptr != etu_end);
                if (etu_ptr != etu_end) etu_ptr <= etu_ptr + 1'b1;
                // stage 1: read proxy rows (p/q RAMs, below)
                etu_v2 <= etu_v1;
                // stage 2: accumulate
                if (etu_v2) begin
                    for (int c = 0; c < C; c++) begin
                        dacc[etu_bank][c] <= dacc[etu_bank][c] + AB'($signed(etu_prow[8*c +: 8]));
                        qacc[etu_bank][c] <= qacc[etu_bank][c] + AB'($signed(etu_qrow[8*c +: 8]));
                    end
                end
                if (etu_ptr == etu_end && !etu_v1 && !etu_v2) begin
                    etu_busy <= 0;
                    bank_ready[etu_bank] <= 1'b1;
                end
            end
        end
    end

    // ETU memory ports
    wire etu_rd_ts = !rst && etu_go && !etu_busy;
    wire etu_rd_ev = !rst && etu_busy && !etu_ld && (etu_ptr != etu_end);
    wire etu_rd_pq = !rst && etu_busy && !etu_ld && etu_v1;
    wire [TSW-1:0] tsa_addr = ld_ts ? TSW'(ld_addr) : TSW'(tsb + etu_t);
    always_ff @(posedge clk)                                      // ts2 port A: load / ETU read
        if (ld_ts || etu_rd_ts) begin
            if (ld_ts) ts2_mem[tsa_addr] <= ld_data[31:0];
            etu_ts <= ts2_mem[tsa_addr];
        end
    wire [EAW-1:0] eva_addr = ld_ev ? EAW'(ld_addr) : etu_ptr;
    always_ff @(posedge clk)                                      // ev port A: load / ETU read
        if (ld_ev || etu_rd_ev) begin
            if (ld_ev) ev_mem[eva_addr] <= ld_data[15:0];
            etu_j <= ev_mem[eva_addr];
        end
    wire [IW-1:0] pa_addr = (ld_p || ld_q) ? IW'(ld_addr) : etu_j[IW-1:0];
    always_ff @(posedge clk) begin                                // p (and q) RAMs: load / ETU read
        if (ld_p) p_mem[pa_addr] <= ld_data[8*C-1:0];
        if (etu_rd_pq) etu_prow <= p_mem[pa_addr];
    end
    if (MF) begin : g_q
        always_ff @(posedge clk) begin
            if (ld_q) q_mem[pa_addr] <= ld_data[8*C-1:0];
            if (etu_rd_pq) etu_qrow <= q_mem[pa_addr];
        end
    end else begin : g_noq
        assign etu_qrow = '0;
    end

    // ---------------- main sequencer ----------------
    typedef enum logic [3:0] {S_IDLE, S_ETU0, S_COMBINE, S_BLK_SEL, S_BLK_LOAD, S_BLK_RUN, S_BLK_FIN,
                              S_SLP_LOAD, S_SLP_FIN, S_FIN2, S_STEP_END, S_DONE} state_t;
    state_t st;

    logic [TW-1:0]           t;
    logic [$clog2(G+1)-1:0]  b;
    logic                    cur_bank;
    logic [C-1:0]            gate;                   // sub-block gates for timestep t
    logic signed [VB-1:0]    R [C];                  // exact max V per sub-block after the last step
    logic signed [AB-1:0]    qs_cur [C];             // mean drive of timestep t per sub-block
    logic [EAW-1:0]          pe_ptr, pe_start, pe_end;
    logic [31:0]             pe_ts;                  // {ts[t+1], ts[t]} of the current timestep
    logic                    pe_v1, pe_v2;
    logic [15:0]             pe_j;
    wire  [255:0]            pe_w;
    assign pe_start = EAW'(pe_ts[15:0]);
    assign pe_end   = EAW'(pe_ts[31:16]);
    logic signed [AB-1:0]    acc [32];
    logic [32*VB-1:0]        st_rd;
    logic                    first;                  // state word arrives this cycle
    logic [3:0]              blk_gate;

    assign blk_gate = gate[4*b +: 4];

    // finalize: one hush_lane per lane (shared with the formal harness)
    logic signed [VB-1:0]    lv   [32];
    logic signed [AB-1:0]    usat [32];
    logic                    spk  [32];
    logic signed [VB-1:0]    vnew [32];
    for (genvar l = 0; l < 32; l++) begin : g_lane
        hush_lane #(.VB(VB), .AB(AB), .K(K), .THETA(THETA)) u_lane (
            .v(st_rd[VB*l +: VB]), .usum(acc[l]),
            .qs(MF ? qs_cur[4*b + l/8] : AB'(0)),
            .awake((st == S_BLK_FIN) && blk_gate[l/8]), .valid(st == S_BLK_FIN),
            .lv(lv[l]), .u(usat[l]), .spk(spk[l]), .vnew(vnew[l]));
    end

    // R refresh is pipelined (timing fix, 27 Oct): FIN registers the new state word, and the 8-input
    // max trees run from that register one cycle later. R is first read at the next step's COMBINE,
    // which is >= 2 cycles after any FIN (FIN -> SEL(b==G) -> STEP_END -> COMBINE), so the cycle count
    // and every output are unchanged.
    logic [32*VB-1:0]        fin_word;
    logic                    fin_v;
    logic [$clog2(G+1)-1:0]  fin_b;
    // Finalize is two stages (timing fix 2, 27 Oct): stage 1 (BLK_FIN / SLP_FIN) registers the lane's
    // saturated pre-reset potential U and the awake bits; stage 2 (FIN2) applies spike = awake & (U >= THETA)
    // and Vnew = U - THETA*spike, exactly hush_lane's formula, then writes back. +1 cycle per block.
    logic signed [AB-1:0]    u_r [32];
    logic [31:0]             aw_r;
    logic signed [VB-1:0]    vnew2 [32];
    logic                    spk2  [32];
    always_comb
        for (int l = 0; l < 32; l++) begin
            spk2[l]  = aw_r[l] && (u_r[l] >= THETA);
            vnew2[l] = VB'(u_r[l] - (spk2[l] ? AB'(THETA) : AB'(0)));
        end
    // Balanced, two-stage max tree (timing fix 3, 27 Oct): stage 1 reduces each sub-block's 8 values to 2
    // (two compare levels) into mid_*, stage 2 takes the max of those 2 into R. R is next read at COMBINE,
    // >= 3 cycles after the last block's FIN2, so outputs and cycle count are unchanged.
    function automatic logic signed [VB-1:0] smax(input logic signed [VB-1:0] a, input logic signed [VB-1:0] b2);
        return (a > b2) ? a : b2;
    endfunction
    logic signed [VB-1:0]    mid [4][2];
    logic                    mid_v;
    logic [$clog2(G+1)-1:0]  mid_b;
    logic signed [VB-1:0]    m2n [4][2];
    // named generate scopes (v5): unnamed loop scopes appear as "(null)" in Vivado's netlist, which read_saif rejects
    for (genvar s = 0; s < 4; s++) begin : g_mx
        for (genvar h = 0; h < 2; h++) begin : g_h
            assign m2n[s][h] = smax(smax($signed(fin_word[VB*(8*s + 4*h + 0) +: VB]), $signed(fin_word[VB*(8*s + 4*h + 1) +: VB])),
                                 smax($signed(fin_word[VB*(8*s + 4*h + 2) +: VB]), $signed(fin_word[VB*(8*s + 4*h + 3) +: VB])));
        end
    end
    // combine: one hush_envelope per sub-block (shared with the formal harness)
    logic [C-1:0] gate_next, env_gate;
    for (genvar c = 0; c < C; c++) begin : g_env
        logic signed [AB-1:0] e_unused;
        hush_envelope #(.VB(VB), .AB(AB), .K(K), .THETA_H(THETA_H)) u_env (
            .R(R[c]), .D(dacc[cur_bank][c]), .E(e_unused), .gate(env_gate[c]));
        assign gate_next[c] = GATE ? env_gate[c] : 1'b1;
    end

    // block-loop memory ports
    wire pe_rd_ts = !rst && (st == S_COMBINE) && (!(GATE || MF) || bank_ready[cur_bank]);
    wire pe_rd_ev = !rst && (st == S_BLK_RUN) && (pe_ptr != pe_end);
    wire pe_rd_w  = !rst && (st == S_BLK_RUN) && pe_v1;
    always_ff @(posedge clk) if (pe_rd_ts) pe_ts <= ts2_mem[TSW'(tsb + t)];   // ts2 port B
    always_ff @(posedge clk) if (pe_rd_ev) pe_j  <= ev_mem[pe_ptr];           // ev port B
    wire [WAW-1:0] wa_addr = ld_w ? WAW'(ld_addr) : WAW'(b * M + pe_j[IW-1:0]);
    for (genvar s = 0; s < 4; s++) begin : g_wcol                        // one RAM per sub-block column
        (* ram_style = "block", ram_decomp = "power" *) logic [63:0] mem [G*M];
        logic [63:0] q;
        if (s == 0) begin : g_i0 initial $readmemh(W0_FILE, mem); end
        if (s == 1) begin : g_i1 initial $readmemh(W1_FILE, mem); end
        if (s == 2) begin : g_i2 initial $readmemh(W2_FILE, mem); end
        if (s == 3) begin : g_i3 initial $readmemh(W3_FILE, mem); end
        always_ff @(posedge clk)
            if (ld_w || (pe_rd_w && blk_gate[s])) begin                // column enable = sub-block awake
                if (ld_w) mem[wa_addr] <= ld_data[64*s +: 64];
                q <= mem[wa_addr];
            end
        assign pe_w[64*s +: 64] = q;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            st <= S_IDLE; done <= 0; out_valid <= 0; v_valid <= 0; etu_go <= 0;
            consume_bank_valid <= 0;
            cnt_cycles <= 0; cnt_col_reads <= 0; cnt_word_reads <= 0; cnt_awake_sub <= 0;
            st_valid <= '0; fin_v <= 0; mid_v <= 0;
            for (int c = 0; c < C; c++) R[c] <= '0;
        end else begin
            out_valid <= 0; v_valid <= 0; etu_go <= 0; consume_bank_valid <= 0;
            fin_v <= 0; mid_v <= fin_v; mid_b <= fin_b;
            if (fin_v) for (int s = 0; s < 4; s++) for (int h = 0; h < 2; h++) mid[s][h] <= m2n[s][h];
            if (mid_v) for (int s = 0; s < 4; s++) R[4*mid_b + s] <= smax(mid[s][0], mid[s][1]);
            if (st != S_IDLE && st != S_DONE) cnt_cycles <= cnt_cycles + 1'b1;
            case (st)
                S_IDLE: if (start) begin
                    t <= 0; cur_bank <= 0; done <= 0;
                    tsb <= TSW'(smp) * TSW'(T + 1);
                    st_valid <= '0;                                  // new inference: V = 0, R = 0
                    for (int c = 0; c < C; c++) R[c] <= '0;
                    if (GATE || MF) begin etu_t <= 0; etu_bank <= 0; etu_go <= 1; st <= S_ETU0; end
                    else st <= S_COMBINE;
                end
                S_ETU0: if (bank_ready[0] && !etu_go) st <= S_COMBINE;
                S_COMBINE: begin
                    if (!(GATE || MF) || bank_ready[cur_bank]) begin
                        gate <= gate_next;
                        for (int c = 0; c < C; c++) qs_cur[c] <= qacc[cur_bank][c];
                        cnt_awake_sub <= cnt_awake_sub + $countones(gate_next);
                        consume_bank_valid <= (GATE || MF);
                        consume_bank       <= cur_bank;
                        // launch ETU for t+1 into the other bank, overlapped with this step's block loop
                        if ((GATE || MF) && (t + 1 < T)) begin etu_t <= t + 1; etu_bank <= ~cur_bank; etu_go <= 1; end
                        b <= 0;
                        st <= S_BLK_SEL;
                    end
                end
                S_BLK_SEL: begin
                    if (b == G) st <= S_STEP_END;
                    else begin
                        st_rd <= st_valid[b] ? st_mem[b] : '0;   // synchronous state read
                        st    <= (|blk_gate) ? S_BLK_LOAD : S_SLP_FIN;
                    end
                end
                S_BLK_LOAD: begin
                    for (int l = 0; l < 32; l++) acc[l] <= AB'(lv[l]);
                    pe_ptr <= pe_start; pe_v1 <= 0; pe_v2 <= 0;
                    st <= S_BLK_RUN;
                end
                S_BLK_RUN: begin
                    pe_v1 <= (pe_ptr != pe_end);
                    if (pe_ptr != pe_end) pe_ptr <= pe_ptr + 1'b1;   // ev port B read (below)
                    pe_v2 <= pe_v1;
                    if (pe_v1) begin                                 // weight column reads (below)
                        cnt_word_reads <= cnt_word_reads + 1'b1;
                        cnt_col_reads  <= cnt_col_reads + $countones(blk_gate);
                    end
                    if (pe_v2)
                        for (int l = 0; l < 32; l++)
                            if (blk_gate[l/8]) acc[l] <= acc[l] + AB'($signed(pe_w[8*l +: 8]));
                    if (pe_ptr == pe_end && !pe_v1 && !pe_v2) st <= S_BLK_FIN;
                end
                S_BLK_FIN, S_SLP_FIN: begin
                    for (int l = 0; l < 32; l++) begin
                        u_r[l]  <= usat[l];
                        aw_r[l] <= (st == S_BLK_FIN) && blk_gate[l/8];
                    end
                    st <= S_FIN2;
                end
                S_FIN2: begin
                    logic [32*VB-1:0] word;
                    logic [31:0] spk_w;
                    for (int l = 0; l < 32; l++) begin word[VB*l +: VB] = vnew2[l]; spk_w[l] = spk2[l]; end
                    st_mem[b] <= word;
                    st_valid[b] <= 1'b1;
                    fin_word <= word; fin_v <= 1'b1; fin_b <= b;
                    out_valid <= 1; out_t <= 16'(t); out_blk <= 16'(b); out_spk <= spk_w;
                    v_valid <= 1; v_data <= word;
                    b <= b + 1'b1;
                    st <= S_BLK_SEL;
                end
                S_STEP_END: begin
                    if (t + 1 == T) st <= S_DONE;
                    else begin t <= t + 1'b1; cur_bank <= ~cur_bank; st <= S_COMBINE; end
                end
                S_DONE: begin done <= 1; if (start) st <= S_IDLE; end
                default: st <= S_IDLE;
            endcase
        end
    end
endmodule
