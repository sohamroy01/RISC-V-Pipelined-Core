`timescale 1ns / 1ps

module pipelined_datapath (
    input clk,
    input rst,
    
    // Control signals coming IN from the Top-Level Control Unit
    input branch_cu,
    input alu_src_cu,
    input [1:0] alu_op_cu,
    input mem_read_cu,
    input mem_write_cu,
    input reg_write_cu,
    input mem_to_reg_cu,
    
    // Signal going OUT to the Top-Level Control Unit
    output reg [6:0] opcode_out
);

    // =========================================================================
    // 0. FORWARD DECLARATIONS (Feedback Loops & Global Variables)
    // =========================================================================
    // By declaring these here, Verilog knows their size before they are used!
    
    reg [31:0] next_pc;             // IF Stage
    
    reg [31:0] branch_target_ex; // Loops from EX back to IF
    reg  branch_taken_ex; // Loops from EX back to IF

    reg [4:0]  rd_mem; // Loops from MEM back to EX (Forwarding)
    reg        reg_write_mem; // Loops from MEM back to EX (Forwarding)
    reg [31:0] alu_result_mem; // Loops from MEM back to EX (Forwarding)

    reg [4:0] rd_wb; // Loops from WB back to ID/EX (Writeback/Forwarding)
    reg reg_write_wb; // Loops from WB back to ID/EX (Writeback/Forwarding)
    reg [31:0] write_back_data; // Loops from WB back to ID/EX (Writeback/Forwarding)


    // =========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // =========================================================================
    wire [31:0] pc_out_if;
    wire [31:0] pc_plus_4_if;
    wire [31:0] instruction_if;
    
    wire pc_write;
    wire if_id_write;
    wire stall;

    always @(*) begin
        if (branch_taken_ex) next_pc = branch_target_ex; 
        else next_pc = pc_plus_4_if;
    end

    program_counter pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write),
        .pc_in(next_pc),
        .pc_out(pc_out_if)
    );

    instruction_memory imem (
        .pc(pc_out_if),
        .instruction(instruction_if)
    );

    pc_adder adder (
        .pc(pc_out_if),
        .pc_plus_4(pc_plus_4_if)
    );

    // =========================================================================
    // IF/ID PIPELINE REGISTER
    // =========================================================================
    reg [31:0] pc_id;
    reg [31:0] instruction_id;

    always @(posedge clk) begin
        if (rst || branch_taken_ex) begin 
            pc_id <= 32'b0;
            instruction_id <= 32'h00000013; // NOP
        end else if (if_id_write) begin     
            pc_id <= pc_out_if;
            instruction_id <= instruction_if;
        end
    end

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID) STAGE
    // =========================================================================
    reg [4:0] rs1_id, rs2_id, rd_id;
    wire [31:0] read_data1_id, read_data2_id, imm_id;

    always @(*) begin
        rs1_id = instruction_id[19:15];
        rs2_id = instruction_id[24:20];
        rd_id = instruction_id[11:7];
        opcode_out = instruction_id[6:0]; 
    end

    reg branch_id, alu_src_id, mem_read_id, mem_write_id, reg_write_id, mem_to_reg_id;
    reg [1:0] alu_op_id;

    register_file rf (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write_wb),     
        .rs1(rs1_id),
        .rs2(rs2_id),
        .rd(rd_wb),                   
        .write_data(write_back_data), 
        .read_data1(read_data1_id),
        .read_data2(read_data2_id)
    );

    immediate_generator imm_gen (
        .instruction(instruction_id),
        .imm_out(imm_id)
    );

    always @(*) begin
        if (stall) begin
            branch_id = 0; alu_src_id = 0; alu_op_id = 0;
            mem_read_id = 0; mem_write_id = 0; reg_write_id = 0; mem_to_reg_id = 0;
        end else begin
            branch_id = branch_cu; alu_src_id = alu_src_cu; alu_op_id = alu_op_cu;
            mem_read_id = mem_read_cu; mem_write_id = mem_write_cu; 
            reg_write_id = reg_write_cu; mem_to_reg_id = mem_to_reg_cu;
        end
    end

    // =========================================================================
    // ID/EX PIPELINE REGISTER
    // =========================================================================
    reg [31:0] pc_ex, read_data1_ex, read_data2_ex, imm_ex;
    reg [4:0]  rs1_ex, rs2_ex, rd_ex;
    reg [3:0]  instruction_funct_ex; 
    
    reg branch_ex, alu_src_ex, mem_read_ex, mem_write_ex, reg_write_ex, mem_to_reg_ex;
    reg [1:0] alu_op_ex;

    always @(posedge clk) begin
        if (rst || branch_taken_ex) begin 
            pc_ex <= 0; read_data1_ex <= 0; read_data2_ex <= 0; imm_ex <= 0;
            rs1_ex <= 0; rs2_ex <= 0; rd_ex <= 0; instruction_funct_ex <= 0;
            branch_ex <= 0; alu_src_ex <= 0; mem_read_ex <= 0; mem_write_ex <= 0;
            reg_write_ex <= 0; mem_to_reg_ex <= 0; alu_op_ex <= 0;
        end else begin
            pc_ex <= pc_id;
            read_data1_ex <= read_data1_id;
            read_data2_ex <= read_data2_id;
            imm_ex <= imm_id;
            rs1_ex <= rs1_id;
            rs2_ex <= rs2_id;
            rd_ex <= rd_id;
            instruction_funct_ex <= {instruction_id[30], instruction_id[14:12]};
            
            branch_ex <= branch_id; alu_src_ex <= alu_src_id; alu_op_ex <= alu_op_id;
            mem_read_ex <= mem_read_id; mem_write_ex <= mem_write_id;
            reg_write_ex <= reg_write_id; mem_to_reg_ex <= mem_to_reg_id;
        end
    end

    // =========================================================================
    // 3. EXECUTE (EX) STAGE
    // =========================================================================
    wire [3:0] alu_ctrl_ex;
    wire [31:0] alu_result_ex;
    wire alu_zero_ex;
    
    reg [31:0] forward_a_out;
    reg [31:0] forward_b_out;
    reg [31:0] alu_b_in;

    wire [1:0] forward_a;
    wire [1:0] forward_b;

    hazard_detection_unit hdu (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_ex),
        .mem_read_ex(mem_read_ex),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .stall(stall)
    );

    forwarding_unit fwd (
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rd_mem(rd_mem),       
        .rd_wb(rd_wb),         
        .reg_write_mem(reg_write_mem),
        .reg_write_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    always @(*) begin
        case (forward_a)
            2'b00: forward_a_out = read_data1_ex;
            2'b10: forward_a_out = alu_result_mem; 
            2'b01: forward_a_out = write_back_data; 
            default: forward_a_out = read_data1_ex;
        endcase
    end

    always @(*) begin
        case (forward_b)
            2'b00: forward_b_out = read_data2_ex;
            2'b10: forward_b_out = alu_result_mem; 
            2'b01: forward_b_out = write_back_data; 
            default: forward_b_out = read_data2_ex;
        endcase
    end

    always @(*) begin
        if (alu_src_ex) alu_b_in = imm_ex;
        else            alu_b_in = forward_b_out;
    end

    always @(*) begin
        branch_target_ex = pc_ex + imm_ex;
        branch_taken_ex  = branch_ex & alu_zero_ex;
    end

    alu_control alu_ctrl_inst (
        .alu_op(alu_op_ex),
        .funct3(instruction_funct_ex[2:0]),
        .funct7_b5(instruction_funct_ex[3]),
        .alu_ctrl(alu_ctrl_ex)
    );

    alu alu_inst (
        .a(forward_a_out),
        .b(alu_b_in),
        .alu_ctrl(alu_ctrl_ex),
        .result(alu_result_ex),
        .zero(alu_zero_ex)
    );

    // =========================================================================
    // EX/MEM PIPELINE REGISTER
    // =========================================================================
    reg [31:0] write_data_mem;
    reg mem_read_mem, mem_write_mem, mem_to_reg_mem;

    always @(posedge clk) begin
        if (rst) begin
            alu_result_mem <= 0; write_data_mem <= 0; rd_mem <= 0;
            mem_read_mem <= 0; mem_write_mem <= 0; reg_write_mem <= 0; mem_to_reg_mem <= 0;
        end else begin
            alu_result_mem <= alu_result_ex;
            write_data_mem <= forward_b_out; 
            rd_mem <= rd_ex;
            
            mem_read_mem <= mem_read_ex;
            mem_write_mem <= mem_write_ex;
            reg_write_mem <= reg_write_ex;
            mem_to_reg_mem <= mem_to_reg_ex;
        end
    end

    // =========================================================================
    // 4. MEMORY (MEM) STAGE
    // =========================================================================
    wire [31:0] read_data_mem;

    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read_mem),
        .mem_write(mem_write_mem),
        .address(alu_result_mem),
        .write_data(write_data_mem),
        .read_data(read_data_mem)
    );

    // =========================================================================
    // MEM/WB PIPELINE REGISTER
    // =========================================================================
    reg [31:0] alu_result_wb, read_data_wb;
    reg mem_to_reg_wb;

    always @(posedge clk) begin
        if (rst) begin
            alu_result_wb <= 0; read_data_wb <= 0; rd_wb <= 0;
            reg_write_wb <= 0; mem_to_reg_wb <= 0;
        end else begin
            alu_result_wb <= alu_result_mem;
            read_data_wb <= read_data_mem;
            rd_wb <= rd_mem;
            
            reg_write_wb <= reg_write_mem;
            mem_to_reg_wb <= mem_to_reg_mem;
        end
    end

    // =========================================================================
    // 5. WRITE BACK (WB) STAGE
    // =========================================================================
    
    always @(*) begin
        if (mem_to_reg_wb) write_back_data = read_data_wb;
        else               write_back_data = alu_result_wb;
    end

endmodule