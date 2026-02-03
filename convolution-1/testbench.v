`timescale 1ns / 1ps

module tb_cnn_top();


    reg clk;
    reg rst_n;
    reg [7:0] ps_pixel;
    reg ps_pixel_valid;
    
    wire [7:0] pl_pixel_out;
    wire pl_pixel_valid;


    cnn_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .ps_pixel(ps_pixel),
        .ps_pixel_valid(ps_pixel_valid),
        .pl_pixel_out(pl_pixel_out),
        .pl_pixel_valid(pl_pixel_valid)
    );


    always #5 clk = ~clk;


    integer i;

    task send_byte_slow;
        input [7:0] data;
        begin

            @(posedge clk);
            ps_pixel <= data;
            ps_pixel_valid <= 0; 
            
           
            @(posedge clk);
            ps_pixel_valid <= 1; 

            @(posedge clk);
            @(posedge clk); 

            ps_pixel_valid <= 0;
            @(posedge clk);
        end
    endtask

    initial begin

        clk = 0;
        rst_n = 0;
        ps_pixel = 0;
        ps_pixel_valid = 0;

        #20;
        rst_n = 1;
        #20;

        $display("STARTING SIMULATION: Edge Detection & Kernel Check");
        
        $display("[Time %0t] Test Case 1: Sending all 1s...", $time);
        
        for (i=0; i<9; i=i+1) begin
            send_byte_slow(8'd1);
        end

        #100;



        
        $display("[Time %0t] Test Case 2: Sending sequence 1..9 (Check Clamping)", $time);
        
        for (i=1; i<=9; i=i+1) begin
            send_byte_slow(i);
        end

        #200;
        $display("SIMULATION FINISHED");
        $finish;
    end


    always @(posedge clk) begin
        if (pl_pixel_valid) begin
            $display("[Time %0t] RESULT VALID: Output = %d", $time, pl_pixel_out);

            if (pl_pixel_out == 44) 
                $display("   -> MATCH! (Correct math for input '1')");
            else if (pl_pixel_out == 255) 
                $display("   -> MATCH! (Correct saturation for input '1..9')");
            else 
                $display("   -> FAILURE! Check kernel weights or adder logic.");
        end
    end

endmodule