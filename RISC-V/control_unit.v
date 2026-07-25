`timescale 1ns / 1ps

module control_unit (
    input [6:0] opcode,
    // Execution (EX) stage signals
    output reg branch,
    output reg alu_src,
    output reg [1:0] alu_op,
    // Memory (MEM) stage signals
    output reg mem_read,
    output reg mem_write,
    // Write Back (WB) stage signals
    output reg reg_write,
    output reg mem_to_reg
);

    always @(*) begin

        branch = 1'b0;
        alu_src = 1'b0;
        alu_op = 2'b00;
        mem_read = 1'b0;
        mem_write = 1'b0;
        reg_write = 1'b0;
        mem_to_reg = 1'b0;

        case (opcode)

            // R-Type (add, sub, and, or, etc.)

            7'b0110011: begin
                reg_write = 1'b1; // Writes result back to rd
                alu_op = 2'b10; // Tells ALU Control to look at funct3/funct7
                // alu_src = 0 (ALU uses rs2)
                // mem_to_reg = 0 (Write back ALU result)
            end

            // I-Type ALU (addi, andi, ori, etc.)

            7'b0010011: begin
                reg_write = 1'b1; // Writes result back to rd
                alu_src = 1'b1; // ALU uses immediate instead of rs2
                alu_op = 2'b10; // Tells ALU Control to look at funct3
                // mem_to_reg = 0 (Write back ALU result)
            end

            // I-Type Load (lw, lh, lb, etc.)

            7'b0000011: begin
                reg_write = 1'b1; // Writes loaded data to rd
                alu_src = 1'b1; // ALU adds base address (rs1) + immediate
                mem_read = 1'b1; // Tells Data Memory to read
                mem_to_reg = 1'b1; // Write back Memory data (not ALU result)
                // alu_op = 00 (ALU simply adds)
            end
            
            // S-Type Store (sw, sh, sb)

            7'b0100011: begin
                alu_src = 1'b1; // ALU adds base address (rs1) + immediate
                mem_write = 1'b1; // Tells Data Memory to write
                // alu_op = 00 (ALU simply adds)
                // reg_write = 0 (Does not write to a register)
            end

            // B-Type Branch (beq, bne, blt, etc.)

            7'b1100011: begin
                branch = 1'b1; // Tells branch logic this is a branch instruction
                alu_op = 2'b01; // Tells ALU Control to set up for subtraction/comparison
                // alu_src = 0 (ALU compares rs1 and rs2)
                // reg_write = 0 (Does not write to a register)
            end

            // U-Type LUI (Load Upper Immediate)

            7'b0110111: begin
                reg_write = 1'b1;  
                alu_src = 1'b1; // Use immediate
                // Note: For LUI, the ALU Control usually forces the ALU to 
                // just pass the 'B' operand (the immediate) straight through.
            end

            // Default case already handled at the top of the block
            default: ; 
        endcase
    end

endmodule
