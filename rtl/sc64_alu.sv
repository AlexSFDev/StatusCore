// StatusCore SC64 - 64-bit integer ALU (RV64I incl. *W variants). Combinational.
module sc64_alu
  import sc64_pkg::*;
(
  input  alu_op_e     op,
  input  logic        word,   // 1: operate on low 32 bits, sign-extend result
  input  logic [63:0] a,
  input  logic [63:0] b,
  output logic [63:0] y
);

  logic [5:0]         shamt;
  logic [63:0]        srl_src;
  logic signed [63:0] sra_src;
  logic [63:0]        sra_res;
  logic [63:0]        r;

  // RV64: 6-bit shift amount; *W shifts use 5 bits.
  assign shamt   = word ? {1'b0, b[4:0]} : b[5:0];
  // Pre-extend the source so a 64-bit shift yields the correct low 32 bits.
  assign srl_src = word ? {32'b0, a[31:0]}         : a;
  assign sra_src = word ? {{32{a[31]}}, a[31:0]}   : a;
  assign sra_res = sra_src >>> shamt;

  always_comb begin
    case (op)
      ALU_ADD:  r = a + b;
      ALU_SUB:  r = a - b;
      ALU_SLL:  r = a << shamt;
      ALU_SLT:  r = {63'b0, ($signed(a) < $signed(b))};
      ALU_SLTU: r = {63'b0, (a < b)};
      ALU_XOR:  r = a ^ b;
      ALU_SRL:  r = srl_src >> shamt;
      ALU_SRA:  r = sra_res;
      ALU_OR:   r = a | b;
      ALU_AND:  r = a & b;
      default:  r = '0;
    endcase
  end

  assign y = word ? {{32{r[31]}}, r[31:0]} : r;

endmodule
