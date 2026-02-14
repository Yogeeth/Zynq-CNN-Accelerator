module conv_math_core #(parameter DATA_WIDTH = 32)(
    input  wire aclk, aresetn, en,
    input  wire [(DATA_WIDTH*25)-1:0] window_flat,
    output reg signed [DATA_WIDTH-1:0] result
);
    reg signed [DATA_WIDTH-1:0] pixels [0:4][0:4];
    integer i, j;
    always @(*) begin
        for (i=0; i<5; i=i+1) for (j=0; j<5; j=j+1)
            pixels[i][j] = window_flat[((i*5 + j)*DATA_WIDTH) +: DATA_WIDTH];
    end

    // Sharpen Kernel
    wire signed [DATA_WIDTH-1:0] k [0:4][0:4];
    assign k[0][0]=-1; assign k[0][1]=-1; assign k[0][2]=-1; assign k[0][3]=-1; assign k[0][4]=-1;
    assign k[1][0]=-1; assign k[1][1]=-2; assign k[1][2]=-2; assign k[1][3]=-2; assign k[1][4]=-1;
    assign k[2][0]=-1; assign k[2][1]=-2; assign k[2][2]=48; assign k[2][3]=-2; assign k[2][4]=-1;
    assign k[3][0]=-1; assign k[3][1]=-2; assign k[3][2]=-2; assign k[3][3]=-2; assign k[3][4]=-1;
    assign k[4][0]=-1; assign k[4][1]=-1; assign k[4][2]=-1; assign k[4][3]=-1; assign k[4][4]=-1;
    reg signed [DATA_WIDTH-1:0] prod [0:4][0:4];
    reg signed [DATA_WIDTH-1:0] row_sum [0:4];
    always @(posedge aclk) begin
        if(!aresetn) begin
            result <= 0;
            for(i=0; i<5; i=i+1) begin row_sum[i]<=0; for(j=0; j<5; j=j+1) prod[i][j]<=0; end
        end else if (en) begin
            for(i=0; i<5; i=i+1) for(j=0; j<5; j=j+1) prod[i][j] <= pixels[i][j] * k[i][j];
            for(i=0; i<5; i=i+1) row_sum[i] <= prod[i][0]+prod[i][1]+prod[i][2]+prod[i][3]+prod[i][4];
            result <= row_sum[0]+row_sum[1]+row_sum[2]+row_sum[3]+row_sum[4];
        end
    end
endmodule
