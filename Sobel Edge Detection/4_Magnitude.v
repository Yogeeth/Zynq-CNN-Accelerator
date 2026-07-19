module sobel_magnitude #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire signed [DATA_WIDTH+2:0] gx, gy,
    input  wire gxgy_valid,
    input  wire [DATA_WIDTH+3:0] threshold,     // runtime-programmable, 12 bits for 8-bit pixels
    output reg  edge_pixel,
    output reg  edge_valid
);
    wire [DATA_WIDTH+2:0] abs_gx = gx[DATA_WIDTH+2] ? (~gx + 1'b1) : gx;
    wire [DATA_WIDTH+2:0] abs_gy = gy[DATA_WIDTH+2] ? (~gy + 1'b1) : gy;
    wire [DATA_WIDTH+3:0] g_approx = {1'b0,abs_gx} + {1'b0,abs_gy};   // |Gx|+|Gy|, Part 1.7

    always @(posedge clk) begin
        edge_pixel <= (g_approx >= threshold);
        edge_valid <= gxgy_valid;
    end
endmodule