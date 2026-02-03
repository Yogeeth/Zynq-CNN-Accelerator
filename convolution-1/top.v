module cnn_top (
    input  wire       clk,
    input  wire       rst_n,

    // Input from PS (Processing System)
    input  wire [7:0] ps_pixel,
    input  wire       ps_pixel_valid,

    // Output to PS
    output wire [7:0] pl_pixel_out,
    output wire       pl_pixel_valid
);

    wire [71:0] vector_flat;
    wire        vector_valid;

    //9 bytes -> 1 
    buffer_bridge u_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_data(ps_pixel),
        .s_axis_valid(ps_pixel_valid),
        .m_vector(vector_flat),
        .m_vector_valid(vector_valid)
    );

    // Engine: Pipelined Convolution
    conv_engine u_conv (
        .clk(clk),
        .rst_n(rst_n),
        .img_vector(vector_flat),
        .img_vector_valid(vector_valid),
        .pixel_out(pl_pixel_out),
        .pixel_valid(pl_pixel_valid)
    );

endmodule