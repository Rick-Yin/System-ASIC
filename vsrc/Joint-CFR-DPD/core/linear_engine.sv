module linear_engine #(
  parameter int IN_DIM = 6,
  parameter int OUT_DIM = 6,
  parameter int LANES = 2
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  input  logic signed [31:0] x_vec [0:IN_DIM-1],
  input  logic signed [31:0] w_mat [0:OUT_DIM-1][0:IN_DIM-1],
  input  logic signed [31:0] b_vec [0:OUT_DIM-1],
  input  logic               bias_en,

  input  logic signed [31:0] exp_x,
  input  logic signed [31:0] exp_out,
  input  logic signed [31:0] w_exp,
  input  logic signed [31:0] b_exp,
  input  logic [7:0]         out_bits,

  output logic busy,
  output logic done,
  output logic signed [31:0] y_vec [0:OUT_DIM-1]
);
  import quant_utils_pkg::*;

  logic [$clog2(OUT_DIM+1)-1:0] out_idx;
  logic processing;

  integer lane, i;
  logic signed [63:0] acc;
  logic signed [31:0] y_q;
  logic signed [31:0] b_align;
  integer idx;
  integer exp_acc;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      processing <= 1'b0;
      busy <= 1'b0;
      done <= 1'b0;
      out_idx <= '0;
      for (i = 0; i < OUT_DIM; i++) begin
        y_vec[i] <= '0;
      end
    end else begin
      done <= 1'b0;

      if (start && !processing) begin
        processing <= 1'b1;
        busy <= 1'b1;
        out_idx <= '0;
      end else if (processing) begin
        exp_acc = $signed(exp_x) + $signed(w_exp);

        for (lane = 0; lane < LANES; lane++) begin
          idx = out_idx + lane;
          if (idx < OUT_DIM) begin
            acc = 64'sd0;
            for (i = 0; i < IN_DIM; i++) begin
              acc = acc + $signed(x_vec[i]) * $signed(w_mat[idx][i]);
            end
            if (bias_en) begin
              b_align = requant_pow2_signed($signed(b_vec[idx]), $signed(b_exp), exp_acc, 32);
              acc = acc + $signed(b_align);
            end
            y_q = requant_pow2_signed(acc, exp_acc, $signed(exp_out), out_bits);
            y_vec[idx] <= y_q;
          end
        end

        if ((out_idx + LANES) >= OUT_DIM) begin
          processing <= 1'b0;
          busy <= 1'b0;
          done <= 1'b1;
          out_idx <= '0;
        end else begin
          out_idx <= out_idx + LANES;
        end
      end
    end
  end

endmodule
