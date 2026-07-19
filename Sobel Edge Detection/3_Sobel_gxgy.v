module sobel_gxgy #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire [DATA_WIDTH-1:0] w00, w01, w02,
    input  wire [DATA_WIDTH-1:0] w10, w11, w12,
    input  wire [DATA_WIDTH-1:0] w20, w21, w22,
    input  wire window_valid,
    output reg  signed [DATA_WIDTH+2:0] gx,   // 11 bits for 8-bit pixels (Part 1.9)
    output reg  signed [DATA_WIDTH+2:0] gy,
    output reg  gxgy_valid
);
    localparam SW = DATA_WIDTH + 2;   // 10 bits for 8-bit pixels

    // vertical [1,2,1] smoothing of the outer columns
    wire [SW-1:0] colL = {2'b00,w00} + ({2'b00,w10} << 1) + {2'b00,w20};  // a+2d+g
    wire [SW-1:0] colR = {2'b00,w02} + ({2'b00,w12} << 1) + {2'b00,w22};  // c+2f+i
    // horizontal [1,2,1] smoothing of the outer rows
    wire [SW-1:0] rowT = {2'b00,w00} + ({2'b00,w01} << 1) + {2'b00,w02};  // a+2b+c
    wire [SW-1:0] rowB = {2'b00,w20} + ({2'b00,w21} << 1) + {2'b00,w22};  // g+2h+i
    // note: w11 (center pixel) never appears -- matches the math in Part 1.6

    always @(posedge clk) begin
        gx         <= $signed({1'b0,colR}) - $signed({1'b0,colL});
        gy         <= $signed({1'b0,rowB}) - $signed({1'b0,rowT});
        gxgy_valid <= window_valid;
    end
endmodule