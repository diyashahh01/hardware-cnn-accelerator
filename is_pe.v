`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.07.2026 19:24:37
// Design Name: 
// Module Name: is_pe
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


module pe_is (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire load_act,     // The control signal switches to loading activations
    
    // Data Inputs
    input  wire signed [7:0]  act_in,
    input  wire signed [7:0]  weight_in,
    input  wire signed [31:0] psum_in,
    
    // Data Outputs
    output reg  signed [7:0]  act_out,
    output reg  signed [7:0]  weight_out, 
    output reg  signed [31:0] psum_out
);

    // The register that holds the stationary Pixel (Activation)
    reg signed [7:0] act_reg;
    
    // Safe multiplication
   wire signed [15:0] mult_result;
    assign mult_result = act_reg * weight_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_reg    <= 8'sd0;
            act_out    <= 8'sd0;
            weight_out <= 8'sd0;
            psum_out   <= 32'sd0;
        end else if (en) begin
            if (load_act) begin
                // --- LOAD PHASE ---
                // Pixels slide in from the left and lock into the desks
                act_reg <= act_in;
                act_out <= act_in; 
            end else begin
                // --- COMPUTE PHASE ---
                // 1. Weights cascade down from the top
                weight_out <= weight_in;
                
                // 2. MAC Operation. Add to the sum coming from the LEFT.
                psum_out   <= psum_in + mult_result;
            end
        end
    end
endmodule
