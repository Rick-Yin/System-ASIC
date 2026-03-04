module rwkv_block_core #(
  parameter int C = 6
) (
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  input  logic signed [31:0] x_in [0:C-1],
  output logic out_valid,
  output logic signed [31:0] x_out [0:C-1]
);
  logic tm_valid;
  logic signed [31:0] tm_out [0:C-1];

  timemix_core #(.C(C)) u_timemix (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(in_valid),
    .x_in(x_in),
    .out_valid(tm_valid),
    .x_out(tm_out)
  );

  channelmix_core #(.C(C)) u_channelmix (
    .clk(clk),
    .rst_n(rst_n),
    .in_valid(tm_valid),
    .x_in(tm_out),
    .out_valid(out_valid),
    .x_out(x_out)
  );
endmodule
