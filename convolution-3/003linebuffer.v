module conv_line_buffers #(parameter DATA_WIDTH = 32, IMG_WIDTH = 28)(
    input wire aclk, aresetn, update_en,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] row0_out, row1_out, row2_out, row3_out
);
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] buff0[0:IMG_WIDTH-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] buff1[0:IMG_WIDTH-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] buff2[0:IMG_WIDTH-1];
    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] buff3[0:IMG_WIDTH-1];
    integer i;
    always @(posedge aclk) begin
        if (!aresetn) begin
            for(i=0; i<IMG_WIDTH; i=i+1) begin
                buff0[i] <= 0;
                buff1[i] <= 0;
                buff2[i] <= 0;
                buff3[i] <= 0;
            end
        end else if (update_en) begin
            for(i=IMG_WIDTH-1; i>0; i=i-1) begin
                buff0[i]<=buff0[i-1]; buff1[i]<=buff1[i-1]; buff2[i]<=buff2[i-1]; buff3[i]<=buff3[i-1];
            end
            buff0[0]<=data_in; buff1[0]<=buff0[IMG_WIDTH-1]; buff2[0]<=buff1[IMG_WIDTH-1]; buff3[0]<=buff2[IMG_WIDTH-1];
        end
    end
    assign row0_out=buff0[IMG_WIDTH-1]; assign row1_out=buff1[IMG_WIDTH-1]; 
    assign row2_out=buff2[IMG_WIDTH-1]; assign row3_out=buff3[IMG_WIDTH-1];
endmodule