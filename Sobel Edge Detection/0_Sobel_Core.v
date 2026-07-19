module sobel_core #(
    parameter DATA_WIDTH = 8,
    parameter MAX_WIDTH  = 1920,
    parameter MAX_HEIGHT = 1080
)(
    input  wire clk,
    input  wire rst,

    input  wire [$clog2(MAX_WIDTH)-1:0]  img_width,
    input  wire [$clog2(MAX_HEIGHT)-1:0] img_height,
    input  wire [DATA_WIDTH+3:0]         threshold,
    input  wire [31:0]                   frame_pixel_count,  // = width*height

    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    output wire                  s_axis_tready,

    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,
    output reg                   m_axis_tlast
);


    // We assume the downstream hardware (DMA + DDR3) is fast
    // nough to accept one output pixel every clock, so we ignore 
    // m_axis_tready and let the Sobel pipeline run continuously 
    // without implementing the AXI-Stream backpressure mechanism.


    assign s_axis_tready = 1'b1; // always ready to receive a pixel for not complex backpressure handling 
    wire pixel_valid = s_axis_tvalid & s_axis_tready;

    wire [DATA_WIDTH-1:0] lb1_out, lb2_out;
    wire lb1_valid, lb2_valid;

    line_buffer #(.DATA_WIDTH(DATA_WIDTH), .MAX_WIDTH(MAX_WIDTH)) LB1 (
        .clk(clk), .rst(rst), .img_width(img_width),
        .pixel_valid(pixel_valid), .pixel_in(s_axis_tdata),
        .pixel_out(lb1_out), .pixel_out_valid(lb1_valid)
    );
    line_buffer #(.DATA_WIDTH(DATA_WIDTH), .MAX_WIDTH(MAX_WIDTH)) LB2 (
        .clk(clk), .rst(rst), .img_width(img_width),
        .pixel_valid(lb1_valid), .pixel_in(lb1_out),
        .pixel_out(lb2_out), .pixel_out_valid(lb2_valid)
    );

    wire [DATA_WIDTH-1:0] w00,w01,w02,w10,w11,w12,w20,w21,w22;
    wire window_valid;

    window_gen #(.DATA_WIDTH(DATA_WIDTH)) WG (
        .clk(clk), .rst(rst), .pixel_valid(pixel_valid),
        .row_top(lb2_out), .row_mid(lb1_out), .row_bot(s_axis_tdata),
        .row_top_valid(lb2_valid),
        .w00(w00),.w01(w01),.w02(w02), .w10(w10),.w11(w11),.w12(w12), .w20(w20),.w21(w21),.w22(w22),
        .window_valid(window_valid)
    );

    wire signed [DATA_WIDTH+2:0] gx, gy;
    wire gxgy_valid;
    sobel_gxgy #(.DATA_WIDTH(DATA_WIDTH)) GXY (
        .clk(clk),
        .w00(w00),.w01(w01),.w02(w02), .w10(w10),.w11(w11),.w12(w12), .w20(w20),.w21(w21),.w22(w22),
        .window_valid(window_valid), .gx(gx), .gy(gy), .gxgy_valid(gxgy_valid)
    );

    wire edge_pixel, edge_valid;
    sobel_magnitude #(.DATA_WIDTH(DATA_WIDTH)) MAG (
        .clk(clk), .gx(gx), .gy(gy), .gxgy_valid(gxgy_valid),
        .threshold(threshold), .edge_pixel(edge_pixel), .edge_valid(edge_valid)
    );

    reg [31:0] out_count;
    always @(posedge clk) begin
        if (rst) begin
            m_axis_tvalid <= 1'b0;
            out_count     <= 32'd0;
        end else if (edge_valid) begin
            m_axis_tdata  <= edge_pixel ? {DATA_WIDTH{1'b1}} : {DATA_WIDTH{1'b0}};
            m_axis_tvalid <= 1'b1;
            m_axis_tlast  <= (out_count == frame_pixel_count - 1);
            out_count     <= (out_count == frame_pixel_count - 1) ? 32'd0 : out_count + 1'b1;
        end else begin
            m_axis_tvalid <= 1'b0;
        end
    end
endmodule