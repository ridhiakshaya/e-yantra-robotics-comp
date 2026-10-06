
// main_decoder.v - logic for main decoder

module main_decoder (
    input  [6:0] op,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUSrc,
    output       ALUSrcA,
    output       RegWrite, Jump, Jalr,
    output [1:0] ImmSrc,
    output [1:0] ALUOp
);

reg [12:0] controls;

always @(*) begin
    case (op)

        // controls:
        // RegWrite_ImmSrc_ALUSrc_ALUSrcA_MemWrite_ResultSrc_Branch_ALUOp_Jump_Jalr

        7'b0000011: controls = 13'b1_00_1_0_0_01_0_00_0_0; // lw

        7'b0100011: controls = 13'b0_01_1_0_1_00_0_00_0_0; // sw

        7'b0110011: controls = 13'b1_xx_0_0_0_00_0_10_0_0; // R-type

        7'b1100011: controls = 13'b0_10_0_0_0_00_1_01_0_0; // beq

        7'b0010011: controls = 13'b1_00_1_0_0_00_0_10_0_0; // I-type ALU

        7'b1101111: controls = 13'b1_11_0_0_0_10_0_00_1_0; // jal

        // LUI: rd = {instr[31:12], 12'b0}
        7'b0110111: controls = 13'b1_xx_0_0_0_11_0_00_0_0; // lui

        // AUIPC: rd = PC + {instr[31:12], 12'b0}
        7'b0010111: controls = 13'b1_xx_1_1_0_00_0_00_0_0; // auipc

        // JALR: rd = PC+4, PC = rs1 + sign-extended immediate
        7'b1100111: controls = 13'b1_00_1_0_0_10_0_00_0_1; // jalr

        default: controls = 13'bx_xx_x_x_x_xx_x_xx_x_x;
    endcase
end

assign {
    RegWrite,
    ImmSrc,
    ALUSrc,
    ALUSrcA,
    MemWrite,
    ResultSrc,
    Branch,
    ALUOp,
    Jump,
    Jalr
} = controls;

endmodule

