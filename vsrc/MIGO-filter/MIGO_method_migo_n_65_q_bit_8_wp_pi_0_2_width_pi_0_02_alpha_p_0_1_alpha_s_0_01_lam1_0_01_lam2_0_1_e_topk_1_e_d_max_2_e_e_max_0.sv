(* keep_hierarchy = "yes" *)
module MIGO_method_migo_n_65_q_bit_8_wp_pi_0_2_width_pi_0_02_alpha_p_0_1_alpha_s_0_01_lam1_0_01_lam2_0_1_e_topk_1_e_d_max_2_e_e_max_0 #(
  parameter int N = 65,
  parameter int BX = 8,
  parameter int SHIFT = 8,
  parameter bit ROUND = 1,
  parameter int BY = 9
)(
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  input  logic signed [BX-1:0] x_in,
  output logic out_valid,
  output logic signed [BY-1:0] y_out
);

  // Delay Line
  logic signed [BX-1:0] shift_reg [0:N-1];
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      for(int i=0; i<N; i++) shift_reg[i] <= '0;
      out_valid <= 1'b0;
    end else if (in_valid) begin
      shift_reg[0] <= x_in;
      for(int i=1; i<N; i++) shift_reg[i] <= shift_reg[i-1];
      out_valid <= 1'b1;
    end else begin
      out_valid <= 1'b0;
    end
  end

  // Symmetric Pre-Adders
  logic signed [BX:0] x_symm [0:32];
  assign x_symm[0] = shift_reg[0] + shift_reg[64];
  assign x_symm[1] = shift_reg[1] + shift_reg[63];
  assign x_symm[2] = shift_reg[2] + shift_reg[62];
  assign x_symm[3] = shift_reg[3] + shift_reg[61];
  assign x_symm[4] = shift_reg[4] + shift_reg[60];
  assign x_symm[5] = shift_reg[5] + shift_reg[59];
  assign x_symm[6] = shift_reg[6] + shift_reg[58];
  assign x_symm[7] = shift_reg[7] + shift_reg[57];
  assign x_symm[8] = shift_reg[8] + shift_reg[56];
  assign x_symm[9] = shift_reg[9] + shift_reg[55];
  assign x_symm[10] = shift_reg[10] + shift_reg[54];
  assign x_symm[11] = shift_reg[11] + shift_reg[53];
  assign x_symm[12] = shift_reg[12] + shift_reg[52];
  assign x_symm[13] = shift_reg[13] + shift_reg[51];
  assign x_symm[14] = shift_reg[14] + shift_reg[50];
  assign x_symm[15] = shift_reg[15] + shift_reg[49];
  assign x_symm[16] = shift_reg[16] + shift_reg[48];
  assign x_symm[17] = shift_reg[17] + shift_reg[47];
  assign x_symm[18] = shift_reg[18] + shift_reg[46];
  assign x_symm[19] = shift_reg[19] + shift_reg[45];
  assign x_symm[20] = shift_reg[20] + shift_reg[44];
  assign x_symm[21] = shift_reg[21] + shift_reg[43];
  assign x_symm[22] = shift_reg[22] + shift_reg[42];
  assign x_symm[23] = shift_reg[23] + shift_reg[41];
  assign x_symm[24] = shift_reg[24] + shift_reg[40];
  assign x_symm[25] = shift_reg[25] + shift_reg[39];
  assign x_symm[26] = shift_reg[26] + shift_reg[38];
  assign x_symm[27] = shift_reg[27] + shift_reg[37];
  assign x_symm[28] = shift_reg[28] + shift_reg[36];
  assign x_symm[29] = shift_reg[29] + shift_reg[35];
  assign x_symm[30] = shift_reg[30] + shift_reg[34];
  assign x_symm[31] = shift_reg[31] + shift_reg[33];
  assign x_symm[32] = {shift_reg[32][BX-1], shift_reg[32]};

  // Group Pre-Sums
  logic signed [16:0] g0_pre_sum;
  assign g0_pre_sum = x_symm[3] + x_symm[5] + x_symm[13] - (x_symm[23] <<< 1) + (x_symm[12] <<< 2) - (x_symm[14] <<< 2) - (x_symm[15] <<< 2) - (x_symm[24] <<< 3) + (x_symm[28] <<< 3);
  logic signed [18:0] g0_mult;
  assign g0_mult = g0_pre_sum;
  logic signed [14:0] g1_pre_sum;
  assign g1_pre_sum = - x_symm[0] - x_symm[6] + x_symm[9] + x_symm[22] - x_symm[27] - (x_symm[7] <<< 1) + (x_symm[11] <<< 1) - (x_symm[16] <<< 1);
  logic signed [17:0] g1_mult;
  (* use_dsp = "no" *) assign g1_mult = g1_pre_sum * 3;
  logic signed [15:0] g2_pre_sum;
  assign g2_pre_sum = x_symm[19] + x_symm[20] - (x_symm[26] <<< 1) + (x_symm[30] <<< 3);
  logic signed [19:0] g2_mult;
  (* use_dsp = "no" *) assign g2_mult = g2_pre_sum * 5;
  logic signed [11:0] g3_pre_sum;
  assign g3_pre_sum = x_symm[2] + x_symm[21];
  logic signed [15:0] g3_mult;
  (* use_dsp = "no" *) assign g3_mult = g3_pre_sum * 7;
  logic signed [10:0] g4_pre_sum;
  assign g4_pre_sum = - x_symm[25];
  logic signed [15:0] g4_mult;
  (* use_dsp = "no" *) assign g4_mult = g4_pre_sum * 11;
  logic signed [10:0] g5_pre_sum;
  assign g5_pre_sum = x_symm[29];
  logic signed [16:0] g5_mult;
  (* use_dsp = "no" *) assign g5_mult = g5_pre_sum * 26;
  logic signed [10:0] g6_pre_sum;
  assign g6_pre_sum = x_symm[31];
  logic signed [17:0] g6_mult;
  (* use_dsp = "no" *) assign g6_mult = g6_pre_sum * 49;
  logic signed [10:0] g7_pre_sum;
  assign g7_pre_sum = x_symm[32];
  logic signed [17:0] g7_mult;
  (* use_dsp = "no" *) assign g7_mult = g7_pre_sum * 57;

  // Final Accumulation
  logic signed [16:0] final_sum;
  assign final_sum = g0_mult + g1_mult + g2_mult + g3_mult + g4_mult + g5_mult + g6_mult + g7_mult;
  always_comb begin
    if (ROUND && SHIFT > 0)
      y_out = (final_sum + (1 <<< (SHIFT-1))) >>> SHIFT;
    else
      y_out = final_sum >>> SHIFT;
  end
endmodule