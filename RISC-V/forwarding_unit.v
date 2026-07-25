`timescale 1ns / 1ps

module forwarding_unit (
    // Source registers of the instruction currently in the Execute (EX) stage
    input [4:0] rs1_ex,
    input [4:0] rs2_ex,
    
    // Destination registers of instructions further down the pipeline
    input [4:0] rd_mem, // Destination of instruction in MEM stage
    input [4:0] rd_wb, // Destination of instruction in WB stage
    
    // Control signals to verify those instructions actually write to a register
    input reg_write_mem, 
    input reg_write_wb,  
    
    // 2-bit selector signals for the ALU input multiplexers
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);

    always @(*) begin   
        // Default: No Forwarding        
        forward_a = 2'b00;
        forward_b = 2'b00;

        // Forward A Logic (for ALU Input 1)
        
        // Priority 1: EX/MEM Hazard (Instruction immediately prior)
        if (reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs1_ex)) begin
            forward_a = 2'b10;
        end
        // Priority 2: MEM/WB Hazard (Instruction 2 cycles prior)
        else if (reg_write_wb && (rd_wb != 5'b00000) && (rd_wb == rs1_ex)) begin
            forward_a = 2'b01;
        end

        // Forward B Logic (for ALU Input 2)
        
        // Priority 1: EX/MEM Hazard (Instruction immediately prior)
        if (reg_write_mem && (rd_mem != 5'b00000) && (rd_mem == rs2_ex)) begin
            forward_b = 2'b10;
        end
        // Priority 2: MEM/WB Hazard (Instruction 2 cycles prior)
        else if (reg_write_wb && (rd_wb != 5'b00000) && (rd_wb == rs2_ex)) begin
            forward_b = 2'b01;
        end
    end

endmodule
