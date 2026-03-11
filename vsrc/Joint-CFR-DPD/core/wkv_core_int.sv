module wkv_core_int #(
  parameter int C = 6,
  parameter int LUT_SIZE = 256,
  parameter int P_BITS = 16,
  parameter int A_BITS = 24,
  parameter int B_BITS = 24
) (
  input  logic clk,
  input  logic rst_n,
  input  logic clr_state,
  input  logic in_valid,

  input  logic signed [31:0] k_vec [0:C-1],
  input  logic signed [31:0] v_vec [0:C-1],
  input  logic signed [31:0] u_vec [0:C-1],
  input  logic signed [31:0] w_vec [0:C-1],

  input  logic signed [31:0] lut       [0:LUT_SIZE-1],
  input  logic signed [31:0] min_delta_i,
  input  logic signed [31:0] step_i,
  input  logic signed [31:0] e_frac,

  output logic out_valid,
  output logic signed [31:0] y_vec [0:C-1]
);
  import quant_utils_pkg::*;

  logic signed [31:0] pp_state [0:C-1];
  logic signed [A_BITS-1:0] aa_state [0:C-1];
  logic [B_BITS-1:0] bb_state [0:C-1];
  localparam logic signed [31:0] PP_INIT = - (32'sd1 <<< (P_BITS - 1));

  integer c;
  logic signed [31:0] ww, p, ww2, p2;
  logic signed [A_BITS-1:0] aa;
  logic [B_BITS-1:0] bb;
  logic signed [63:0] e1, e2, e1n, e2n;
  logic signed [63:0] t1, t2;
  logic signed [31:0] yi;
  logic [B_BITS-1:0] bb_safe;
  integer idx;

  function automatic logic signed [31:0] lut_lookup(input logic signed [31:0] delta_i);
    integer id;
    begin
      id = wkv_lut_lookup_idx(delta_i, min_delta_i, step_i, LUT_SIZE);
      lut_lookup = lut[id];
    end
  endfunction

  function automatic logic signed [31:0] div_rne_wkv(
    input logic signed [A_BITS-1:0] x,
    input logic [B_BITS-1:0] d
  );
    logic neg;
    logic [A_BITS-1:0] ax;
    logic [B_BITS:0] rem;
    logic [A_BITS-1:0] q;
    logic [B_BITS:0] two_r;
    logic inc;
    logic [A_BITS-1:0] q2;
    logic signed [31:0] q2_ext;
    integer bit_idx;
    begin
      if (d == '0) begin
        div_rne_wkv = 32'sd0;
      end else begin
        neg = (x < 0);
        if (neg) begin
          ax = $unsigned(-x);
        end else begin
          ax = $unsigned(x);
        end
        rem = '0;
        q = '0;
        for (bit_idx = A_BITS - 1; bit_idx >= 0; bit_idx = bit_idx - 1) begin
          rem = {rem[B_BITS-1:0], ax[bit_idx]};
          if (rem >= {1'b0, d}) begin
            rem = rem - {1'b0, d};
            q[bit_idx] = 1'b1;
          end
        end
        two_r = {rem[B_BITS-1:0], 1'b0};
        inc = (two_r > {1'b0, d}) || ((two_r == {1'b0, d}) && q[0]);
        q2 = q + (inc ? {{(A_BITS-1){1'b0}}, 1'b1} : {A_BITS{1'b0}});
        q2_ext = $signed({1'b0, q2});
        if (neg) begin
          div_rne_wkv = -q2_ext;
        end else begin
          div_rne_wkv = q2_ext;
        end
      end
    end
  endfunction

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      for (c = 0; c < C; c++) begin
        pp_state[c] <= PP_INIT;
        aa_state[c] <= '0;
        bb_state[c] <= '0;
        y_vec[c] <= 32'sd0;
      end
    end else begin
      out_valid <= in_valid;

      if (clr_state) begin
        for (c = 0; c < C; c++) begin
          pp_state[c] <= PP_INIT;
          aa_state[c] <= '0;
          bb_state[c] <= '0;
        end
      end else if (in_valid) begin
        for (c = 0; c < C; c++) begin
          ww = $signed(k_vec[c]) + $signed(u_vec[c]);
          p = (pp_state[c] > ww) ? pp_state[c] : ww;

          e1 = $signed(lut_lookup(pp_state[c] - p));
          e2 = $signed(lut_lookup(ww - p));

          aa = aa_state[c];
          bb = bb_state[c];

          t1 = rshift_rne64(aa * e1, $signed(e_frac));
          t2 = $signed(v_vec[c]) * e2;
          aa = sat_signed64(t1 + t2, A_BITS);

          t1 = rshift_rne64($signed({1'b0, bb}) * e1, $signed(e_frac));
          t2 = e2;
          bb = sat_unsigned64(t1 + t2, B_BITS);

          bb_safe = (bb == '0) ? {{(B_BITS-1){1'b0}}, 1'b1} : bb;
          yi = div_rne_wkv(aa, bb_safe);
          y_vec[c] <= yi;

          ww2 = $signed(pp_state[c]) + $signed(w_vec[c]);
          p2 = (ww2 > k_vec[c]) ? ww2 : k_vec[c];

          e1n = $signed(lut_lookup(ww2 - p2));
          e2n = $signed(lut_lookup(k_vec[c] - p2));

          t1 = rshift_rne64(aa * e1n, $signed(e_frac));
          t2 = $signed(v_vec[c]) * e2n;
          aa = sat_signed64(t1 + t2, A_BITS);

          t1 = rshift_rne64($signed({1'b0, bb}) * e1n, $signed(e_frac));
          t2 = e2n;
          bb = sat_unsigned64(t1 + t2, B_BITS);

          pp_state[c] <= p2;
          aa_state[c] <= aa;
          bb_state[c] <= bb;
        end
      end
    end
  end

endmodule
