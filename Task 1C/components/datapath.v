// datapath.v

module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         PCSrc, ALUSrc,
    input         ALUSrcA,
    input         Jalr,
    input         RegWrite,
    input [1:0]   ImmSrc,
    input [3:0]   ALUControl,

    output        Zero,
    output        LessThan,
    output        LessThanU,

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

reg  [31:0] LoadData;

imm_extend ext (
    Instr[31:7],
    ImmSrc,
    ImmExt
);

// U-type immediate for LUI and AUIPC
assign ImmExtU = {Instr[31:12], 12'b0};


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

adder pcaddbranch (
    PC,
    ImmExt,
    PCTarget
);

mux2 #(32) pcmux (
    PCPlus4,
    PCTarget,
    PCSrc,
    PCNextNormal
);


// -----------------------------------------------------
// JALR
// -----------------------------------------------------



assign JalrTarget = {
    ALUResult[31:1],
    1'b0
};

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
// Branch comparisons
// -----------------------------------------------------

// Signed comparison for BLT / BGE

assign LessThan =
    ($signed(SrcAReg) < $signed(WriteData));


// Unsigned comparison for BLTU / BGEU

assign LessThanU =
    (SrcAReg < WriteData);


// -----------------------------------------------------
// Load data processing
// -----------------------------------------------------
//
// funct3:
//
// 000 = LB
// 001 = LH
// 010 = LW
// 100 = LBU
// 101 = LHU
//
// ALUResult[1:0] selects the byte inside the word.
// -----------------------------------------------------

always @(*) begin

    // Default = full 32-bit word
    LoadData = ReadData;

    case (Instr[14:12])

        // -------------------------------------------------
        // LB - Load Byte, sign extended
        // -------------------------------------------------

        3'b000: begin

            case (ALUResult[1:0])

                2'b00:
                    LoadData = {
                        {24{ReadData[7]}},
                        ReadData[7:0]
                    };

                2'b01:
                    LoadData = {
                        {24{ReadData[15]}},
                        ReadData[15:8]
                    };

                2'b10:
                    LoadData = {
                        {24{ReadData[23]}},
                        ReadData[23:16]
                    };

                2'b11:
                    LoadData = {
                        {24{ReadData[31]}},
                        ReadData[31:24]
                    };

            endcase

        end


        // -------------------------------------------------
        // LH - Load Halfword, sign extended
        // -------------------------------------------------

        3'b001: begin

            if (ALUResult[1] == 1'b0)

                LoadData = {
                    {16{ReadData[15]}},
                    ReadData[15:0]
                };

            else

                LoadData = {
                    {16{ReadData[31]}},
                    ReadData[31:16]
                };

        end


        // -------------------------------------------------
        // LW - Load Word
        // -------------------------------------------------

        3'b010:
            LoadData = ReadData;


        // -------------------------------------------------
        // LBU - Load Byte, zero extended
        // -------------------------------------------------

        3'b100: begin

            case (ALUResult[1:0])

                2'b00:
                    LoadData = {
                        24'b0,
                        ReadData[7:0]
                    };

                2'b01:
                    LoadData = {
                        24'b0,
                        ReadData[15:8]
                    };

                2'b10:
                    LoadData = {
                        24'b0,
                        ReadData[23:16]
                    };

                2'b11:
                    LoadData = {
                        24'b0,
                        ReadData[31:24]
                    };

            endcase

        end


        // -------------------------------------------------
        // LHU - Load Halfword, zero extended
        // -------------------------------------------------

        3'b101: begin

            if (ALUResult[1] == 1'b0)

                LoadData = {
                    16'b0,
                    ReadData[15:0]
                };

            else

                LoadData = {
                    16'b0,
                    ReadData[31:16]
                };

        end


        default:
            LoadData = ReadData;

    endcase

end


// -----------------------------------------------------
// Result selection
//
// 00 -> ALU result
// 01 -> processed memory load
// 10 -> PC + 4
// 11 -> U-type immediate
// -----------------------------------------------------

mux4 #(32) resultmux (
    ALUResult,
    LoadData,
    PCPlus4,
    ImmExtU,
    ResultSrc,
    Result
);


// -----------------------------------------------------
// Memory interface
// -----------------------------------------------------

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule