`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.07.2026 16:07:00
// Design Name: 
// Module Name: 
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


module tb_ws_wrapper;

    // --- Signals ---
    reg  clk;
    reg  rst_n;
    reg  start;
    wire done;
    
    reg  [23:0] stream_act_packed;
    reg  [23:0] stream_weight_packed;
    
    wire [95:0] stream_out_packed;
    wire out_valid;

    // --- Unpack Output Wires for easy reading in the console ---
    wire signed [31:0] psum_col2 = stream_out_packed[95:64];
    wire signed [31:0] psum_col1 = stream_out_packed[63:32];
    wire signed [31:0] psum_col0 = stream_out_packed[31:0];

    // --- Instantiate the Wrapper ---
    ws_accelerator_wrapper dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .stream_act_packed(stream_act_packed),
        .stream_weight_packed(stream_weight_packed),
        .stream_out_packed(stream_out_packed),
        .out_valid(out_valid)
    );

    // --- Clock Generation (10ns period) ---
    always #5 clk = ~clk;

    // --- Test Sequence ---
    initial begin
        // 1. Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        stream_act_packed = 24'd0;
        stream_weight_packed = 24'd0;

        // 2. Apply Reset
        #10;
        rst_n = 1;

        // 3. Trigger the Wrapper Start
        start = 1;
        #10;
        start = 0; // Pulse start for 1 cycle

        // ==========================================
        // PHASE 1: LOAD WEIGHTS (Takes 3 Cycles)
        // Packing format: {Col2, Col1, Col0}
        // ==========================================
        
        // Cycle 1: Load Bottom Row of Matrix B (0, 2, 1)
        stream_weight_packed = {8'd1, 8'd2, 8'd0}; 
        #10;
        
        // Cycle 2: Load Middle Row of Matrix B (2, 1, 0)
        stream_weight_packed = {8'd0, 8'd1, 8'd2}; 
        #10;
        
        // Cycle 3: Load Top Row of Matrix B (1, 0, 2)
        stream_weight_packed = {8'd2, 8'd0, 8'd1}; 
        #10;
        
        // Stop feeding weights
        stream_weight_packed = 24'd0; 

        // ==========================================
// ==========================================
        // PHASE 2: COMPUTE (Stream Skewed Columns of A)
        // Packing format: {Row2, Row1, Row0}
        //
        // Matrix A Columns: 
        // Col0 (fed to Row0) = [1, 0, 2]
        // Col1 (fed to Row1) = [2, 1, 0]
        // Col2 (fed to Row2) = [1, 2, 1]
        // ==========================================
        
        // Cycle 1: Row0 gets 1st pixel. Rest get 0.
        stream_act_packed = {8'd0, 8'd0, 8'd1}; 
        #10;
        
        // Cycle 2: Row0 gets 2nd pixel. Row1 gets 1st.
        stream_act_packed = {8'd0, 8'd2, 8'd0}; 
        #10;
        
        // Cycle 3: Row0 gets 3rd. Row1 gets 2nd. Row2 gets 1st.
        stream_act_packed = {8'd1, 8'd1, 8'd2}; 
        #10;
        
        // Cycle 4: Row0 empty. Row1 gets 3rd. Row2 gets 2nd.
        stream_act_packed = {8'd2, 8'd0, 8'd0}; 
        #10;
        
        // Cycle 5: Row0 empty. Row1 empty. Row2 gets 3rd.
        stream_act_packed = {8'd1, 8'd0, 8'd0}; 
        #10;
        
        // Pad with zeros to let the pipeline drain
        stream_act_packed = {8'd0, 8'd0, 8'd0};
        // Wait for the Wrapper to assert 'done'
        wait(done == 1'b1);
        
        $display("--- ACCELERATOR FINISHED ---");
        #5;
        $finish;
    end

    // --- Monitor Outputs ---
    // This block automatically prints the results to the console 
    // whenever the wrapper says the output is valid.
    always @(posedge clk) begin
        if (out_valid) begin
            $display("Valid Result Row Dropped: [%0d, %0d, %0d]", 
                     psum_col0, psum_col1, psum_col2);
        end
    end

endmodule
