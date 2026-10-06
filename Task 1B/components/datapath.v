
//datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         ALUSrcA,
    input         Jalr,
    input         RegWrite,
    input [1:0]   ImmSrc,
    input [2:0]   ALUControl,
    output        Zero,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCPlus4, PCTarget;
wire [31:0] PCNextNormal;
wire [31:0] JalrTarget;

wire [31:0] ImmExt;
wire [31:0] ImmExtU;

wire [31:0] SrcA;
wire [31:0] SrcAReg;
wire [31:0] SrcB;
wire [31:0] ALUImm;
wire [31:0] WriteData;
wire [31:0] ALUResult;


// -----------------------------------------------------
// Immediate generation
// -----------------------------------------------------

// Existing I/S/B/J immediate
imm_extend ext (
    Instr[31:7],
    ImmSrc,
    ImmExt
);

// U-type immediate for LUI and AUIPC
assign ImmExtU = {Instr[31:12], 12'b0};


// -----------------------------------------------------
// Next PC logic
// -----------------------------------------------------

reset_ff #(32) pcreg (
    clk,
    reset,
    PCNext,
    PC
);

adder pcadd4 (
    PC,
    32'd4,
    PCPlus4
);

// Used by BEQ and JAL
adder pcaddbranch (
    PC,
    ImmExt,
    PCTarget
);

// Normal PC selection:
// 0 -> PC + 4
// 1 -> branch/JAL target
mux2 #(32) pcmux (
    PCPlus4,
    PCTarget,
    PCSrc,
    PCNextNormal
);

// JALR target = rs1 + immediate.
// RISC-V requires bit 0 of target to be cleared.
assign JalrTarget = {ALUResult[31:1], 1'b0};

// Final PC selection:
// normal branch/JAL path or JALR target
mux2 #(32) jalrmux (
    PCNextNormal,
    JalrTarget,
    Jalr,
    PCNext
);


// -----------------------------------------------------
// Register file
// -----------------------------------------------------

reg_file rf (
    clk,
    RegWrite,
    Instr[19:15],
    Instr[24:20],
    Instr[11:7],
    Result,
    SrcAReg,
    WriteData
);


// -----------------------------------------------------
// ALU input selection
// -----------------------------------------------------

// Normal instructions use rs1.
// AUIPC uses PC.
mux2 #(32) srcamux (
    SrcAReg,
    PC,
    ALUSrcA,
    SrcA
);

mux2 #(32) immux (
    ImmExt,
    ImmExtU,
    ALUSrcA,
    ALUImm
);

mux2 #(32) srcbmux (
    WriteData,
    ALUImm,
    ALUSrc,
    SrcB
);

// -----------------------------------------------------
// ALU
// -----------------------------------------------------

alu alu (
    SrcA,
    SrcB,
    ALUControl,
    ALUResult,
    Zero
);


// -----------------------------------------------------
// Result selection
//
// 00 -> ALU result
// 01 -> memory data
// 10 -> PC + 4
// 11 -> U-type immediate (LUI)
// -----------------------------------------------------

mux4 #(32) resultmux (
    ALUResult,
    ReadData,
    PCPlus4,
    ImmExtU,
    ResultSrc,
    Result
);


assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule