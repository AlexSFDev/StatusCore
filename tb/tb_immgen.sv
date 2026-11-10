// Immediate generator test: encode a known immediate into each instruction
// format per the RISC-V spec (random garbage in all non-immediate fields),
// then check the generator recovers the sign-extended value.
module tb_immgen;
  import sc64_pkg::*;

  logic [31:0] instr;
  imm_type_e   imm_type;
  logic [63:0] imm;
  int          errors = 0;

  sc64_immgen dut (.instr, .imm_type, .imm);

  task automatic check(input string name, input imm_type_e t,
                       input logic [31:0] i, input logic [63:0] expd);
    instr = i; imm_type = t;
    #1;
    if (imm !== expd) begin
      errors++;
      $display("%s FAIL instr=%h got=%h exp=%h", name, i, imm, expd);
    end
  endtask

  initial begin
    for (int n = 0; n < 100000; n++) begin
      logic [31:0] v;
      logic [12:0] mid;
      logic [6:0]  low7;
      logic [11:0] r12;
      logic [19:0] r20;
      v = $urandom; mid = 13'($urandom); low7 = 7'($urandom);
      r12 = 12'($urandom); r20 = 20'($urandom);

      // I-type: imm[11:0] at [31:20]
      check("I", IMM_I, {v[11:0], r20}, {{52{v[11]}}, v[11:0]});
      // S-type: imm[11:5] at [31:25], imm[4:0] at [11:7]
      check("S", IMM_S, {v[11:5], mid, v[4:0], low7}, {{52{v[11]}}, v[11:0]});
      // B-type: imm[12|10:5] at [31:25], imm[4:1|11] at [11:7]; bit 0 is zero
      check("B", IMM_B, {v[12], v[10:5], mid, v[4:1], v[11], low7},
                        {{51{v[12]}}, v[12:1], 1'b0});
      // U-type: imm[31:12] at [31:12]
      check("U", IMM_U, {v[31:12], r12}, {{32{v[31]}}, v[31:12], 12'b0});
      // J-type: imm[20|10:1|11|19:12] at [31:12]; bit 0 is zero
      check("J", IMM_J, {v[20], v[10:1], v[11], v[19:12], r12},
                        {{43{v[20]}}, v[20:1], 1'b0});
    end

    if (errors != 0) $fatal(1, "tb_immgen FAILED with %0d errors", errors);
    $display("tb_immgen PASSED");
    $finish;
  end
endmodule
