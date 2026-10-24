// Formal harness: one HUSH sub-block of NL lanes driven by MI inputs, using the RTL arithmetic modules
// hush_envelope and hush_lane unchanged (small widths so the solver finishes).
//
// Free inputs every cycle: the spike vector s. Weights are arbitrary constants (anyconst).
// The proxy P_j = max_l W_lj and the mean Q_j = floor(mean_l W_lj) are computed here, which is the
// assumption that the offline tables were generated correctly.
//
// Proved (k-induction):
//   A1 gated  -> no lane's ungated update reaches THETA          (Corollary 1, no suppressed spike)
//   A2 R      == max_l V_l                                       (exact resync invariant)
//   A3 U_l    <= E for every lane, awake or asleep               (Theorem 1, incl. mean-field)
//   A4 spike  -> gate
module fv_hush #(
    parameter int NL = 4, parameter int MI = 3, parameter int VB = 8, parameter int AB = 12,
    parameter int K = 2, parameter int THETA = 20, parameter int MF = 1
) (
    input logic clk,
    input logic [MI-1:0] s
);
    (* anyconst *) logic [4*MI*NL-1:0] Wv;     // weights, 4-bit signed, $signed(Wv[4*(j*NL+l) +: 4]) at bits 4*(j*NL+l)

    logic signed [VB-1:0] V [NL];
    logic signed [VB-1:0] R;
    logic init = 1'b1;

    // proxy and mean tables
    logic signed [AB-1:0] P [MI];
    logic signed [AB-1:0] Q [MI];
    always_comb begin
        for (int j = 0; j < MI; j++) begin
            logic signed [AB-1:0] mx, sm;
            mx = AB'($signed(Wv[4*(j*NL) +: 4])); sm = '0;
            for (int l = 0; l < NL; l++) begin
                if (AB'($signed(Wv[4*(j*NL+l) +: 4])) > mx) mx = AB'($signed(Wv[4*(j*NL+l) +: 4]));
                sm = sm + AB'($signed(Wv[4*(j*NL+l) +: 4]));
            end
            P[j] = mx;
            Q[j] = sm >>> $clog2(NL);                 // floor(sum / NL), NL a power of two
        end
    end

    logic signed [AB-1:0] D, qs, drive [NL];
    always_comb begin
        D = '0; qs = '0;
        for (int l = 0; l < NL; l++) drive[l] = '0;
        for (int j = 0; j < MI; j++) if (s[j]) begin
            D  = D + P[j];
            qs = qs + Q[j];
            for (int l = 0; l < NL; l++) drive[l] = drive[l] + AB'($signed(Wv[4*(j*NL+l) +: 4]));
        end
    end

    logic signed [AB-1:0] E;
    logic                 gate;
    hush_envelope #(.VB(VB), .AB(AB), .K(K), .THETA_H(THETA)) u_env (.R(R), .D(D), .E(E), .gate(gate));

    logic signed [VB-1:0] lv [NL], vnew [NL];
    logic signed [AB-1:0] u [NL], ufull [NL];
    logic                 spk [NL];
    for (genvar l = 0; l < NL; l++) begin : g
        hush_lane #(.VB(VB), .AB(AB), .K(K), .THETA(THETA)) u_lane (
            .v(V[l]), .usum(AB'(lv[l]) + drive[l]), .qs(MF ? qs : AB'(0)), .awake(gate), .valid(1'b1),
            .lv(lv[l]), .u(u[l]), .spk(spk[l]), .vnew(vnew[l]));
        localparam logic signed [AB-1:0] VMAX = (1 <<< (VB - 1)) - 1;
        localparam logic signed [AB-1:0] VMIN = -(1 <<< (VB - 1));
        logic signed [AB-1:0] pre;
        assign pre = AB'(lv[l]) + drive[l];
        assign ufull[l] = (pre > VMAX) ? VMAX : (pre < VMIN) ? VMIN : pre;
    end

    logic signed [VB-1:0] rnext;
    always_comb begin
        rnext = vnew[0];
        for (int l = 1; l < NL; l++) if (vnew[l] > rnext) rnext = vnew[l];
    end

    always_ff @(posedge clk) begin
        init <= 1'b0;
        if (init) begin
            for (int l = 0; l < NL; l++) V[l] <= '0;
            R <= '0;
        end else begin
            for (int l = 0; l < NL; l++) V[l] <= vnew[l];
            R <= rnext;
        end
    end

    // properties
    logic signed [VB-1:0] vmax;
    always_comb begin
        vmax = V[0];
        for (int l = 1; l < NL; l++) if (V[l] > vmax) vmax = V[l];
    end
    always_comb if (!init) begin
        A2: assert (R == vmax);
        for (int l = 0; l < NL; l++) begin
            if (!gate) assert (ufull[l] < THETA);
            assert (u[l] <= E);
            if (spk[l]) assert (gate);
        end
    end
endmodule
