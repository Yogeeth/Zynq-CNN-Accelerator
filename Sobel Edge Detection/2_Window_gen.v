module window_gen #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire pixel_valid,          // top-level s_axis_tvalid

    input  wire [DATA_WIDTH-1:0] row_top,     // = line buffer 2 out (2-cycle latency)
    input  wire [DATA_WIDTH-1:0] row_mid,     // = line buffer 1 out (1-cycle latency)
    input  wire [DATA_WIDTH-1:0] row_bot,     // = s_axis_tdata      (0-cycle latency)
    input  wire row_top_valid,                // = line buffer 2's pixel_out_valid

    output reg [DATA_WIDTH-1:0] w00, w01, w02,   // top row,    left->right
    output reg [DATA_WIDTH-1:0] w10, w11, w12,   // middle row, left->right
    output reg [DATA_WIDTH-1:0] w20, w21, w22,   // bottom row, left->right
    output reg window_valid
);
  
    reg [DATA_WIDTH-1:0] row_mid_d1, row_bot_d1, row_bot_d2;
    always @(posedge clk) begin
        if (pixel_valid) begin
            row_mid_d1 <= row_mid;
            row_bot_d1 <= row_bot;
            row_bot_d2 <= row_bot_d1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            window_valid <= 1'b0;
        end else if (row_top_valid) begin      // all three taps are aligned exactly when this fires
            w00 <= w01; w01 <= w02; w02 <= row_top;
            w10 <= w11; w11 <= w12; w12 <= row_mid_d1;
            w20 <= w21; w21 <= w22; w22 <= row_bot_d2;
            window_valid <= 1'b1;
        end else begin
            window_valid <= 1'b0;
        end
    end
endmodule