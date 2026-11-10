// StatusCore SC64 - immediate generator (RV64: all immediates sign-extend to 64 bits)
module sc64_immgen
  import sc64_pkg::*;
(
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [31:0] instr,   // opcode/register fields intentionally unused
  /* verilator lint_on UNUSEDSIGNAL */
  input  imm_type_e   imm_type,
  output logic [63:0] imm
);

  always_comb begin
    case (imm_type)
      IMM_I:   imm = {{52{instr[31]}}, instr[31:20]};
      IMM_S:   imm = {{52{instr[31]}}, instr[31:25], instr[11:7]};
      IMM_B:   imm = {{51{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
      IMM_U:   imm = {{32{instr[31]}}, instr[31:12], 12'b0};
      IMM_J:   imm = {{43{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
      default: imm = '0;
    endcase
  end

endmodule
