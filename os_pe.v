`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 19:12:07
// Design Name: 
// Module Name: pe_os
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


// ============================================================================
// 1. OUTPUT STATIONARY PROCESSING ELEMENT (PE)
// ============================================================================
module pe_os (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire drain,        // New control signal to flush the answers out
    
    // Data Inputs
    input  wire signed [7:0]  act_in,     // Comes from Left
    input  wire signed [7:0]  weight_in,  // Comes from Top
    input  wire signed [31:0] psum_in,    // Comes from Top (Used only during drain)
    
    // Data Outputs
    output reg  signed [7:0]  act_out,
    output reg  signed [7:0]  weight_out, 
    output wire signed [31:0] psum_out    // Wire, because it directly exposes the internal register
);

    // The register that holds the stationary Partial Sum (The Answer)
    reg signed [31:0] psum_reg;
    
    // Expose the register to the outside world
    assign psum_out = psum_reg;
    
    // Safe multiplication
    wire signed [15:0] mult_result;
    assign mult_result = act_in * weight_in;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            psum_reg   <= 32'sd0;
            act_out    <= 8'sd0;
            weight_out <= 8'sd0;
        end else if (en) begin
            if (drain) begin
                // --- DRAIN PHASE ---
                // Stop doing math. Shift the answers downwards like a vertical conveyor belt!
                psum_reg <= psum_in;
            end else begin
                // --- COMPUTE PHASE ---
                // 1. Shift Pixels to the Right
                act_out <= act_in;
                
                // 2. Shift Weights Down
                weight_out <= weight_in;
                
                // 3. MAC Operation. Accumulate securely inside the local register!
                psum_reg <= psum_reg + mult_result;
            end
        end
    end
endmodule
