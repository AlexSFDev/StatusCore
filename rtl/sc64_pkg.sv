// StatusCore SC64 - shared types and constants (RV64I base, stage 1)
package sc64_pkg;

  // ---- Major opcodes (instr[6:0]) ----------------------------------------
  localparam logic [6:0] OPC_LOAD     = 7'b0000011;
  localparam logic [6:0] OPC_MISC_MEM = 7'b0001111;
  localparam logic [6:0] OPC_OP_IMM   = 7'b0010011;
  localparam logic [6:0] OPC_AUIPC    = 7'b0010111;
  localparam logic [6:0] OPC_OP_IMM32 = 7'b0011011;
  localparam logic [6:0] OPC_STORE    = 7'b0100011;
  localparam logic [6:0] OPC_OP       = 7'b0110011;
  localparam logic [6:0] OPC_LUI      = 7'b0110111;
  localparam logic [6:0] OPC_OP32     = 7'b0111011;
  localparam logic [6:0] OPC_BRANCH   = 7'b1100011;
  localparam logic [6:0] OPC_JALR     = 7'b1100111;
  localparam logic [6:0] OPC_JAL      = 7'b1101111;
  localparam logic [6:0] OPC_SYSTEM   = 7'b1110011;

  // ---- ALU operations -----------------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD  = 4'd0,
    ALU_SUB  = 4'd1,
    ALU_SLL  = 4'd2,
    ALU_SLT  = 4'd3,
    ALU_SLTU = 4'd4,
    ALU_XOR  = 4'd5,
    ALU_SRL  = 4'd6,
    ALU_SRA  = 4'd7,
    ALU_OR   = 4'd8,
    ALU_AND  = 4'd9
  } alu_op_e;

  // ---- Immediate formats --------------------------------------------------
  typedef enum logic [2:0] {
    IMM_I = 3'd0,
    IMM_S = 3'd1,
    IMM_B = 3'd2,
    IMM_U = 3'd3,
    IMM_J = 3'd4
  } imm_type_e;

  // ---- ALU operand selects ------------------------------------------------
  typedef enum logic [1:0] {
    A_RS1  = 2'd0,
    A_PC   = 2'd1,
    A_ZERO = 2'd2
  } src_a_e;

  typedef enum logic {
    B_RS2 = 1'b0,
    B_IMM = 1'b1
  } src_b_e;

  // ---- Decoded control word ----------------------------------------------
  // Invariant: when illegal == 1, every other field is zero (no side effects).
  typedef struct packed {
    alu_op_e   alu_op;
    logic      word;          // 32-bit (*W) operation, result sign-extended
    src_a_e    src_a;
    src_b_e    src_b;
    imm_type_e imm_type;
    logic      reg_write;
    logic      mem_read;
    logic      mem_write;
    logic [1:0] mem_size;     // 0=byte 1=half 2=word 3=double
    logic      mem_unsigned;  // zero-extend load result
    logic      branch;        // conditional branch (funct3 selects compare)
    logic      jal;
    logic      jalr;
    logic      fence;         // FENCE / FENCE.I (funct3 distinguishes)
    logic      system;        // ECALL/EBREAK/CSR/xRET - decoded in the CSR unit
    logic      illegal;
  } ctrl_t;

endpackage
