module axi_conv_2d #(
    parameter DATA_WIDTH = 32,
    parameter IMG_WIDTH  = 28,
    parameter IMG_SIZE   = 784
)(
    input  wire         aclk,
    input  wire         aresetn,
    // Slave Interface (Input from DMA)
    input  wire [DATA_WIDTH-1:0] s_axis_tdata,
    input  wire                  s_axis_tvalid,
    input  wire                  s_axis_tlast,
    output wire                  s_axis_tready,
    // Master Interface (Output to DMA)
    output wire [DATA_WIDTH-1:0] m_axis_tdata,
    output wire                  m_axis_tvalid,
    output wire                  m_axis_tlast,
    input  wire                  m_axis_tready
);
   
    reg flushing;

    always @(posedge aclk) begin
        if (!aresetn) begin
            flushing <= 0;
        end else begin
            
            if (s_axis_tvalid && s_axis_tready && s_axis_tlast)
                flushing <= 1;
            
            else if (m_axis_tlast && m_axis_tready)
                flushing <= 0;
        end
    end

    wire internal_valid = s_axis_tvalid || flushing;
    wire [DATA_WIDTH-1:0] internal_data = flushing ? 32'd0 : s_axis_tdata;


    assign s_axis_tready = m_axis_tready && !flushing;

    wire update_en = internal_valid && m_axis_tready;

    wire [DATA_WIDTH-1:0] row0, row1, row2, row3;
    wire [(DATA_WIDTH*25)-1:0] window_flat;
    wire [DATA_WIDTH-1:0] math_result;
    conv_line_buffers #(
        .DATA_WIDTH(DATA_WIDTH), .IMG_WIDTH(IMG_WIDTH)
    ) u_buffers (
        .aclk(aclk), .aresetn(aresetn), .update_en(update_en),
        .data_in(internal_data),
        .row0_out(row0), .row1_out(row1), .row2_out(row2), .row3_out(row3)
    );
    conv_window_manager #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_window (
        .aclk(aclk), .update_en(update_en),
        .data_in(internal_data),
        .row0_in(row0), .row1_in(row1), .row2_in(row2), .row3_in(row3),
      .window_flat(window_flat),
      .aresetn(aresetn)
    );
    conv_math_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_math (
        .aclk(aclk), .aresetn(aresetn), .en(update_en),
        .window_flat(window_flat),
        .result(math_result)
    );
    conv_control_unit #(
        .DATA_WIDTH(DATA_WIDTH), .IMG_WIDTH(IMG_WIDTH), .IMG_SIZE(IMG_SIZE)
    ) u_control (
        .aclk(aclk), .aresetn(aresetn), .update_en(update_en),
        .m_axis_tready(m_axis_tready),
        .data_in(math_result),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast)
    );
endmodule