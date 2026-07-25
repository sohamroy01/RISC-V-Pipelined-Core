`timescale 1ns / 1ps

module hazard_detection_unit (
    input [4:0] rs1_id, // Source register 1 in the Decode (ID) stage
    input [4:0] rs2_id, // Source register 2 in the Decode (ID) stage
    input [4:0] rd_ex, // Destination register currently in the Execute (EX) stage
    input mem_read_ex, // The MemRead control signal in the Execute (EX) stage
    
    output reg pc_write, // Enables/Disables updating the Program Counter
    output reg if_id_write, // Enables/Disables updating the IF/ID pipeline register
    output reg stall // Signal to flush/zero-out control signals going into EX
);

    always @(*) begin
        // Load-Use Hazard Condition
        // 1. The instruction in EX is a Load (mem_read_ex == 1)
        // 2. The destination register is not x0 (rd_ex != 0)
        // 3. The destination matches either rs1 or rs2 of the ID instruction
        if (mem_read_ex && (rd_ex != 5'b00000) && ((rd_ex == rs1_id) || (rd_ex == rs2_id))) begin
            // We have a collision! Stall the pipeline.
            pc_write = 1'b0;  // Freeze the PC (do not fetch the next instruction)
            if_id_write = 1'b0;  // Freeze IF/ID (keep the current instruction in the Decode stage)
            stall = 1'b1;  // Tell the ID/EX register to turn all control signals to 0
        end else begin
            // No hazard detected. Normal execution.
            pc_write = 1'b1;  
            if_id_write = 1'b1;
            stall = 1'b0;
        end
    end

endmodule
