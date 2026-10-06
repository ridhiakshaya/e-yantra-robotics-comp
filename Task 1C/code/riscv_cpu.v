// riscv_cpu.v - single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);


wire        ALUSrc;
wire        ALUSrcA;
wire        RegWrite;
wire        Jump;
wire        Jalr;

wire        Zero;
wire        LessThan;
wire        LessThanU;

wire        PCSrc;

wire [1:0]  ResultSrc;
wire [1:0]  ImmSrc;
wire [3:0]  ALUControl;

controller c (
    Instr[6:0],       // opcode
    Instr[14:12],     // funct3
    Instr[30],        // funct7 bit 5

    Zero,
    LessThan,
    LessThanU,

    ResultSrc,
    MemWrite,
    PCSrc,
    ALUSrc,
    ALUSrcA,
    RegWrite,
    Jump,
    Jalr,
    ImmSrc,
    ALUControl
);


datapath dp (
    clk,
    reset,

    ResultSrc,
    PCSrc,
    ALUSrc,
    ALUSrcA,
    Jalr,
    RegWrite,
    ImmSrc,
    ALUControl,

    Zero,
    LessThan,
    LessThanU,

    PC,
    Instr,

    Mem_WrAddr,
    Mem_WrData,

    ReadData,
    Result
);

endmodule