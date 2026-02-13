module conv_control_unit #(
    parameter DATA_WIDTH = 32,
    parameter IMG_WIDTH  = 28,
    parameter OUT_WIDTH  = 24,
    parameter IMG_SIZE   = 784
)(
    input  wire aclk,
    input  wire aresetn,
    input  wire update_en,
    input  wire m_axis_tready,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg  m_axis_tvalid,
    output reg  m_axis_tlast
);
    localparam LATENCY = (IMG_WIDTH * 4) + 5 + 3;
    localparam VALID_OUTPUTS = OUT_WIDTH * OUT_WIDTH; // 576
    
    reg [31:0] out_pixels_cnt;
    reg [31:0] latency_cnt;
    reg [5:0]  col_cnt, row_cnt;
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            out_pixels_cnt <= 0;
            latency_cnt    <= 0;
            col_cnt <= 0; 
            row_cnt <= 0;
            m_axis_tvalid <= 0; 
            m_axis_tlast <= 0; 
            m_axis_tdata <= 0;
          
        end else begin
            if (m_axis_tready) begin
                m_axis_tvalid <= 0;
                m_axis_tlast  <= 0;
            end
            
            if (update_en) begin
        
                if (latency_cnt < LATENCY)
                    latency_cnt <= latency_cnt + 1;
                
                // Output Logic - ONLY for valid region
                if (latency_cnt >= LATENCY) begin
                    // Only output if within valid 24x24 region
                    if (row_cnt < OUT_WIDTH && col_cnt < OUT_WIDTH) begin
                        m_axis_tvalid <= 1;
                        m_axis_tdata <= data_in;
                        
                        // checking is this the last valid output
                        if (out_pixels_cnt == (VALID_OUTPUTS - 1)) begin
                            m_axis_tlast   <= 1;
                            out_pixels_cnt <= 0;
                            latency_cnt    <= 0;
                            col_cnt <= 0; 
                            row_cnt <= 0;
                        end else begin
                            out_pixels_cnt <= out_pixels_cnt + 1;
                        end
                    end
                    
                    // Updating pos of Counter
                    if (col_cnt == (IMG_WIDTH - 1)) begin
                        col_cnt <= 0;
                        row_cnt <= (row_cnt == IMG_WIDTH-1) ? 0 : row_cnt + 1;
                    end else begin
                        col_cnt <= col_cnt + 1;
                    end
                end
            end
        end
    end
endmodule