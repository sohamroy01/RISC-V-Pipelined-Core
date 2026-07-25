`timescale 1ns / 1ps

module tb_core();

    reg clk;
    reg rst;

    rv32i_pipelined_core uut (
        .clk(clk),
        .rst(rst)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        $display("========================================");
        $display("Starting RISC-V Pipeline Simulation...");
        $display("========================================");

        clk = 0;
        rst = 1;

        #20;

        rst = 0;
        $display("[%0t ns] Reset released. Processor running.", $time);

        #200;

        $display("========================================");
        $display("[%0t ns] Simulation finished.", $time);
        $display("========================================");
        $finish;
    end

endmodule
