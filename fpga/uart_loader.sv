// Host load port for hush_layer (A3b, 28 Oct 2026): 8N1 UART receiver (115200 baud at 100 MHz) and a frame
// decoder. Frame: 0xA5, sel, addr[7:0], addr[15:8], then 32 data bytes (byte i = bits 8i+7:8i); one ld_we
// pulse per frame. sel: 0 = weight word (256 b, all four columns), 1 = P row, 2 = Q row, 3 = event, 4 = ts2 pair.
// Loads are issued by the host only while the layer is idle. With the line idle (as in all evaluation runs)
// nothing toggles here; the port exists so every table is a real writable RAM.
module uart_loader #(parameter int CLKS_PER_BIT = 868) (
    input  logic         clk,
    input  logic         rst,
    input  logic         rx,
    output logic         ld_we,
    output logic [2:0]   ld_sel,
    output logic [15:0]  ld_addr,
    output logic [255:0] ld_data
);
    logic [2:0] rx_s = '1;
    always_ff @(posedge clk) rx_s <= {rx_s[1:0], rx};
    wire rxd = rx_s[2];

    // byte receiver
    logic [$clog2(3*CLKS_PER_BIT/2+1)-1:0] cnt;
    logic [3:0] bitn;
    logic       busy, bv;
    logic [7:0] sh, by;
    always_ff @(posedge clk) begin
        bv <= 1'b0;
        if (rst) begin busy <= 1'b0; cnt <= '0; bitn <= '0; end
        else if (!busy) begin
            if (!rxd) begin busy <= 1'b1; cnt <= ($bits(cnt))'(3*CLKS_PER_BIT/2 - 1); bitn <= '0; end
        end else if (cnt != 0) cnt <= cnt - 1'b1;
        else if (bitn < 8) begin sh <= {rxd, sh[7:1]}; bitn <= bitn + 1'b1; cnt <= ($bits(cnt))'(CLKS_PER_BIT - 1); end
        else begin busy <= 1'b0; if (rxd) begin by <= sh; bv <= 1'b1; end end   // stop bit
    end

    // frame decoder
    logic [5:0] pos;                       // 0 = waiting for 0xA5, 1 = sel, 2..3 = addr, 4..35 = data
    always_ff @(posedge clk) begin
        ld_we <= 1'b0;
        if (rst) pos <= '0;
        else if (bv) begin
            case (pos)
                6'd0: if (by == 8'hA5) pos <= 6'd1;
                6'd1: begin ld_sel <= by[2:0]; pos <= 6'd2; end
                6'd2: begin ld_addr[7:0] <= by; pos <= 6'd3; end
                6'd3: begin ld_addr[15:8] <= by; pos <= 6'd4; end
                default: begin
                    ld_data <= {by, ld_data[255:8]};
                    if (pos == 6'd35) begin pos <= 6'd0; ld_we <= 1'b1; end else pos <= pos + 1'b1;
                end
            endcase
        end
    end
endmodule
