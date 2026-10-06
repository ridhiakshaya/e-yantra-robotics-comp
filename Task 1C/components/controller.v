// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,

    input        Zero,
    input        LessThan,
    input        LessThanU,

    output       [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc,
    output       ALUSrc,
    output       ALUSrcA,
    output       RegWrite,
    output       Jump,
    output       Jalr,
    output [1:0] ImmSrc,
    output [3:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch;

reg        BranchTaken;


main_decoder md (
    op,
    ResultSrc,
    MemWrite,
    Branch,
    ALUSrc,
    ALUSrcA,
    RegWrite,
    Jump,
    Jalr,
    ImmSrc,
    ALUOp
);



alu_decoder ad (
    op[5],
    funct3,
    funct7b5,
    ALUOp,
    ALUControl
);



always @(*) begin

    case (funct3)

        // BEQ
        3'b000:
            BranchTaken = Zero;

        // BNE
        3'b001:
            BranchTaken = ~Zero;

        // BLT - signed
        3'b100:
            BranchTaken = LessThan;

        // BGE - signed
        3'b101:
            BranchTaken = ~LessThan;

        // BLTU - unsigned
        3'b110:
            BranchTaken = LessThanU;

        // BGEU - unsigned
        3'b111:
            BranchTaken = ~LessThanU;

        default:
            BranchTaken = 1'b0;

    endcase

end



assign PCSrc = (Branch & BranchTaken) | Jump;

endmodule