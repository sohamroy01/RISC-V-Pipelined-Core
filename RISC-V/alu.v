`timescale 1ns / 1ps

module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output reg zero
);

    // The zero flag is 1 if the result is exactly 0
    always @(*) begin
        if (result == 32'd0) zero = 1'b1;
        else zero = 1'b0;
    end

    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b; // ADD
            4'b1000: result = a - b; // SUB
            4'b0111: result = a & b; // AND
            4'b0110: result = a | b; // OR
            4'b0100: result = a ^ b; // XOR
            4'b0001: result = a << b[4:0]; // SLL (Shift Left Logical)
            4'b0101: result = a >> b[4:0]; // SRL (Shift Right Logical)
            
            // SRA (Shift Right Arithmetic): We must cast 'a' to signed 
            // so Verilog knows to duplicate the sign bit instead of filling with 0s.
            4'b1101: result = $signed(a) >>> b[4:0];               

            // SLT (Set Less Than - Signed): Cast to signed for accurate negative comparison
            4'b0010: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0; 
            
            // SLTU (Set Less Than - Unsigned): Standard unsigned comparison
            4'b0011: result = (a < b) ? 32'b1 : 32'b0;             
            
            default: result = 32'b0;
        endcase
    end

endmodule