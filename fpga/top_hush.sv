// Board top for power/timing runs on a Nexys A7-100T (XC7A100T-1CSG324C).
// Runs back-to-back inferences of one hush_layer on a fixed test sample stored in BRAM ("autorun"),
// so the board draws steady-state power for the differential BASE-vs-HUSH measurement.
// LEDs: [0] heartbeat (toggles every 2^k inferences), [1] done, [7:2] XOR of output spikes so the
// datapath cannot be optimised away.
module top_hush #(
    parameter int M = 578, parameter int N = 256, parameter int T = 100, parameter int K = 4,
    parameter int THETA = 64, parameter int GATE = 1, parameter int MF = 1, parameter int NEV = 4096,
    parameter int NSMP = 1        // > 1: step through NSMP on-chip samples, one per inference (power runs)
) (
    input  logic       clk100,
    input  logic       cpu_resetn,
    input  logic       uart_rx,         // host load port (weights, tables, events); idle-high when unused
    output logic [7:0] led
);
    logic rst;
    logic [3:0] rst_sync = '1;
    always_ff @(posedge clk100) rst_sync <= {rst_sync[2:0], ~cpu_resetn};
    assign rst = rst_sync[3];

    logic start, done, out_valid, v_valid;
    logic [15:0] out_t, out_blk;
    logic [31:0] out_spk;
    logic [32*16-1:0] v_data;
    logic [47:0] cyc, colr, wordr, awk;

    logic [15:0] smp;
    logic        ld_we;
    logic [2:0]  ld_sel;
    logic [15:0] ld_addr;
    logic [255:0] ld_data;
    uart_loader u_ld (.clk(clk100), .rst, .rx(uart_rx), .ld_we, .ld_sel, .ld_addr, .ld_data);
    hush_layer #(.M(M), .N(N), .T(T), .K(K), .THETA(THETA), .THETA_H(THETA), .GATE(GATE), .MF(MF), .NEV(NEV), .NSMP(NSMP))
        u_layer (.clk(clk100), .rst, .start, .smp, .ld_we, .ld_sel, .ld_addr, .ld_data, .done, .out_valid, .out_t, .out_blk, .out_spk, .v_valid, .v_data,
                 .cnt_cycles(cyc), .cnt_col_reads(colr), .cnt_word_reads(wordr), .cnt_awake_sub(awk));

    // autorun: pulse start whenever the layer is idle or done
    logic [23:0] n_inf;
    logic        done_q;
    logic [5:0]  spk_x;
    always_ff @(posedge clk100) begin
        if (rst) begin start <= 1'b0; n_inf <= '0; done_q <= 1'b0; spk_x <= '0; smp <= '0; end
        else begin
            done_q <= done;
            // hush_layer leaves DONE on a start pulse (DONE -> IDLE) and needs start again in IDLE to run, and
            // done stays high in IDLE; so hold start while done is high (fix 28 Oct: the old rising-edge rule
            // ran a single inference and then idled).
            start  <= done || (n_inf == 0 && !start);
            if (done && !done_q) begin
                n_inf <= n_inf + 1'b1;
                smp   <= (smp == 16'(NSMP - 1)) ? 16'd0 : smp + 16'd1;   // next sample, captured at the next start
            end
            if (out_valid) spk_x <= spk_x ^ out_spk[5:0] ^ out_spk[31:26] ^ v_data[5:0];
        end
    end
    assign led = {spk_x, done, n_inf[12]};
endmodule
