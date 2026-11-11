// Safety-critical arithmetic of HUSH, shared by hush_layer and the formal harness (formal/fv_hush.sv).
//
// hush_envelope : E = sat(L(R) + max(0, D)); gate = (E >= THETA_H)
// hush_lane     : one neuron's end-of-step update
//                   awake : U = sat(usum)           (usum = L(V) + sum of its weights, exact)
//                   asleep: U = sat(L(V) + qs)      (qs = shared mean drive, 0 when MF is off)
//                   spike = awake & (U >= THETA);  Vnew = U - THETA*spike

module hush_envelope #(
    parameter int VB = 16, parameter int AB = 26, parameter int K = 3, parameter int THETA_H = 64
) (
    input  logic signed [VB-1:0] R,
    input  logic signed [AB-1:0] D,
    output logic signed [AB-1:0] E,
    output logic                 gate
);
    localparam logic signed [AB-1:0] VMAX = (1 <<< (VB - 1)) - 1;
    localparam logic signed [AB-1:0] VMIN = -(1 <<< (VB - 1));
    logic signed [VB-1:0] lr;
    logic signed [AB-1:0] sum;
    always_comb begin
        lr   = R - (R >>> K);
        sum  = AB'(lr) + ((D > 0) ? D : AB'(0));
        E    = (sum > VMAX) ? VMAX : (sum < VMIN) ? VMIN : sum;
        gate = (E >= THETA_H);
    end
endmodule

module hush_lane #(
    parameter int VB = 16, parameter int AB = 26, parameter int K = 3, parameter int THETA = 64
) (
    input  logic signed [VB-1:0] v,       // potential at the start of the step
    input  logic signed [AB-1:0] usum,    // L(v) + sum_j s_j W_ij (exact), used when awake
    input  logic signed [AB-1:0] qs,      // shared mean drive, used when asleep
    input  logic                 awake,
    input  logic                 valid,   // 0 forces no spike (asleep pass / non-final cycles)
    output logic signed [VB-1:0] lv,
    output logic signed [AB-1:0] u,
    output logic                 spk,
    output logic signed [VB-1:0] vnew
);
    localparam logic signed [AB-1:0] VMAX = (1 <<< (VB - 1)) - 1;
    localparam logic signed [AB-1:0] VMIN = -(1 <<< (VB - 1));
    logic signed [AB-1:0] pre;
    always_comb begin
        lv   = v - (v >>> K);
        pre  = awake ? usum : (AB'(lv) + qs);
        u    = (pre > VMAX) ? VMAX : (pre < VMIN) ? VMIN : pre;
        spk  = valid && awake && (u >= THETA);
        vnew = VB'(u - (spk ? AB'(THETA) : AB'(0)));
    end
endmodule
