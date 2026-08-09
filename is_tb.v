`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 11:39:50
// Design Name: 
// Module Name: is_tb
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


module tb_is_wrapper;
    reg  clk;
    reg  rst_n;
    reg  start;
    wire done;
    
    reg  [23:0] stream_act_packed;
    reg  [23:0] stream_weight_packed;
    
    wire [95:0] stream_out_packed;
    wire out_valid;

    // Outputs exit from the Right edge (Row 2, Row 1, Row 0)
    wire signed [31:0] psum_row2 = stream_out_packed[95:64];
    wire signed [31:0] psum_row1 = stream_out_packed[63:32];
    wire signed [31:0] psum_row0 = stream_out_packed[31:0];

    is_accelerator_wrapper dut (
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
        // PHASE 1: LOAD ACTIVATIONS (Pixels)
        // Shifting from Left to Right. Takes 3 cycles.
        // ==========================================
        // Matrix A: Row0=[1,2,1], Row1=[0,1,2], Row2=[2,0,1]
        
        // Cycle 1: Feed Right-most column of Matrix A
        stream_act_packed = {8'd1, 8'd2, 8'd1}; #10;
        // Cycle 2: Feed Middle column of Matrix A
        stream_act_packed = {8'd0, 8'd1, 8'd2}; #10;
        // Cycle 3: Feed Left-most column of Matrix A
        stream_act_packed = {8'd2, 8'd0, 8'd1}; #10;
        
        stream_act_packed = 24'd0; 

        // ==========================================
        // PHASE 2: COMPUTE (Stream Skewed Weights)
        // Matrix B: Top=[1,0,2], Mid=[2,1,0], Bot=[0,2,1]
        // ==========================================
        
        // Cycle 1: Col0 gets 1st weight.
        stream_weight_packed = {8'd0, 8'd0, 8'd1}; #10;
        // Cycle 2: Col0 gets 2nd. Col1 gets 1st.
        stream_weight_packed = {8'd0, 8'd2, 8'd0}; #10;
        // Cycle 3: Col0 gets 3rd. Col1 gets 2nd. Col2 gets 1st.
        stream_weight_packed = {8'd0, 8'd1, 8'd2}; #10;
        // Cycle 4: Col1 gets 3rd. Col2 gets 2nd.
        stream_weight_packed = {8'd2, 8'd0, 8'd0}; #10;
        // Cycle 5: Col2 gets 3rd.
        stream_weight_packed = {8'd1, 8'd0, 8'd0}; #10;
        
        stream_weight_packed = 24'd0;

        wait(done == 1'b1);
        $display("--- ACCELERATOR FINISHED ---");
        #5;
        $finish;
    end

    always @(posedge clk) begin
        if (out_valid) begin
            $display("Valid Result Column Exited Right: [%0d, %0d, %0d]", 
                     psum_row0, psum_row1, psum_row2);
        end
    end
endmodule
