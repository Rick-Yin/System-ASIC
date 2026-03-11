module dwconv1d_timeshift #(
  parameter int C = 6,
  parameter int K = 4
) (
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,

  input  logic signed [31:0] x_in [0:C-1],
  input  logic signed [31:0] w   [0:C-1][0:K-1],
  input  logic signed [31:0] b   [0:C-1],

  input  logic signed [31:0] exp_x,
  input  logic signed [31:0] w_exp,
  input  logic signed [31:0] b_exp,
  input  logic [7:0]         bits_x,

  output logic out_valid,
  output logic signed [31:0] xx_out [0:C-1]
);
  import quant_utils_pkg::*;

  logic signed [31:0] hist [0:C-1][0:K-1];

  integer c, i;
  logic signed [63:0] acc;
  logic signed [31:0] b_align;
  integer exp_acc;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      for (c = 0; c < C; c++) begin
        xx_out[c] <= '0;
        for (i = 0; i < K; i++) begin
          hist[c][i] <= '0;
        end
      end
    end else begin
      out_valid <= in_valid;
      if (in_valid) begin
        exp_acc = $signed(exp_x) + $signed(w_exp);

        for (c = 0; c < C; c++) begin
          acc = 64'sd0;
          for (i = 0; i < K; i++) begin
            acc = acc + (hist[c][i] * w[c][i]);
          end
          b_align = requant_pow2_signed($signed(b[c]), $signed(b_exp), exp_acc, 32);
          acc = acc + $signed(b_align);
          xx_out[c] <= requant_pow2_signed(acc, exp_acc, $signed(exp_x), bits_x);
        end

        for (c = 0; c < C; c++) begin
          for (i = 0; i < K-1; i++) begin
            hist[c][i] <= hist[c][i+1];
          end
          hist[c][K-1] <= x_in[c];
        end
      end
    end
  end

endmodule
