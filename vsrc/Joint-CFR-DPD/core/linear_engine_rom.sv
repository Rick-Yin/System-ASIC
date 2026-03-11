module linear_engine_rom #(
  parameter int MAX_IN_DIM = 18,
  parameter int MAX_OUT_DIM = 18
) (
  input  logic clk,
  input  logic rst_n,
  input  logic start,

  input  logic signed [31:0] x_vec [0:MAX_IN_DIM-1],
  input  logic [15:0] in_dim,
  input  logic [15:0] out_dim,
  input  logic        bias_en,

  input  logic signed [31:0] exp_x,
  input  logic signed [31:0] exp_out,
  input  logic signed [31:0] w_exp,
  input  logic signed [31:0] b_exp,
  input  logic [7:0]         out_bits,

  input  logic signed [31:0] w_data,
  input  logic signed [31:0] b_data,
  output logic [15:0]        w_addr,
  output logic [15:0]        b_addr,

  output logic busy,
  output logic done,
  output logic signed [MAX_OUT_DIM*32-1:0] y_bus
);
  import quant_utils_pkg::*;

  localparam int OUT_IDX_W = (MAX_OUT_DIM <= 1) ? 1 : $clog2(MAX_OUT_DIM);
  localparam int IN_IDX_W = (MAX_IN_DIM <= 1) ? 1 : $clog2(MAX_IN_DIM);

  logic processing;
  logic [OUT_IDX_W-1:0] out_idx;
  logic [IN_IDX_W-1:0] in_idx;
  logic signed [63:0] acc;
  logic signed [31:0] y_vec_r [0:MAX_OUT_DIM-1];

  integer i;
  integer exp_acc;
  logic signed [63:0] acc_sum;
  logic signed [31:0] b_align;

  always_comb begin
    w_addr = (out_idx * in_dim) + in_idx;
    b_addr = out_idx;
    busy = processing;
    y_bus = '0;
    for (i = 0; i < MAX_OUT_DIM; i++) begin
      y_bus[i*32 +: 32] = y_vec_r[i];
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      processing <= 1'b0;
      done <= 1'b0;
      out_idx <= '0;
      in_idx <= '0;
      acc <= '0;
      for (i = 0; i < MAX_OUT_DIM; i++) begin
        y_vec_r[i] <= '0;
      end
    end else begin
      done <= 1'b0;

      if (start && !processing) begin
        processing <= 1'b1;
        out_idx <= '0;
        in_idx <= '0;
        acc <= '0;
      end else if (processing) begin
        exp_acc = $signed(exp_x) + $signed(w_exp);
        acc_sum = acc + ($signed(x_vec[in_idx]) * $signed(w_data));

        if ((in_idx + 1'b1) >= in_dim) begin
          if (bias_en) begin
            b_align = requant_pow2_signed($signed(b_data), $signed(b_exp), exp_acc, 32);
            acc_sum = acc_sum + $signed(b_align);
          end

          for (i = 0; i < MAX_OUT_DIM; i++) begin
            if (i == out_idx) begin
              y_vec_r[i] <= requant_pow2_signed(acc_sum, exp_acc, $signed(exp_out), out_bits);
            end
          end
          acc <= '0;
          in_idx <= '0;

          if ((out_idx + 1'b1) >= out_dim) begin
            processing <= 1'b0;
            out_idx <= '0;
            done <= 1'b1;
          end else begin
            out_idx <= out_idx + 1'b1;
          end
        end else begin
          acc <= acc_sum;
          in_idx <= in_idx + 1'b1;
        end
      end
    end
  end

endmodule
