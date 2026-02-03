module conv_engine(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [71:0] img_vector,
    input  wire        img_vector_valid,
    output reg  [7:0]  pixel_out,
    output reg         pixel_valid
);


    localparam signed [7:0] K0 = 1, K1 = 1, K2 = 3;
    localparam signed [7:0] K3 = 4, K4 = 5, K5 = 6;
    localparam signed [7:0] K6 = 7, K7 = 8, K8 = 9;


    reg signed [15:0] mult[0:8];   // Result of Byte * Kernel
    reg signed [19:0] sum_stg1[0:4]; // First adder stage
    reg signed [19:0] final_sum;
    
    // Pipeline Valid Shift Register (Depth = 3: Mult -> Add1 -> Final)
    reg [2:0] valid_pipe; 


    integer i;


    always @(posedge clk) begin
        if (!rst_n) begin
            pixel_valid <= 0;
            pixel_out   <= 0;
            valid_pipe  <= 0;
            final_sum   <= 0;
        end else begin
           
            if (img_vector_valid) begin

                mult[0] <= $signed(img_vector[7:0])   * K0;
                mult[1] <= $signed(img_vector[15:8])  * K1;
                mult[2] <= $signed(img_vector[23:16]) * K2;
                mult[3] <= $signed(img_vector[31:24]) * K3;
                mult[4] <= $signed(img_vector[39:32]) * K4;
                mult[5] <= $signed(img_vector[47:40]) * K5;
                mult[6] <= $signed(img_vector[55:48]) * K6;
                mult[7] <= $signed(img_vector[63:56]) * K7;
                mult[8] <= $signed(img_vector[71:64]) * K8;
            end


            sum_stg1[0] <= mult[0] + mult[1];
            sum_stg1[1] <= mult[2] + mult[3];
            sum_stg1[2] <= mult[4] + mult[5];
            sum_stg1[3] <= mult[6] + mult[7];
            sum_stg1[4] <= mult[8]; 

           
            final_sum <= sum_stg1[0] + sum_stg1[1] + sum_stg1[2] + sum_stg1[3] + sum_stg1[4];


            pixel_out <= (final_sum > 255) ? 255 : (final_sum < 0) ? 0 : final_sum[7:0];


            valid_pipe  <= {valid_pipe[1:0], img_vector_valid}; 
            pixel_valid <= valid_pipe[2]; 
        end
    end

endmodule