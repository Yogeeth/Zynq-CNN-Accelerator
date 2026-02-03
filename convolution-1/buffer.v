module buffer_bridge(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  s_axis_data,
    input  wire        s_axis_valid, // This comes from Python (Slow)
    output wire [71:0] m_vector,
    output reg         m_vector_valid
);

    reg [7:0] storage [0:8];
    reg [3:0] count;
    

    reg s_axis_valid_prev;
    wire valid_rising_edge;

    // Detect when valid goes from 0 -> 1
    assign valid_rising_edge = s_axis_valid && !s_axis_valid_prev;

    assign m_vector = {
        storage[8], storage[7], storage[6], 
        storage[5], storage[4], storage[3], 
        storage[2], storage[1], storage[0]
    };

    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
            m_vector_valid <= 0;
            s_axis_valid_prev <= 0;
        end else begin
            //Track the previous state of the valid signal
            s_axis_valid_prev <= s_axis_valid;
            
            //Clear output trigger
            m_vector_valid <= 0; 

            //ONLY react if we see a Rising Edge (0 -> 1 transition)
            if (valid_rising_edge) begin
                storage[count] <= s_axis_data;

                if (count == 8) begin
                    m_vector_valid <= 1; 
                    count <= 0;
                end else begin
                    count <= count + 1;
                end
            end
        end
    end

endmodule