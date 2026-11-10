// Decoder test: real RV64I encodings (as emitted by GNU as) with exact
// full-struct comparison, plus illegal-encoding checks.
module tb_decoder;
  import sc64_pkg::*;

  logic [31:0] instr;
  ctrl_t       ctrl, e;
  int          errors = 0;

  sc64_decoder dut (.instr, .ctrl);

  task automatic run(input string name, input logic [31:0] i, input ctrl_t expd);
    instr = i;
    #1;
    if (ctrl !== expd) begin
      errors++;
      $display("%s FAIL instr=%h\n  got=%h\n  exp=%h", name, i, ctrl, expd);
    end
  endtask

  task automatic illegal(input string name, input logic [31:0] i);
    ctrl_t x;
    x = '0; x.illegal = 1'b1;
    run(name, i, x);
  endtask

  initial begin
    e = '0; e.alu_op = ALU_ADD; e.src_b = B_IMM; e.imm_type = IMM_I; e.reg_write = 1;
    run("addi x1,x0,5", 32'h00500093, e);

    e = '0; e.alu_op = ALU_ADD; e.reg_write = 1;
    run("add x3,x1,x2", 32'h002081B3, e);

    e = '0; e.alu_op = ALU_SUB; e.reg_write = 1;
    run("sub x3,x1,x2", 32'h402081B3, e);

    e = '0; e.alu_op = ALU_SRA; e.src_b = B_IMM; e.imm_type = IMM_I; e.reg_write = 1;
    run("srai x1,x1,1", 32'h4010D093, e);

    e = '0; e.alu_op = ALU_ADD; e.word = 1; e.src_b = B_IMM; e.imm_type = IMM_I; e.reg_write = 1;
    run("addiw x1,x1,1", 32'h0010809B, e);

    e = '0; e.alu_op = ALU_ADD; e.src_a = A_ZERO; e.src_b = B_IMM; e.imm_type = IMM_U; e.reg_write = 1;
    run("lui x1,0x12345", 32'h123450B7, e);

    e = '0; e.alu_op = ALU_ADD; e.src_a = A_PC; e.src_b = B_IMM; e.imm_type = IMM_U; e.reg_write = 1;
    run("auipc x1,0", 32'h00000097, e);

    e = '0; e.alu_op = ALU_ADD; e.src_a = A_PC; e.src_b = B_IMM; e.imm_type = IMM_J;
    e.jal = 1; e.reg_write = 1;
    run("jal x1,0", 32'h000000EF, e);

    e = '0; e.alu_op = ALU_ADD; e.src_b = B_IMM; e.imm_type = IMM_I; e.jalr = 1; e.reg_write = 1;
    run("jalr x0,0(x1)", 32'h00008067, e);

    e = '0; e.alu_op = ALU_ADD; e.src_a = A_PC; e.src_b = B_IMM; e.imm_type = IMM_B; e.branch = 1;
    run("beq x1,x2,8", 32'h00208463, e);

    e = '0; e.alu_op = ALU_ADD; e.src_b = B_IMM; e.imm_type = IMM_I;
    e.mem_read = 1; e.reg_write = 1; e.mem_size = 2'd3;
    run("ld x5,8(x2)", 32'h00813283, e);

    e.mem_size = 2'd2; e.mem_unsigned = 1;
    run("lwu x1,0(x2)", 32'h00016083, e);

    e = '0; e.alu_op = ALU_ADD; e.src_b = B_IMM; e.imm_type = IMM_S;
    e.mem_write = 1; e.mem_size = 2'd3;
    run("sd x5,8(x2)", 32'h00513423, e);

    e = '0; e.fence = 1;
    run("fence", 32'h0FF0000F, e);

    e = '0; e.system = 1;
    run("ecall", 32'h00000073, e);

    illegal("all zeros (compressed/invalid)", 32'h00000000);
    illegal("reserved opcode", 32'hFFFFFFFF);
    illegal("mul (M ext, not yet supported)", 32'h022081B3);
    illegal("slli with bad funct6", 32'h40109093);
    illegal("load funct3=7", 32'h00007003);
    illegal("store funct3=4", 32'h00004023);
    illegal("branch funct3=2", 32'h00002063);
    illegal("jalr funct3=1", 32'h00009067);

    if (errors != 0) $fatal(1, "tb_decoder FAILED with %0d errors", errors);
    $display("tb_decoder PASSED");
    $finish;
  end
endmodule
