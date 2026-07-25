`timescale 1ns / 1ps

module immediate_generator (
    input [31:0] instruction,
    output reg [31:0] imm_out
);
    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
        
            // I-Type: Arithmetic Immediate, Loads, JALR
            // Opcode: 0010011 (ALU), 0000011 (Load), 1100111 (JALR)
            
            7'b0010011, 7'b0000011, 7'b1100111: begin
                // Sign-extend bit 31 by 20 copies, then attach bits 31:20
                imm_out = { {20{instruction[31]}}, instruction[31:20] };
            end
            
            // S-Type: Stores (sw, sh, sb)
            // Opcode: 0100011
            
            7'b0100011: begin
                // Sign-extend bit 31, attach upper 7 bits, attach lower 5 bits
                imm_out = { {20{instruction[31]}}, instruction[31:25], instruction[11:7] };
            end

            // B-Type: Branches (beq, bne, blt, bge, etc.)
            // Opcode: 1100011
            // Note: Branches jump in multiples of 2, so the lowest bit is an implicit 0.

            7'b1100011: begin
                imm_out = { {19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0 };
            end

            // U-Type: LUI (Load Upper Imm), AUIPC (Add Upper Imm to PC)
            // Opcode: 0110111 (LUI), 0010111 (AUIPC)

            7'b0110111, 7'b0010111: begin
                // Upper 20 bits are the immediate, lower 12 bits are filled with 0s
                imm_out = { instruction[31:12], 12'b0 };
            end

            // J-Type: JAL (Jump and Link)
            // Opcode: 1101111

            7'b1101111: begin
                imm_out = { {11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0 };
            end

            // Default case to prevent latches
            default: begin
                imm_out = 32'b0;
            end
        endcase
    end

endmodule