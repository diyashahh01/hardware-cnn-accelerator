`timescale 1ns / 1ps

// ============================================================================
// 3. OUTPUT STATIONARY WRAPPER (FSM)
// ============================================================================
module os_accelerator_wrapper (
    input  wire clk,
    input  wire rst_n,
    
    input  wire start,
    output reg  done,
    
    input  wire [23:0] stream_act_packed,
    input  wire [23:0] stream_weight_packed,
    
    output wire [95:0] stream_out_packed,
    
    output reg  out_valid
);

    localparam [1:0] 
        IDLE  = 2'b00,
        COMP  = 2'b01,  // OS has no "Load" state. It computes immediately!
        DRAIN = 2'b10;

    reg [1:0] state, next_state;
    reg [5:0] counter; 
    
    reg array_en, drain;

    systolic_array_os core_array (
        .clk(clk), .rst_n(rst_n), .en(array_en), .drain(drain),
        .act_in_packed(stream_act_packed), 
        .weight_in_packed(stream_weight_packed), 
        .psum_out_packed(stream_out_packed)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            counter <= 6'd1;
        end else begin
            state <= next_state;
            if (state != next_state) counter <= 6'd1;
            else if (state != IDLE) counter <= counter + 6'd1;
        end
    end

    always @(*) begin
        next_state = state;
        array_en   = 1'b0;
        drain      = 1'b0;
        done       = 1'b0;
        out_valid  = 1'b0;

        case (state)
            IDLE: begin
                if (start) next_state = COMP;
            end

            COMP: begin
                array_en = 1'b1;
                // It takes exactly 7 cycles for the skewed data to fully pass through 
                // the 3x3 array and finish the final internal multiplication.
                if (counter == 6'd7) next_state = DRAIN;
            end

            DRAIN: begin
                array_en  = 1'b1;
                drain     = 1'b1;
                out_valid = 1'b1; // The answers are falling out of the bottom pins!
                
                // It takes 3 cycles to flush the 3 rows out of the bottom
                if (counter == 6'd3) begin
                    done = 1'b1;
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule