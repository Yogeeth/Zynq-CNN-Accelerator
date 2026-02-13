module axis_cnn_comb (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tvalid,
    input  wire        s_axis_tlast,
    output wire        s_axis_tready,
    output reg [31:0]  m_axis_tdata,
    output reg         m_axis_tvalid,
    output reg         m_axis_tlast,
    input  wire        m_axis_tready
);

    reg [31:0] weights [0:24];
    integer i;
    initial begin
        for (i = 0; i < 25; i = i + 1) weights[i] = i + 1; 
    end

    reg [4:0]  counter;      
    reg [31:0] current_sum;  

    // Comb Logic
    wire [31:0] current_weight = weights[counter];
    wire [31:0] product_result = s_axis_tdata * current_weight;
    wire [31:0] next_sum_value = current_sum + product_result;

    assign s_axis_tready = m_axis_tready; 

    always @(posedge aclk) begin
        if (!aresetn) begin
            counter <= 0; current_sum <= 0;
            m_axis_tvalid <= 0; m_axis_tlast <= 0; m_axis_tdata <= 0;
        end else begin
            if (m_axis_tready && m_axis_tvalid) begin
                m_axis_tvalid <= 0; m_axis_tlast <= 0;
            end

            if (s_axis_tvalid && s_axis_tready) begin


                if (counter < 24) begin
                    current_sum <= next_sum_value; 
                    counter     <= counter + 1;    
                end else begin
                    m_axis_tdata  <= next_sum_value; 
                    m_axis_tvalid <= 1;
                    m_axis_tlast  <= 1;
                    current_sum   <= 0;
                    counter       <= 0;
                end
            end
        end
    end
endmodule