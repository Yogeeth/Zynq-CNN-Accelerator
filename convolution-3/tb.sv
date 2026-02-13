`timescale 1ns/1ps

module tb_axi_conv_2d;
    // Parameters
    parameter DATA_WIDTH = 32;
    parameter IMG_WIDTH  = 28;
    parameter IMG_SIZE   = 784;
    parameter CLK_PERIOD = 10;
    
    // Signals
    reg aclk;
    reg aresetn;
    reg [DATA_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg s_axis_tlast;
    wire s_axis_tready;
    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    wire m_axis_tlast;
    reg m_axis_tready;
    
    // Instantiate DUT
    axi_conv_2d #(
        .DATA_WIDTH(DATA_WIDTH),
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_SIZE(IMG_SIZE)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tready(m_axis_tready)
    );
    
  //Dump
  task dump_all_internals;
        integer idx, r, c;
        begin
            $display("\n");
            $display("================================================================================");
            $display("                         INTERNAL REGISTER DUMP");
            $display("                              Time: %0t ns", $time);
            $display("================================================================================");
            
            // Line Buffer 0
            $display("\n--- LINE BUFFER 0 ---");
            for (idx = 0; idx < IMG_WIDTH; idx = idx + 1) begin
                $display("buff0[%2d] = %4d", idx, dut.u_buffers.buff0[idx]);
            end
            
            // Line Buffer 1
            $display("\n--- LINE BUFFER 1 ---");
            for (idx = 0; idx < IMG_WIDTH; idx = idx + 1) begin
                $display("buff1[%2d] = %4d", idx, dut.u_buffers.buff1[idx]);
            end
            
            // Line Buffer 2
            $display("\n--- LINE BUFFER 2 ---");
            for (idx = 0; idx < IMG_WIDTH; idx = idx + 1) begin
                $display("buff2[%2d] = %4d", idx, dut.u_buffers.buff2[idx]);
            end
            
            // Line Buffer 3
            $display("\n--- LINE BUFFER 3 ---");
            for (idx = 0; idx < IMG_WIDTH; idx = idx + 1) begin
                $display("buff3[%2d] = %4d", idx, dut.u_buffers.buff3[idx]);
            end
            
            // Row outputs
            $display("\n--- LINE BUFFER OUTPUTS ---");
            $display("row0_out = %4d", dut.row0);
            $display("row1_out = %4d", dut.row1);
            $display("row2_out = %4d", dut.row2);
            $display("row3_out = %4d", dut.row3);
            
            // 5x5 Window
            $display("\n--- 5x5 WINDOW MANAGER ---");
            for (r = 0; r < 5; r = r + 1) begin
                $write("Row %0d: [", r);
                for (c = 0; c < 5; c = c + 1) begin
                    $write("%4d", dut.u_window.win[r][c]);
                    if (c < 4) $write(", ");
                end
                $display("]");
            end
            
            // Math Core
            $display("\n--- MATH CORE ---");
            $display("Convolution Result = %0d (signed: %0d)", 
                     dut.u_math.result, $signed(dut.u_math.result));
            
            // Control Unit
            $display("\n--- CONTROL UNIT ---");
            $display("latency_cnt     = %4d", dut.u_control.latency_cnt);
            $display("out_pixels_cnt  = %4d", dut.u_control.out_pixels_cnt);
            $display("row_cnt         = %4d", dut.u_control.row_cnt);
            $display("col_cnt         = %4d", dut.u_control.col_cnt);
            $display("m_axis_tvalid   = %b", dut.u_control.m_axis_tvalid);
            $display("m_axis_tlast    = %b", dut.u_control.m_axis_tlast);
            $display("m_axis_tdata    = %0d", $signed(dut.u_control.m_axis_tdata));
            
            // Top level
            $display("\n--- TOP LEVEL SIGNALS ---");
            $display("flushing        = %b", dut.flushing);
            $display("update_en       = %b", dut.update_en);
            $display("internal_valid  = %b", dut.internal_valid);
            
            $display("================================================================================\n");
        end
    endtask
    

    // Clock generation
    initial begin
        aclk = 0;
        forever #(CLK_PERIOD/2) aclk = ~aclk;
      forever #(CLK_PERIOD/2) m_axis_tready = ~m_axis_tready; // For testing 
    end
    
    // Test stimulus
    integer i;
    initial begin
        // Initialize
        aresetn = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;
        
        // Reset
        #(CLK_PERIOD*5);
        aresetn = 1;
        #(CLK_PERIOD*2);
        
        // Send 784 pixels
        for (i = 0; i < IMG_SIZE; i = i + 1) begin
            @(posedge aclk);
            s_axis_tdata = i; // Simple incrementing pattern
            s_axis_tvalid = 1;
            s_axis_tlast = (i == IMG_SIZE-1) ? 1 : 0;
            
            // Wait for ready
            while (!s_axis_tready) @(posedge aclk);
        end
        
        @(posedge aclk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        
        // Wait for output to finish
        wait(m_axis_tlast && m_axis_tvalid);
        #(CLK_PERIOD*10);
        
        $display("Test completed!");
      #(CLK_PERIOD*100);
      aresetn = 0;
      #(CLK_PERIOD*5);
        aresetn = 1;
      dump_all_internals();
        $finish;
    end
    
    // Monitor outputs
    integer out_count;
    initial begin
        out_count = 0;
        forever begin
            @(posedge aclk);
            if (m_axis_tvalid && m_axis_tready) begin
                $display("Output[%0d] = %0d, TLAST=%b", out_count, m_axis_tdata, m_axis_tlast);
                out_count = out_count + 1;
            end
        end
    end
  
  
    
endmodule