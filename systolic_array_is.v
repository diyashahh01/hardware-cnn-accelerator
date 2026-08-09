`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.07.2026 11:57:40
// Design Name: 
// Module Name: systolic_array_is
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


module systolic_array_is (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire load_act,
    
    // Flattened Edge Inputs
    input  wire [23:0] act_in_packed,    // Enters from Left Edge
    input  wire [23:0] weight_in_packed, // Enters from Top Edge
    
    // Flattened Edge Outputs
    output wire [95:0] psum_out_packed   // Exits from Right Edge!
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

    // Psums now exit from the RIGHT edge of each row
    assign psum_out_packed = {psum_out[2], psum_out[1], psum_out[0]};

    // Internal wires
    wire signed [7:0]  act_wire    [0:2][0:3];
    wire signed [7:0]  weight_wire [0:3][0:2];
    wire signed [31:0] psum_wire   [0:2][0:3]; // Swapped dimensions for Horizontal flow

    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : assign_inputs
            assign act_wire[i][0]    = act_in[i];      // Activations enter Left
            assign psum_wire[i][0]   = 32'sd0;         // Psums start at 0 on the Left
            assign weight_wire[0][i] = weight_in[i];   // Weights enter Top
            
            // Outputs come from the 3rd column (Right edge)
            assign psum_out[i]       = psum_wire[i][3]; 
        end

        for (i = 0; i < 3; i = i + 1) begin : row
            for (j = 0; j < 3; j = j + 1) begin : col
                pe_is pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .en(en),
                    .load_act(load_act),
                    
                    .act_in(act_wire[i][j]),
                    .weight_in(weight_wire[i][j]),
                    .psum_in(psum_wire[i][j]),
                    
                    // Activations shift Right, Psums accumulate Right, Weights shift Down
                    .act_out(act_wire[i][j+1]),
                    .weight_out(weight_wire[i+1][j]),
                    .psum_out(psum_wire[i][j+1]) 
                );
            end
        end
    endgenerate
endmodule
