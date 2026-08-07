`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.07.2026 15:29:28
// Design Name: 
// Module Name: wrapper
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

module ws_accelerator_wrapper (
    input  wire clk,
    input  wire rst_n,
    
    // Control interface
    input  wire start,
    output reg  done,
    
    // Data streams (Packed)
    input  wire [23:0] stream_act_packed,
    input  wire [23:0] stream_weight_packed,
    
    // Outputs (Packed)
    output wire [95:0] stream_out_packed,
    output reg  out_valid
);

    // Standard Verilog FSM States
    localparam [1:0] 
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        COMP  = 2'b10,
        DRAIN = 2'b11;

    reg [1:0] state, next_state;
    reg [5:0] counter; 
    
    reg array_en, load_weight;

    // Instantiate Array
    systolic_array_ws core_array (
        .clk(clk), 
        .rst_n(rst_n), 
        .en(array_en), 
        .load_weight(load_weight),
        .act_in_packed(stream_act_packed), 
        .weight_in_packed(stream_weight_packed), 
        .psum_out_packed(stream_out_packed)
    );

    // FSM Sequential Block
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            counter <= 6'd0;
        end else begin
            state <= next_state;
            
            if (state != next_state) 
                counter <= 6'd0;
            else if (state == LOAD || state == COMP)
                counter <= counter + 6'd1;
        end
    end

    // FSM Combinational Block
    always @(*) begin
        // Defaults
        next_state  = state;
        array_en    = 1'b0;
        load_weight = 1'b0;
        done        = 1'b0;
        out_valid   = 1'b0;

        case (state)
            IDLE: begin
                if (start) next_state = LOAD;
            end

            LOAD: begin
                array_en    = 1'b1;
                load_weight = 1'b1;
                if (counter == 6'd2) 
                    next_state = COMP;
            end

            COMP: begin
                array_en = 1'b1;
                if (counter >= 6'd3) out_valid = 1'b1; 
                
                if (counter == 6'd18) 
                    next_state = DRAIN;
            end

            DRAIN: begin
                done       = 1'b1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule
