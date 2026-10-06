// alu.v - ALU module

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,
    input       [3:0] alu_ctrl,
    output reg  [WIDTH-1:0] alu_out,
    output      zero
);

always @(*) begin

    case (alu_ctrl)

        // ADD / ADDI
        4'b0000:
            alu_out = a + b;

        // SUB
        4'b0001:
            alu_out = a - b;

        // AND / ANDI
        4'b0010:
            alu_out = a & b;

        // OR / ORI
        4'b0011:
            alu_out = a | b;

        // XOR / XORI
        4'b0100:
            alu_out = a ^ b;

        // SLT / SLTI
        // Signed comparison
        4'b0101:
            alu_out = ($signed(a) < $signed(b))
                      ? 32'b1
                      : 32'b0;

        // SLL / SLLI
        4'b0110:
            alu_out = a << b[4:0];

        // SRL / SRLI
        // Logical right shift
        4'b0111:
            alu_out = a >> b[4:0];

        // SRA / SRAI
        // Arithmetic right shift
        4'b1000:
            alu_out = $signed(a) >>> b[4:0];

        // SLTU / SLTIU
        // Unsigned comparison
        4'b1001:
            alu_out = (a < b)
                      ? 32'b1
                      : 32'b0;

        default:
            alu_out = 32'b0;

    endcase

end


assign zero = (alu_out == 32'b0);

endmodule