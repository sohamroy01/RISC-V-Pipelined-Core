`timescale 1ns / 1ps

module alu_control (
    input [1:0] alu_op, // From main Control Unit
    input [2:0] funct3, // instruction[14:12]
    input funct7_b5, // instruction[30] - used to tell ADD from SUB, SRL from SRA
    output reg [3:0] alu_ctrl // 4-bit signal sent to the ALU
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // Load/Store: Add
            2'b01: alu_ctrl = 4'b1000; // Branch: Subtract
            
            2'b10: begin // R-type or I-type ALU
                case (funct3)
                    3'b000: begin
                        // If funct7_b5 is 1, it's SUB. Otherwise, ADD.
                        if (funct7_b5 == 1'b1) alu_ctrl = 4'b1000; // SUB
                        else alu_ctrl = 4'b0000; // ADD
                    end
                    3'b001: alu_ctrl = 4'b0001; // SLL (Shift Left Logical)
                    3'b010: alu_ctrl = 4'b0010; // SLT (Set Less Than)
                    3'b011: alu_ctrl = 4'b0011; // SLTU (Set Less Than Unsigned)
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b101: begin
                        // If funct7_b5 is 1, it's SRA. Otherwise, SRL.
                        if (funct7_b5 == 1'b1) alu_ctrl = 4'b1101; // SRA (Shift Right Arithmetic)
                        else alu_ctrl = 4'b0101; // SRL (Shift Right Logical)
                    end
                    3'b110: alu_ctrl = 4'b0110; // OR
                    3'b111: alu_ctrl = 4'b0111; // AND
                    default: alu_ctrl = 4'b0000; 
                endcase
            end
            
            default: alu_ctrl = 4'b0000;
        endcase
    end

endmodule
