module line_buffer #(
    parameter DATA_WIDTH = 8,
    parameter MAX_WIDTH  = 1920      // upper bound on image width; sets BRAM depth
)(
    input  wire clk,
    input  wire rst,
    input  wire [$clog2(MAX_WIDTH)-1:0] img_width,
    input  wire pixel_valid,
    input  wire [DATA_WIDTH-1:0] pixel_in,
    output reg  [DATA_WIDTH-1:0] pixel_out,
    output reg  pixel_out_valid
);
    reg [DATA_WIDTH-1:0] mem [0:MAX_WIDTH-1];   // Vivado infers this as BRAM
    reg [$clog2(MAX_WIDTH)-1:0] wr_ptr;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            pixel_out_valid <= 1'b0;
        end else if (pixel_valid) begin
            // READ before WRITE
            pixel_out       <= mem[wr_ptr];
            pixel_out_valid <= 1'b1;
            mem[wr_ptr]     <= pixel_in;
            wr_ptr <= (wr_ptr == img_width-1) ? {$clog2(MAX_WIDTH){1'b0}} : wr_ptr + 1'b1;
        end else begin
            pixel_out_valid <= 1'b0;
        end
    end
endmodule