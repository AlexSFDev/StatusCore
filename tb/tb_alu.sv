// Self-checking ALU testbench: directed corner cases + 200k random vectors
// against an independent reference model (32-bit datapath for *W ops).
module tb_alu;
  import sc64_pkg::*;

  alu_op_e     op;
  logic        word;
  logic [63:0] a, b, y;
  int          errors = 0;

  sc64_alu dut (.op, .word, .a, .b, .y);

  function automatic logic [63:0] ref_alu(input alu_op_e o, input logic w,
                                          input logic [63:0] x, input logic [63:0] z);
    logic [31:0] x32, z32, r32;
    logic [63:0] r;
    x32 = x[31:0]; z32 = z[31:0];
    r = '0; r32 = '0;
    if (w) begin
      case (o)
        ALU_ADD: r32 = x32 + z32;
        ALU_SUB: r32 = x32 - z32;
        ALU_SLL: r32 = x32 << z[4:0];
        ALU_SRL: r32 = x32 >> z[4:0];
        ALU_SRA: r32 = 32'($signed(x32) >>> z[4:0]);
        default: r32 = '0;
      endcase
      r = {{32{r32[31]}}, r32};
    end else begin
      case (o)
        ALU_ADD:  r = x + z;
        ALU_SUB:  r = x - z;
        ALU_SLL:  r = x << z[5:0];
        ALU_SLT:  r = ($signed(x) < $signed(z)) ? 64'd1 : 64'd0;
        ALU_SLTU: r = (x < z) ? 64'd1 : 64'd0;
        ALU_XOR:  r = x ^ z;
        ALU_SRL:  r = x >> z[5:0];
        ALU_SRA:  r = 64'($signed(x) >>> z[5:0]);
        ALU_OR:   r = x | z;
        ALU_AND:  r = x & z;
        default:  r = '0;
      endcase
    end
    return r;
  endfunction

  function automatic logic [63:0] pick();
    case ($urandom_range(9, 0))
      0:       return 64'd0;
      1:       return 64'd1;
      2:       return 64'hFFFF_FFFF_FFFF_FFFF;
      3:       return 64'h8000_0000_0000_0000;
      4:       return 64'h7FFF_FFFF_FFFF_FFFF;
      5:       return 64'h0000_0000_7FFF_FFFF;
      6:       return 64'h0000_0000_8000_0000;
      7:       return 64'hFFFF_FFFF_8000_0000;
      default: return {$urandom, $urandom};
    endcase
  endfunction

  task automatic apply(input alu_op_e o, input logic w,
                       input logic [63:0] x, input logic [63:0] z);
    op = o; word = w; a = x; b = z;
    #1;
  endtask

  // Compare against the reference model.
  task automatic check(input alu_op_e o, input logic w,
                       input logic [63:0] x, input logic [63:0] z);
    logic [63:0] expd;
    apply(o, w, x, z);
    expd = ref_alu(o, w, x, z);
    if (y !== expd) begin
      errors++;
      $display("MISMATCH op=%0d word=%0b a=%h b=%h got=%h exp=%h", o, w, x, z, y, expd);
    end
  endtask

  // Compare against a hand-computed constant.
  task automatic check_const(input string name, input alu_op_e o, input logic w,
                             input logic [63:0] x, input logic [63:0] z,
                             input logic [63:0] expd);
    apply(o, w, x, z);
    if (y !== expd) begin
      errors++;
      $display("DIRECTED FAIL %s: got=%h exp=%h", name, y, expd);
    end
  endtask

  initial begin
    // Directed cases (expected values worked out by hand from the RISC-V spec)
    check_const("ADDW overflow",  ALU_ADD, 1, 64'h0000_0000_7FFF_FFFF, 64'd1,
                64'hFFFF_FFFF_8000_0000);
    check_const("SUBW 0-1",       ALU_SUB, 1, 64'd0, 64'd1, 64'hFFFF_FFFF_FFFF_FFFF);
    check_const("SRAW sign",      ALU_SRA, 1, 64'h0000_0000_8000_0000, 64'd1,
                64'hFFFF_FFFF_C000_0000);
    check_const("SRLW ignores upper", ALU_SRL, 1, 64'hFFFF_FFFF_8000_0000, 64'd1,
                64'h0000_0000_4000_0000);
    check_const("SLLW to sign bit", ALU_SLL, 1, 64'd1, 64'd31, 64'hFFFF_FFFF_8000_0000);
    check_const("SLLW uses 5-bit shamt", ALU_SLL, 1, 64'd1, 64'd32, 64'd1);
    check_const("SLL 63",         ALU_SLL, 0, 64'd1, 64'd63, 64'h8000_0000_0000_0000);
    check_const("SRA 63",         ALU_SRA, 0, 64'h8000_0000_0000_0000, 64'd63,
                64'hFFFF_FFFF_FFFF_FFFF);
    check_const("SRL 63",         ALU_SRL, 0, 64'h8000_0000_0000_0000, 64'd63, 64'd1);
    check_const("SLT -1<1",       ALU_SLT,  0, 64'hFFFF_FFFF_FFFF_FFFF, 64'd1, 64'd1);
    check_const("SLTU max<1",     ALU_SLTU, 0, 64'hFFFF_FFFF_FFFF_FFFF, 64'd1, 64'd0);

    // Random + corner-biased vectors against the reference model
    for (int i = 0; i < 200000; i++) begin
      alu_op_e o;
      logic    w;
      o = alu_op_e'($urandom_range(9, 0));
      w = (o inside {ALU_ADD, ALU_SUB, ALU_SLL, ALU_SRL, ALU_SRA}) ? 1'($urandom_range(1, 0)) : 1'b0;
      check(o, w, pick(), pick());
    end

    if (errors != 0) $fatal(1, "tb_alu FAILED with %0d errors", errors);
    $display("tb_alu PASSED");
    $finish;
  end
endmodule
