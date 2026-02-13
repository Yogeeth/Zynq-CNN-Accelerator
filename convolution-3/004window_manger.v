module conv_window_manager #(parameter DATA_WIDTH = 32)(
    input wire aclk, update_en,aresetn,
    input wire [DATA_WIDTH-1:0] data_in, row0_in, row1_in, row2_in, row3_in,
    output wire [(DATA_WIDTH*25)-1:0] window_flat
);
    reg [DATA_WIDTH-1:0] win [0:4][0:4];
    integer r, c;
    always @(posedge aclk) begin
            if (!aresetn) begin
                // Reset window to zero
                for(r=0; r<5; r=r+1) begin
                    for(c=0; c<5; c=c+1) begin
                        win[r][c] <= 0;
                    end
            end
              end
        else if (update_en) begin
            for(r=0; r<5; r=r+1) for(c=0; c<4; c=c+1) win[r][c] <= win[r][c+1];
            win[0][4]<=row3_in; win[1][4]<=row2_in; win[2][4]<=row1_in; win[3][4]<=row0_in; win[4][4]<=data_in;
        end
    end
    genvar x, y;
    generate
        for(x=0; x<5; x=x+1) for(y=0; y<5; y=y+1) 
            assign window_flat[((x*5 + y)*DATA_WIDTH) +: DATA_WIDTH] = win[x][y];
    endgenerate
endmodule