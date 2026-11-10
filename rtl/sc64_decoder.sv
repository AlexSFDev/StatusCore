// StatusCore SC64 - RV64I instruction decoder (32-bit encodings only).
// Not yet decoded: M/A/C extensions (reported illegal), CSR/privileged ops
// (flagged `system`, decoded later by the CSR unit).
module sc64_decoder
  import sc64_pkg::*;
(
  /* verilator lint_off UNUSEDSIGNAL */
  input  logic [31:0] instr,   // register-specifier fields unused here
  /* verilator lint_on UNUSEDSIGNAL */
  output ctrl_t       ctrl
);

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic       f7_zero, f7_alt, f6_zero, f6_alt;
  alu_op_e    base_op;

  assign opcode  = instr[6:0];
  assign funct3  = instr[14:12];
  assign funct7  = instr[31:25];
  assign f7_zero = (funct7 == 7'b0000000);
  assign f7_alt  = (funct7 == 7'b0100000);
  assign f6_zero = (instr[31:26] == 6'b000000);   // RV64 shift-immediate: 6-bit shamt
  assign f6_alt  = (instr[31:26] == 6'b010000);

  // ALU op implied by funct3 (SUB for OP/OP-32 is patched in below).
  always_comb begin
    case (funct3)
      3'b000:  base_op = ALU_ADD;
      3'b001:  base_op = ALU_SLL;
      3'b010:  base_op = ALU_SLT;
      3'b011:  base_op = ALU_SLTU;
      3'b100:  base_op = ALU_XOR;
      3'b101:  base_op = instr[30] ? ALU_SRA : ALU_SRL;
      3'b110:  base_op = ALU_OR;
      default: base_op = ALU_AND;
    endcase
  end

  always_comb begin
    ctrl         = '0;
    ctrl.illegal = 1'b1;

    if (instr[1:0] == 2'b11) begin
      case (opcode)
        OPC_LUI: begin
          ctrl.illegal = 1'b0;
          ctrl.imm_type = IMM_U; ctrl.src_a = A_ZERO; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.reg_write = 1'b1;
        end

        OPC_AUIPC: begin
          ctrl.illegal = 1'b0;
          ctrl.imm_type = IMM_U; ctrl.src_a = A_PC; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.reg_write = 1'b1;
        end

        OPC_JAL: begin   // ALU computes pc + imm (target); link value comes from pc+4
          ctrl.illegal = 1'b0;
          ctrl.imm_type = IMM_J; ctrl.src_a = A_PC; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.jal = 1'b1; ctrl.reg_write = 1'b1;
        end

        OPC_JALR: begin
          ctrl.illegal = (funct3 != 3'b000);
          ctrl.imm_type = IMM_I; ctrl.src_a = A_RS1; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.jalr = 1'b1; ctrl.reg_write = 1'b1;
        end

        OPC_BRANCH: begin  // ALU computes pc + imm; compare done by branch unit via funct3
          ctrl.illegal = (funct3 == 3'b010) || (funct3 == 3'b011);
          ctrl.imm_type = IMM_B; ctrl.src_a = A_PC; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.branch = 1'b1;
        end

        OPC_LOAD: begin
          ctrl.illegal = (funct3 == 3'b111);
          ctrl.imm_type = IMM_I; ctrl.src_a = A_RS1; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.mem_read = 1'b1; ctrl.reg_write = 1'b1;
          ctrl.mem_size = funct3[1:0]; ctrl.mem_unsigned = funct3[2];
        end

        OPC_STORE: begin
          ctrl.illegal = funct3[2];
          ctrl.imm_type = IMM_S; ctrl.src_a = A_RS1; ctrl.src_b = B_IMM;
          ctrl.alu_op = ALU_ADD; ctrl.mem_write = 1'b1;
          ctrl.mem_size = funct3[1:0];
        end

        OPC_OP_IMM: begin
          ctrl.illegal = (funct3 == 3'b001) ? !f6_zero :
                         (funct3 == 3'b101) ? !(f6_zero || f6_alt) : 1'b0;
          ctrl.imm_type = IMM_I; ctrl.src_a = A_RS1; ctrl.src_b = B_IMM;
          ctrl.alu_op = base_op; ctrl.reg_write = 1'b1;
        end

        OPC_OP: begin
          ctrl.illegal = !(f7_zero || (f7_alt && (funct3 == 3'b000 || funct3 == 3'b101)));
          ctrl.src_a = A_RS1; ctrl.src_b = B_RS2; ctrl.reg_write = 1'b1;
          ctrl.alu_op = (funct3 == 3'b000 && f7_alt) ? ALU_SUB : base_op;
        end

        OPC_OP_IMM32: begin
          ctrl.illegal = (funct3 == 3'b000) ? 1'b0 :
                         (funct3 == 3'b001) ? !f7_zero :
                         (funct3 == 3'b101) ? !(f7_zero || f7_alt) : 1'b1;
          ctrl.word = 1'b1;
          ctrl.imm_type = IMM_I; ctrl.src_a = A_RS1; ctrl.src_b = B_IMM;
          ctrl.alu_op = base_op; ctrl.reg_write = 1'b1;
        end

        OPC_OP32: begin
          ctrl.illegal = (funct3 == 3'b000) ? !(f7_zero || f7_alt) :
                         (funct3 == 3'b001) ? !f7_zero :
                         (funct3 == 3'b101) ? !(f7_zero || f7_alt) : 1'b1;
          ctrl.word = 1'b1;
          ctrl.src_a = A_RS1; ctrl.src_b = B_RS2; ctrl.reg_write = 1'b1;
          ctrl.alu_op = (funct3 == 3'b000 && f7_alt) ? ALU_SUB : base_op;
        end

        OPC_MISC_MEM: begin
          ctrl.illegal = (funct3 != 3'b000) && (funct3 != 3'b001);
          ctrl.fence = 1'b1;
        end

        OPC_SYSTEM: begin
          ctrl.illegal = 1'b0;
          ctrl.system  = 1'b1;
        end

        default: ctrl.illegal = 1'b1;
      endcase
    end

    // Illegal instructions must have no architectural side effects.
    if (ctrl.illegal) begin
      ctrl         = '0;
      ctrl.illegal = 1'b1;
    end
  end

endmodule
