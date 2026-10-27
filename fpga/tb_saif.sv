// A3: switching-activity testbench for SAIF power. Runs top_hush (autorun) over NS different N-MNIST samples,
// loading each sample's event memories while the layer sits in DONE/IDLE, and the chosen network's weights
// once at start. Writes one line per inference: "I <idx> <cycles>" to compare with expected_cycles.csv.
//   plusargs: +WDIR=<dir with w.hex p.hex q.hex>  +SDIR=<dir with ev_NNN.hex ts_NNN.hex>  +NS=<count>
`timescale 1ns/1ps
module tb_saif;
    parameter int GATE = 1, MF = 1;
    logic clk = 0, rn = 0;
    always #5 clk = ~clk;
    logic [7:0] led;
    top_hush #(.M(578), .N(256), .T(100), .K(4), .THETA(64), .GATE(GATE), .MF(MF), .NEV(4096))
        u_top (.clk100(clk), .cpu_resetn(rn), .led(led));

    string wdir, sdir, fn;
    int ns, idx;
    longint c_start, c_now;
    logic loaded_for_done;

    always @(posedge clk) c_now++;

    task automatic load_sample(input int i);
        $sformat(fn, "%s/ev_%03d.hex", sdir, i); $readmemh(fn, u_top.u_layer.ev_mem);
        $sformat(fn, "%s/ts_%03d.hex", sdir, i); $readmemh(fn, u_top.u_layer.ts_mem);
    endtask

    initial begin
        if (!$value$plusargs("WDIR=%s", wdir)) wdir = ".";
        if (!$value$plusargs("SDIR=%s", sdir)) sdir = ".";
        if (!$value$plusargs("NS=%d", ns)) ns = 10;
        c_now = 0; idx = 0; loaded_for_done = 0;
        #1;
        $sformat(fn, "%s/w.hex", wdir); $readmemh(fn, u_top.u_layer.w_mem);
        $sformat(fn, "%s/p.hex", wdir); $readmemh(fn, u_top.u_layer.p_mem);
        if (MF) begin $sformat(fn, "%s/q.hex", wdir); $readmemh(fn, u_top.u_layer.q_mem); end
        load_sample(0);
        repeat (5) @(posedge clk);
        rn = 1;
        c_start = c_now;
    end

    // done rises -> the layer is in DONE and will not read the event memories for >= 2 cycles: swap the sample
    always @(negedge clk) begin
        if (u_top.u_layer.done && !loaded_for_done) begin
            loaded_for_done = 1;
            $display("I %0d %0d", idx, c_now - c_start);
            idx++;
            if (idx == ns) $finish;
            load_sample(idx);
        end
        if (!u_top.u_layer.done) begin
            if (loaded_for_done) c_start = c_now;
            loaded_for_done = 0;
        end
    end
endmodule
