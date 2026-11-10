// StatusCore SC64 - 32 x 64-bit register file, 2 read / 1 write, x0 == 0.
// Write-through bypass: a same-cycle read of the register being written
// returns the new value. (Replace the storage with a macro for tapeout.)
module sc64_regfile (
  input  logic        clk,
  input  logic        we,
  input  logic [4:0]  rs1_addr,
  input  logic [4:0]  rs2_addr,
  input  logic [4:0]  rd_addr,
  input  logic [63:0] rd_data,
  output logic [63:0] rs1_data,
  output logic [63:0] rs2_data
);

  logic [63:0] regs [32];

  always_ff @(posedge clk) begin
    if (we && (rd_addr != 5'd0)) regs[rd_addr] <= rd_data;
  end

  assign rs1_data = (rs1_addr == 5'd0)                ? 64'd0   :
                    (we && (rd_addr == rs1_addr))     ? rd_data :
                                                        regs[rs1_addr];
  assign rs2_data = (rs2_addr == 5'd0)                ? 64'd0   :
                    (we && (rd_addr == rs2_addr))     ? rd_data :
                                                        regs[rs2_addr];

endmodule
