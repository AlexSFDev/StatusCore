// Register file test: x0 hardwired zero, bypass, full read-back.
module tb_regfile;
  logic        clk = 1'b0;
  logic        we = 1'b0;
  logic [4:0]  rs1_addr = '0, rs2_addr = '0, rd_addr = '0;
  logic [63:0] rd_data = '0, rs1_data, rs2_data;
  int          errors = 0;

  always #5 clk = ~clk;

  sc64_regfile dut (.clk, .we, .rs1_addr, .rs2_addr, .rd_addr, .rd_data, .rs1_data, .rs2_data);

  function automatic logic [63:0] pattern(input int i);
    return {32'hA5A50000 | 32'(i), 32'h5A5A0000 | 32'(i)};
  endfunction

  task automatic expect64(input string name, input logic [63:0] got, input logic [63:0] expd);
    if (got !== expd) begin
      errors++;
      $display("%s FAIL got=%h exp=%h", name, got, expd);
    end
  endtask

  initial begin
    // Same-cycle bypass
    @(negedge clk);
    we = 1; rd_addr = 5'd5; rd_data = 64'hDEAD_BEEF_0123_4567; rs1_addr = 5'd5; rs2_addr = 5'd5;
    #1;
    expect64("bypass rs1", rs1_data, 64'hDEAD_BEEF_0123_4567);
    expect64("bypass rs2", rs2_data, 64'hDEAD_BEEF_0123_4567);

    // Value persists after write
    @(negedge clk);
    we = 0; #1;
    expect64("persist rs1", rs1_data, 64'hDEAD_BEEF_0123_4567);

    // x0 ignores writes, including through the bypass path
    @(negedge clk);
    we = 1; rd_addr = 5'd0; rd_data = 64'hFFFF_FFFF_FFFF_FFFF; rs1_addr = 5'd0; rs2_addr = 5'd0;
    #1;
    expect64("x0 bypass rs1", rs1_data, 64'd0);
    expect64("x0 bypass rs2", rs2_data, 64'd0);
    @(negedge clk);
    we = 0; #1;
    expect64("x0 stored", rs1_data, 64'd0);

    // Write x1..x31, read all back on both ports
    for (int i = 1; i < 32; i++) begin
      @(negedge clk);
      we = 1; rd_addr = 5'(i); rd_data = pattern(i);
    end
    @(negedge clk);
    we = 0;
    for (int i = 1; i < 32; i++) begin
      rs1_addr = 5'(i); rs2_addr = 5'(32 - i);
      #1;
      expect64("rs1 readback", rs1_data, pattern(i));
      expect64("rs2 readback", rs2_data, pattern(32 - i));
    end

    if (errors != 0) $fatal(1, "tb_regfile FAILED with %0d errors", errors);
    $display("tb_regfile PASSED");
    $finish;
  end
endmodule
