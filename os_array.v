`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.07.2026 19:13:43
// Design Name: 
// Module Name: os_array
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
// 2. OUTPUT STATIONARY 3x3 SYSTOLIC ARRAY
// ============================================================================
module systolic_array_os (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire drain,
    
    // Flattened Edge Inputs
    input  wire [23:0] act_in_packed,    // Enters from Left Edge
    input  wire [23:0] weight_in_packed, // Enters from Top Edge
    
    // Flattened Edge Outputs
    output wire [95:0] psum_out_packed   // Exits from Bottom Edge!
);

    wire signed [7:0]  act_in [0:2];
    wire signed [7:0]  weight_in [0:2];
    wire signed [31:0] psum_out [0:2];

    assign act_in[0] = act_in_packed[7:0];
    assign act_in[1] = act_in_packed[15:8];
    assign act_in[2] = act_in_packed[23:16];

    assign weight_in[0] = weight_in_packed[7:0];
    assign weight_in[1] = weight_in_packed[15:8];
    assign weight_in[2] = weight_in_packed[23:16];

    // Psums exit from the BOTTOM edge of each column
    assign psum_out_packed = {psum_out[2], psum_out[1], psum_out[0]};

    // Internal wires
    wire signed [7:0]  act_wire    [0:2][0:3];
    wire signed [7:0]  weight_wire [0:3][0:2];
    wire signed [31:0] psum_wire   [0:3][0:2]; // Flows vertically during drain

    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : assign_inputs
            assign act_wire[i][0]    = act_in[i];      // Activations enter Left
            assign weight_wire[0][i] = weight_in[i];   // Weights enter Top
            
            // During DRAIN, the top row needs 0s to drop in from the ceiling to flush it
            assign psum_wire[0][i]   = 32'sd0;         
            
            // Outputs come from the 3rd row (Bottom edge)
            assign psum_out[i]       = psum_wire[3][i]; 
        end

        for (i = 0; i < 3; i = i + 1) begin : row
            for (j = 0; j < 3; j = j + 1) begin : col
                pe_os pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .en(en),
                    .drain(drain),
                    
                    .act_in(act_wire[i][j]),
                    .weight_in(weight_wire[i][j]),
                    .psum_in(psum_wire[i][j]),
                    
                    // Activations shift Right, Weights shift Down, Psums shift Down (during Drain)
                    .act_out(act_wire[i][j+1]),
                    .weight_out(weight_wire[i+1][j]),
                    .psum_out(psum_wire[i+1][j]) 
                );
            end
        end
    endgenerate
endmodule