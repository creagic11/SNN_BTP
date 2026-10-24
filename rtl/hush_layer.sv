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
//   * Input events: ev_mem holds active input indices, timestep t occupies [ts_mem[t], ts_mem[t+1]).
//   * Envelope unit (ETU) accumulates D_c(t+1) = sum P[j][c] and Qs_c(t+1) = sum Q[j][c] for the next
//     timestep while the block loop processes timestep t (double-buffered banks).
//   * State: G words of 32 x INT16 potentials. Asleep blocks get the leak (+ mean drive if MF) in a
//     short 2-cycle pass, so R_c = exact max V of every sub-block after every timestep.
//
// Simulation-oriented top: memories are initialised with $readmemh, results stream out of the
// out_* (spikes) and v_* (state write-back) ports. An AXI wrapper for the board comes later.

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
    parameter W_FILE = "w.hex",
    parameter P_FILE = "p.hex",
    parameter Q_FILE = "q.hex",
    parameter EV_FILE = "ev.hex",
    parameter TS_FILE = "ts.hex"
) (
    input  logic                 clk,
    input  logic                 rst,
    input  logic                 start,
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
    logic [255:0]       w_mem  [G*M];
    logic [8*C-1:0]     p_mem  [M];
    logic [8*C-1:0]     q_mem  [M];
    logic [15:0]        ev_mem [NEV];
    logic [15:0]        ts_mem [T+1];
    (* ram_style = "distributed" *) logic [32*VB-1:0] st_mem [G];
    logic [G-1:0]       st_valid;                 // block written since start; unwritten blocks read as 0

    initial begin
        $readmemh(W_FILE, w_mem);
        $readmemh(P_FILE, p_mem);
        if (MF) $readmemh(Q_FILE, q_mem);
        $readmemh(EV_FILE, ev_mem);
        $readmemh(TS_FILE, ts_mem);
    end

    // ---------------- helpers ----------------
    function automatic logic signed [AB-1:0] sat(input logic signed [AB-1:0] x);
        if (x > VMAX)      sat = VMAX;
        else if (x < VMIN) sat = VMIN;
        else               sat = x;
    endfunction

    function automatic logic signed [VB-1:0] leakf(input logic signed [VB-1:0] v);
        leakf = v - (v >>> K);
    endfunction

    // ---------------- envelope unit (ETU) ----------------
    logic signed [AB-1:0] dacc [2][C];
    logic signed [AB-1:0] qacc [2][C];
    logic [1:0]           bank_ready;
    logic                 etu_busy, etu_go, etu_bank;
    logic [TW-1:0]        etu_t;
    logic [EAW-1:0]       etu_ptr, etu_end;
    logic                 etu_v1, etu_v2;            // pipeline valids: ev data, P/Q data
    logic [15:0]          etu_j;
    logic [8*C-1:0]       etu_prow, etu_qrow;
    logic                 etu_clear;                 // pulse: clear bank etu_bank (handled in ETU block)
    logic                 consume_bank_valid;
    logic                 consume_bank;

    always_ff @(posedge clk) begin
        if (rst) begin
            etu_busy <= 0; etu_v1 <= 0; etu_v2 <= 0; bank_ready <= 2'b00;
        end else begin
            if (consume_bank_valid) bank_ready[consume_bank] <= 1'b0;
            if (etu_go && !etu_busy) begin
                etu_busy <= 1;
                etu_ptr  <= ts_mem[etu_t][EAW-1:0];
                etu_end  <= ts_mem[etu_t + 1][EAW-1:0];
                for (int c = 0; c < C; c++) begin dacc[etu_bank][c] <= '0; qacc[etu_bank][c] <= '0; end
            end else if (etu_busy) begin
                // stage 0: read event index
                etu_v1 <= (etu_ptr != etu_end);
                if (etu_ptr != etu_end) begin
                    etu_j   <= ev_mem[etu_ptr];
                    etu_ptr <= etu_ptr + 1'b1;
                end
                // stage 1: read proxy rows
                etu_v2 <= etu_v1;
                if (etu_v1) begin
                    etu_prow <= p_mem[etu_j[IW-1:0]];
                    etu_qrow <= MF ? q_mem[etu_j[IW-1:0]] : '0;
                end
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

    // ---------------- main sequencer ----------------
    typedef enum logic [3:0] {S_IDLE, S_ETU0, S_COMBINE, S_BLK_SEL, S_BLK_LOAD, S_BLK_RUN, S_BLK_FIN,
                              S_SLP_LOAD, S_SLP_FIN, S_STEP_END, S_DONE} state_t;
    state_t st;

    logic [TW-1:0]           t;
    logic [$clog2(G+1)-1:0]  b;
    logic                    cur_bank;
    logic [C-1:0]            gate;                   // sub-block gates for timestep t
    logic signed [VB-1:0]    R [C];                  // exact max V per sub-block after the last step
    logic signed [AB-1:0]    qs_cur [C];             // mean drive of timestep t per sub-block
    logic [EAW-1:0]          pe_ptr, pe_start, pe_end;
    logic                    pe_v1, pe_v2;
    logic [15:0]             pe_j;
    logic [255:0]            pe_w;
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

    logic signed [VB-1:0] rnew [4];
    always_comb begin
        for (int s = 0; s < 4; s++) begin
            rnew[s] = vnew[8*s];
            for (int l = 1; l < 8; l++)
                if (vnew[8*s + l] > rnew[s]) rnew[s] = vnew[8*s + l];
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

    always_ff @(posedge clk) begin
        if (rst) begin
            st <= S_IDLE; done <= 0; out_valid <= 0; v_valid <= 0; etu_go <= 0;
            consume_bank_valid <= 0;
            cnt_cycles <= 0; cnt_col_reads <= 0; cnt_word_reads <= 0; cnt_awake_sub <= 0;
            st_valid <= '0;
            for (int c = 0; c < C; c++) R[c] <= '0;
        end else begin
            out_valid <= 0; v_valid <= 0; etu_go <= 0; consume_bank_valid <= 0;
            if (st != S_IDLE && st != S_DONE) cnt_cycles <= cnt_cycles + 1'b1;
            case (st)
                S_IDLE: if (start) begin
                    t <= 0; cur_bank <= 0; done <= 0;
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
                        pe_start <= ts_mem[t][EAW-1:0];
                        pe_end   <= ts_mem[t + 1][EAW-1:0];
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
                    if (pe_ptr != pe_end) begin pe_j <= ev_mem[pe_ptr]; pe_ptr <= pe_ptr + 1'b1; end
                    pe_v2 <= pe_v1;
                    if (pe_v1) begin
                        pe_w <= w_mem[b * M + pe_j[IW-1:0]];
                        cnt_word_reads <= cnt_word_reads + 1'b1;
                        cnt_col_reads  <= cnt_col_reads + $countones(blk_gate);
                    end
                    if (pe_v2)
                        for (int l = 0; l < 32; l++)
                            if (blk_gate[l/8]) acc[l] <= acc[l] + AB'($signed(pe_w[8*l +: 8]));
                    if (pe_ptr == pe_end && !pe_v1 && !pe_v2) st <= S_BLK_FIN;
                end
                S_BLK_FIN, S_SLP_FIN: begin
                    logic [32*VB-1:0] word;
                    logic [31:0] spk_w;
                    for (int l = 0; l < 32; l++) begin word[VB*l +: VB] = vnew[l]; spk_w[l] = spk[l]; end
                    st_mem[b] <= word;
                    st_valid[b] <= 1'b1;
                    for (int s = 0; s < 4; s++) R[4*b + s] <= rnew[s];
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
