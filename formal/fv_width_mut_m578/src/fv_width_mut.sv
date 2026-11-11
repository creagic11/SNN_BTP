// Full-width check of the HUSH safety arithmetic (11 Nov 2026, review point "proof at reduced widths").
//
// The RTL modules hush_envelope and hush_lane at the widths hush_layer actually uses for an M-input layer:
//   VB = 16 (membrane potential), K = 4, THETA = THETA_H = 64, AB = clog2(2^15 + 128*M + 1) + 1 (18 bits for M = 578).
// One timestep of one sub-block of NL = 8 lanes, as the inductive step of Theorem 1:
//   free values  R, V_l (16 bit), D, qs, drive_l (AB bit), any value every check
//   assumptions  V_l <= R                              (induction hypothesis: R bounds every member)
//                drive_l <= D, qs <= D                  (sum_j W_jl <= sum_j P_jc and floor-mean <= max, per active input)
//                -128*M <= drive_l, qs, D <= 127*M      (sums of at most M INT8 values)
//   assertions   F1 gate = 0  ->  ungated U_l < THETA   (no suppressed spike)
//                F2 U_l <= E for every lane, awake or asleep (mean-field drive included)
//                F3 spike -> gate
//                F4 no wrap-around: every AB-bit sum (and the clipped envelope) equals the same computed 8 bits wider
//                F5 Vnew_l <= max_l Vnew_l (R' = max Vnew re-establishes the hypothesis for the next step)
// With V_l = R = 0 at reset, F5 makes V_l <= R an invariant of all reachable states (induction on t), and F1 then
// holds at every timestep. Run: sby -f fv_width.sby m578 (hidden layer) / m256 (output-layer widths).
module fv_width #(
    parameter int M = 578, parameter int NL = 8, parameter int VB = 16, parameter int K = 4,
    parameter int THETA = 64
) (
    input logic clk
);
    localparam int AB = $clog2((1 << 15) + 128 * M + 1) + 1;
    localparam int WB = AB + 8;
    localparam logic signed [AB-1:0] LO = -128 * M;
    localparam logic signed [AB-1:0] HI = 127 * M;
    localparam logic signed [AB-1:0] VMAX = (1 <<< (VB - 1)) - 1;
    localparam logic signed [AB-1:0] VMIN = -(1 <<< (VB - 1));

    logic init = 1'b1;                       // one register so the engines see a sequential model
    always_ff @(posedge clk) init <= 1'b0;
    (* anyseq *) logic signed [VB-1:0] R;
    (* anyseq *) logic signed [AB-1:0] D;
    (* anyseq *) logic signed [AB-1:0] qs;
    (* anyseq *) logic [NL*VB-1:0] Vp;
    (* anyseq *) logic [NL*AB-1:0] Dp;

    logic signed [AB-1:0] E;
    logic                 gate;
    hush_envelope #(.VB(VB), .AB(AB), .K(K), .THETA_H(THETA)) u_env (.R(R), .D(D), .E(E), .gate(gate));

    // wide reference for the envelope sum
    wire signed [WB-1:0] lrw  = WB'(R) - (WB'(R) >>> K);
    wire signed [WB-1:0] sumw = lrw + ((D > 0) ? WB'(D) : WB'(0));

    always_comb begin
        assume (D >= LO && D <= HI);
        assume (qs >= LO && qs <= HI && qs <= D);
        // E equals the clip of the exact (wide) envelope sum: no wrap inside hush_envelope
        if (!init) assert (WB'(E) == ((sumw > WB'(VMAX)) ? WB'(VMAX) : (sumw < WB'(VMIN)) ? WB'(VMIN) : sumw));
    end

    logic signed [VB-1:0] vn [NL];
    for (genvar l = 0; l < NL; l++) begin : g
        wire signed [VB-1:0] v  = Vp[VB*l +: VB];
        wire signed [AB-1:0] dr = Dp[AB*l +: AB];
        logic signed [VB-1:0] lv, vnew;
        logic signed [AB-1:0] u;
        logic                 spk;
        hush_lane #(.VB(VB), .AB(AB), .K(K), .THETA(THETA)) u_lane (
            .v(v), .usum(AB'(lv) + dr), .qs(qs), .awake(gate), .valid(1'b1),
            .lv(lv), .u(u), .spk(spk), .vnew(vnew));
        wire signed [AB-1:0] pre   = AB'(lv) + dr;
        wire signed [AB-1:0] ufull = (pre > VMAX) ? VMAX : (pre < VMIN) ? VMIN : pre;
        wire signed [WB-1:0] lvw   = WB'(v) - (WB'(v) >>> K);
        assign vn[l] = vnew;
        always_comb begin
            assume (v <= R);
            assume (dr >= LO && dr <= HI);   // MUTANT: proxy no longer bounds the weights
            if (!init) assert (WB'(pre) == lvw + WB'(dr));
            if (!init) assert (WB'(AB'(lv) + qs) == lvw + WB'(qs));
            if (!init) assert (WB'(lv) == lvw);
            if (!gate && !init) assert (ufull < THETA);
            if (!init) assert (u <= E);
            if (spk && !init) assert (gate);
        end
    end

    logic signed [VB-1:0] vmx;
    always_comb begin
        vmx = vn[0];
        for (int l = 1; l < NL; l++) if (vn[l] > vmx) vmx = vn[l];
        for (int l = 0; l < NL; l++) if (!init) assert (vn[l] <= vmx);   // F5
    end
endmodule
