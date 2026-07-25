`timescale 1ns / 1ps

module data_memory (
    input clk,
    input mem_read, // From Control Unit (delayed to MEM stage)
    input mem_write, // From Control Unit (delayed to MEM stage)
    input [31:0] address, // From ALU Result
    input [31:0] write_data, // From rs2 (passed down the pipeline)
    output reg  [31:0] read_data
);

    reg [31:0] memory [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'd0;
        end
    end

    // Synchronous Write Logic
    
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address[31:2]] <= write_data;
        end
    end

    // Combinational Read Logic
    // Considering memory reads to be instant.

    always @(*) begin
        if (mem_read) begin
            read_data = memory[address[31:2]];
        end else begin
            read_data = 32'd0;
        end
    end

endmodule