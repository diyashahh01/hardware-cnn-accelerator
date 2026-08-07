`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.07.2026 18:48:45
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

module pe_ws (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire load_weight,
    
    // Data Inputs
    input  wire signed [7:0]  act_in,
    input  wire signed [7:0]  weight_in,
    input  wire signed [31:0] psum_in,
    
    // Data Outputs
    output reg signed [7:0]  act_out,
    output reg signed [7:0]  weight_out, 
    output reg signed [31:0] psum_out
);

    reg signed [7:0] weight_reg;
    
    // 8-bit * 8-bit = 16-bit signed result. 
    // Verilog will automatically sign-extend this to 32 bits when adding to psum_in.
    wire signed [15:0] mult_result;
    assign mult_result = act_in * weight_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            weight_reg <= 8'sd0;
            act_out    <= 8'sd0;
            weight_out <= 8'sd0;
            psum_out   <= 32'sd0;
        end else if (en) begin
            if (load_weight) begin
                weight_reg <= weight_in;
                weight_out <= weight_in; 
            end else begin
                act_out  <= act_in;
                psum_out <= psum_in + mult_result;
            end
        end
    end
endmodule
