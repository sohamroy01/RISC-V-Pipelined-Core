`timescale 1ns / 1ps

module instruction_memory #(
    parameter MEM_FILE = "program.mem"  
)(
    input [31:0] pc,
    output reg [31:0] instruction
);

    reg [31:0] memory [0:1023];

    initial begin
        $readmemh(MEM_FILE, memory);
    end

    always @(*) begin
        instruction = memory[pc[31:2]];
    end

endmodule