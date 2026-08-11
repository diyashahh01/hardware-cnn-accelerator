`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 19:16:51
// Design Name: 
// Module Name: tb_os
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

// ============================================================================
// 4. TESTBENCH (The Dual Skew)
// ============================================================================
module tb_os_wrapper;
    reg  clk;
    reg  rst_n;
    reg  start;
    wire done;
    
    reg  [23:0] stream_act_packed;
    reg  [23:0] stream_weight_packed;
    
    wire [95:0] stream_out_packed;
    wire out_valid;

    // Outputs exit from the Bottom edge (Col 2, Col 1, Col 0)
    wire signed [31:0] psum_col2 = stream_out_packed[95:64];
    wire signed [31:0] psum_col1 = stream_out_packed[63:32];
    wire signed [31:0] psum_col0 = stream_out_packed[31:0];

    os_accelerator_wrapper dut (
        .clk(clk), .rst_n(rst_n), .start(start), .done(done),
        .stream_act_packed(stream_act_packed),
        .stream_weight_packed(stream_weight_packed),
        .stream_out_packed(stream_out_packed),
        .out_valid(out_valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; start = 0;
        stream_act_packed = 24'd0; stream_weight_packed = 24'd0;

        #10; rst_n = 1;
        start = 1; #10; start = 0; 

        // ==========================================
        // COMPUTE PHASE (Dual Skewing!)
        // In Output Stationary, BOTH inputs move, 
        // so BOTH must be fed as staggered diamonds.
        // Matrix A Rows: R0=[1,2,1], R1=[0,1,2], R2=[2,0,1]
        // Matrix B Cols: C0=[1,2,0], C1=[0,1,2], C2=[2,0,1]
        // ==========================================
        
        // Cycle 1: Row0 gets A, Col0 gets B
        stream_act_packed    = {8'd0, 8'd0, 8'd1}; 
        stream_weight_packed = {8'd0, 8'd0, 8'd1}; 
        #10;
        
        // Cycle 2: R0/R1 get A, C0/C1 get B
        stream_act_packed    = {8'd0, 8'd0, 8'd2}; 
        stream_weight_packed = {8'd0, 8'd0, 8'd2}; 
        #10;
        
        // Cycle 3: All active (Peak diamond width)
        stream_act_packed    = {8'd2, 8'd1, 8'd1}; 
        stream_weight_packed = {8'd2, 8'd1, 8'd0}; 
        #10;
        
        // Cycle 4: R0/C0 empty
        stream_act_packed    = {8'd0, 8'd2, 8'd0}; 
        stream_weight_packed = {8'd0, 8'd2, 8'd0}; 
        #10;
        
        // Cycle 5: Only R2/C2 active (End of diamond)
        stream_act_packed    = {8'd1, 8'd0, 8'd0}; 
        stream_weight_packed = {8'd1, 8'd0, 8'd0}; 
        #10;
        
        stream_act_packed = 24'd0;
        stream_weight_packed = 24'd0;

        wait(done == 1'b1);
        $display("--- ACCELERATOR FINISHED ---");
        #5;
        $finish;
    end

    // Monitor the DRAIN phase
    always @(posedge clk) begin
        if (out_valid) begin
            // Because they shift downwards, Row 2 drops out first, then Row 1, then Row 0!
            $display("Valid Result Row Exited Bottom: [%0d, %0d, %0d]", 
                     psum_col0, psum_col1, psum_col2);
        end
    end
endmodule
