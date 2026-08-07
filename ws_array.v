`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.07.2026 15:27:55
// Design Name: 
// Module Name: array
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

module systolic_array_ws (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire load_weight,
    
    // Flattened Edge Inputs (3 * 8 bits = 24 bits)
    input  wire [23:0] act_in_packed,    
    input  wire [23:0] weight_in_packed, 
    
    // Flattened Edge Outputs (3 * 32 bits = 96 bits)
    output wire [95:0] psum_out_packed   
);

    // Unpack the inputs for internal wiring
    wire signed [7:0]  act_in [0:2];
    wire signed [7:0]  weight_in [0:2];
    wire signed [31:0] psum_out [0:2];

    assign act_in[0] = act_in_packed[7:0];
    assign act_in[1] = act_in_packed[15:8];
    assign act_in[2] = act_in_packed[23:16];

    assign weight_in[0] = weight_in_packed[7:0];
    assign weight_in[1] = weight_in_packed[15:8];
    assign weight_in[2] = weight_in_packed[23:16];

    assign psum_out_packed = {psum_out[2], psum_out[1], psum_out[0]};

    // Internal 2D wire matrices for the grid
    wire signed [7:0]  act_wire    [0:2][0:3];
    wire signed [7:0]  weight_wire [0:3][0:2];
    wire signed [31:0] psum_wire   [0:3][0:2];

    genvar i, j;
    generate
        for (i = 0; i < 3; i = i + 1) begin : assign_inputs
            assign act_wire[i][0]    = act_in[i];      
            assign weight_wire[0][i] = weight_in[i];   
            assign psum_wire[0][i]   = 32'sd0;             
            
            assign psum_out[i]       = psum_wire[3][i]; 
        end

        for (i = 0; i < 3; i = i + 1) begin : row
            for (j = 0; j < 3; j = j + 1) begin : col
                pe_ws pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .en(en),
                    .load_weight(load_weight),
                    
                    .act_in(act_wire[i][j]),
                    .weight_in(weight_wire[i][j]),
                    .psum_in(psum_wire[i][j]),
                    
                    .act_out(act_wire[i][j+1]),
                    .weight_out(weight_wire[i+1][j]),
                    .psum_out(psum_wire[i+1][j])
                );
            end
        end
    endgenerate

endmodule
