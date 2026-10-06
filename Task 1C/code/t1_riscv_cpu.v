// t1_riscv_cpu.v

module t1_riscv_cpu (
    input         clk, reset,
    input         Ext_MemWrite,
    input  [31:0] Ext_WriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;

wire [31:0] DataAdr_rv32;
wire [31:0] WriteData_rv32;
wire        MemWrite_rv32;

// Actual 32-bit value written into data_mem
reg  [31:0] MemWriteData_rv32;
wire [31:0] MemWriteData;



riscv_cpu rvcpu (
    clk,
    reset,
    PC,
    Instr,
    MemWrite_rv32,
    DataAdr_rv32,
    WriteData_rv32,
    ReadData,
    Result
);


// -----------------------------------------------------
// Instruction memory
// -----------------------------------------------------

instr_mem instrmem (
    PC,
    Instr
);


always @(*) begin

    // Default behaviour = SW
    MemWriteData_rv32 = WriteData_rv32;

    if (MemWrite_rv32) begin

        case (Instr[14:12])

            // -------------------------------------------------
            // SB - Store Byte
            // -------------------------------------------------

            3'b000: begin

                case (DataAdr_rv32[1:0])

                    2'b00:
                        MemWriteData_rv32 = {
                            ReadData[31:8],
                            WriteData_rv32[7:0]
                        };

                    2'b01:
                        MemWriteData_rv32 = {
                            ReadData[31:16],
                            WriteData_rv32[7:0],
                            ReadData[7:0]
                        };

                    2'b10:
                        MemWriteData_rv32 = {
                            ReadData[31:24],
                            WriteData_rv32[7:0],
                            ReadData[15:0]
                        };

                    2'b11:
                        MemWriteData_rv32 = {
                            WriteData_rv32[7:0],
                            ReadData[23:0]
                        };

                endcase

            end


            3'b001: begin

                case (DataAdr_rv32[1])

                    // Lower halfword
                    1'b0:
                        MemWriteData_rv32 = {
                            ReadData[31:16],
                            WriteData_rv32[15:0]
                        };

                    // Upper halfword
                    1'b1:
                        MemWriteData_rv32 = {
                            WriteData_rv32[15:0],
                            ReadData[15:0]
                        };

                endcase

            end


            3'b010:
                MemWriteData_rv32 = WriteData_rv32;


            default:
                MemWriteData_rv32 = WriteData_rv32;

        endcase

    end

end


assign MemWrite =
    (Ext_MemWrite && reset)
    ? 1'b1
    : MemWrite_rv32;



assign WriteData =
    (Ext_MemWrite && reset)
    ? Ext_WriteData
    : WriteData_rv32;


assign DataAdr =
    reset
    ? Ext_DataAdr
    : DataAdr_rv32;



assign MemWriteData =
    (Ext_MemWrite && reset)
    ? Ext_WriteData
    : MemWriteData_rv32;


data_mem datamem (
    clk,
    MemWrite,
    DataAdr,
    MemWriteData,
    ReadData
);

endmodule