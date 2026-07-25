`timescale 1ns / 1ps

module rv32i_pipelined_core (
    input clk,
    input rst
);

    wire [6:0] opcode;
    
    wire branch;
    wire alu_src;
    wire [1:0] alu_op;
    wire mem_read;
    wire mem_write;
    wire reg_write;
    wire mem_to_reg;

    control_unit cu (
        .opcode(opcode),
        .branch(branch),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .reg_write(reg_write),
        .mem_to_reg(mem_to_reg)
    );

    pipelined_datapath dp (
        .clk(clk),
        .rst(rst),
        .branch_cu(branch),
        .alu_src_cu(alu_src),
        .alu_op_cu(alu_op),
        .mem_read_cu(mem_read),
        .mem_write_cu(mem_write),
        .reg_write_cu(reg_write),
        .mem_to_reg_cu(mem_to_reg),
        .opcode_out(opcode)
    );

endmodule