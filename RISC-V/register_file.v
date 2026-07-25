`timescale 1ns / 1ps

module register_file (
    input clk,
    input rst,
    input reg_write,         
    input [4:0] rs1,         
    input [4:0] rs2,         
    input [4:0] rd,          
    input [31:0] write_data,
    output reg  [31:0] read_data1, 
    output reg  [31:0] read_data2
);

    // The actual memory array: 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];
    integer i;

    // Combinational Read Logic (with internal forwarding)

    always @(*) begin
        // Read Port 1 (rs1)
        if (rs1 == 5'b00000) begin
            read_data1 = 32'b0; // x0 is always 0
        end else if (reg_write && (rs1 == rd)) begin
            read_data1 = write_data; // Internal forward: read the newest data being written
        end else begin
            read_data1 = registers[rs1]; // Normal read
        end

        // Read Port 2 (rs2)
        if (rs2 == 5'b00000) begin
            read_data2 = 32'b0; // x0 is always 0
        end else if (reg_write && (rs2 == rd)) begin
            read_data2 = write_data; // Internal forward: read the newest data being written
        end else begin
            read_data2 = registers[rs2]; // Normal read
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (reg_write && (rd != 5'b00000)) begin
            // Only write if enabled AND the destination is not x0
            registers[rd] <= write_data;
        end
    end

endmodule
