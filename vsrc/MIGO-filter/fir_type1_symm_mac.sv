(* keep_hierarchy = "yes" *)
module fir_type1_symm_mac #(
  parameter int N = 33,
  parameter int BX = 8,
  parameter int BC = 8,
  parameter int SHIFT = 8,
  parameter bit ROUND = 1,

  parameter int signed H_HALF [0:(N+1)/2-1] = '{default:0},

  parameter int BY = (
    (((BX+1) + BC + $clog2((N+1)/2) + 3) > SHIFT) ?
      (((BX+1) + BC + $clog2((N+1)/2) + 3) - SHIFT) : 1
  )
)(
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  input  logic signed [BX-1:0] x_in,

  output logic out_valid,
  output logic signed [BY-1:0] y_out
);

  localparam int K = (N+1)/2;
  localparam int BPRE  = BX + 1;
  localparam int BPROD = BPRE + BC;
  localparam int BACC  = BPROD + $clog2(K) + 3;
  localparam int MAX_STAGES = (K <= 1) ? 0 : $clog2(K);

  logic signed [BX-1:0] x_d [0:N-1];
  logic signed [BX-1:0] x_n [0:N-1];

  logic signed [BACC-1:0] final_acc;
  logic signed [BACC-1:0] acc_biased;
  logic signed [BY-1:0]   y_comb;

  integer i;

  always_comb begin
    for (i = 0; i < N; i++) x_n[i] = x_d[i];
    if (in_valid) begin
      x_n[0] = x_in;
      for (i = 1; i < N; i++) x_n[i] = x_d[i-1];
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for (i = 0; i < N; i++) x_d[i] <= '0;
      out_valid <= 1'b0;
      y_out <= '0;
    end else begin
      for (i = 0; i < N; i++) x_d[i] <= x_n[i];
      out_valid <= in_valid;
      y_out <= y_comb;
    end
  end

  logic signed [BPRE-1:0]  xhat [0:K-1];
  logic signed [BPROD-1:0] prod [0:K-1];

  genvar k;
  generate
    for (k = 0; k < K; k++) begin : GEN_TAPS
      always_comb begin
        if (k == (N-1-k))
          xhat[k] = $signed({x_n[k][BX-1], x_n[k]});
        else
          xhat[k] = $signed({x_n[k][BX-1], x_n[k]}) +
                    $signed({x_n[N-1-k][BX-1], x_n[N-1-k]});
      end

      (* use_dsp = "no" *)
      always_comb begin
        prod[k] = $signed(xhat[k]) * $signed(H_HALF[k]);
      end
    end
  endgenerate

  logic signed [BACC-1:0] stage [0:MAX_STAGES][0:K-1];

  generate
    for (k = 0; k < K; k++) begin : GEN_STAGE0
      assign stage[0][k] = $signed(prod[k]);
    end
  endgenerate

  genvar s, j;
  generate
    for (s = 0; s < MAX_STAGES; s++) begin : GEN_REDUCE
      localparam int LEN_CUR = (K + (1<<s) - 1) >> s;
      localparam int LEN_NXT = (K + (1<<(s+1)) - 1) >> (s+1);

      for (j = 0; j < LEN_NXT; j++) begin : GEN_NODE
        if ((2*j + 1) < LEN_CUR) begin
          assign stage[s+1][j] = stage[s][2*j] + stage[s][2*j+1];
        end else begin
          assign stage[s+1][j] = stage[s][2*j];
        end
      end

      for (j = LEN_NXT; j < K; j++) begin : GEN_PAD
        assign stage[s+1][j] = '0;
      end
    end
  endgenerate



  always_comb begin
    final_acc = stage[MAX_STAGES][0];

    if (SHIFT == 0) begin
      acc_biased = final_acc;
    end else if (ROUND) begin
      if (final_acc >= 0)
        acc_biased = final_acc + $signed( (1 <<< (SHIFT-1)) );
      else
        acc_biased = final_acc - $signed( (1 <<< (SHIFT-1)) );
    end else begin
      acc_biased = final_acc;
    end

    if (SHIFT == 0)
      y_comb = $signed(acc_biased[BY-1:0]);
    else
      y_comb = $signed(acc_biased >>> SHIFT);
  end

endmodule
