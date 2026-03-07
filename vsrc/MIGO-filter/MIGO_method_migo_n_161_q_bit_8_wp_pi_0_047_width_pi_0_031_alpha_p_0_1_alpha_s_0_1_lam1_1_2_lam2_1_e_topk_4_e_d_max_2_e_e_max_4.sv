(* keep_hierarchy = "yes" *)
module MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4 #(
  parameter int N = 161,
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
  logic signed [BX:0] x_symm [0:80];
  assign x_symm[0] = shift_reg[0] + shift_reg[160];
  assign x_symm[1] = shift_reg[1] + shift_reg[159];
  assign x_symm[2] = shift_reg[2] + shift_reg[158];
  assign x_symm[3] = shift_reg[3] + shift_reg[157];
  assign x_symm[4] = shift_reg[4] + shift_reg[156];
  assign x_symm[5] = shift_reg[5] + shift_reg[155];
  assign x_symm[6] = shift_reg[6] + shift_reg[154];
  assign x_symm[7] = shift_reg[7] + shift_reg[153];
  assign x_symm[8] = shift_reg[8] + shift_reg[152];
  assign x_symm[9] = shift_reg[9] + shift_reg[151];
  assign x_symm[10] = shift_reg[10] + shift_reg[150];
  assign x_symm[11] = shift_reg[11] + shift_reg[149];
  assign x_symm[12] = shift_reg[12] + shift_reg[148];
  assign x_symm[13] = shift_reg[13] + shift_reg[147];
  assign x_symm[14] = shift_reg[14] + shift_reg[146];
  assign x_symm[15] = shift_reg[15] + shift_reg[145];
  assign x_symm[16] = shift_reg[16] + shift_reg[144];
  assign x_symm[17] = shift_reg[17] + shift_reg[143];
  assign x_symm[18] = shift_reg[18] + shift_reg[142];
  assign x_symm[19] = shift_reg[19] + shift_reg[141];
  assign x_symm[20] = shift_reg[20] + shift_reg[140];
  assign x_symm[21] = shift_reg[21] + shift_reg[139];
  assign x_symm[22] = shift_reg[22] + shift_reg[138];
  assign x_symm[23] = shift_reg[23] + shift_reg[137];
  assign x_symm[24] = shift_reg[24] + shift_reg[136];
  assign x_symm[25] = shift_reg[25] + shift_reg[135];
  assign x_symm[26] = shift_reg[26] + shift_reg[134];
  assign x_symm[27] = shift_reg[27] + shift_reg[133];
  assign x_symm[28] = shift_reg[28] + shift_reg[132];
  assign x_symm[29] = shift_reg[29] + shift_reg[131];
  assign x_symm[30] = shift_reg[30] + shift_reg[130];
  assign x_symm[31] = shift_reg[31] + shift_reg[129];
  assign x_symm[32] = shift_reg[32] + shift_reg[128];
  assign x_symm[33] = shift_reg[33] + shift_reg[127];
  assign x_symm[34] = shift_reg[34] + shift_reg[126];
  assign x_symm[35] = shift_reg[35] + shift_reg[125];
  assign x_symm[36] = shift_reg[36] + shift_reg[124];
  assign x_symm[37] = shift_reg[37] + shift_reg[123];
  assign x_symm[38] = shift_reg[38] + shift_reg[122];
  assign x_symm[39] = shift_reg[39] + shift_reg[121];
  assign x_symm[40] = shift_reg[40] + shift_reg[120];
  assign x_symm[41] = shift_reg[41] + shift_reg[119];
  assign x_symm[42] = shift_reg[42] + shift_reg[118];
  assign x_symm[43] = shift_reg[43] + shift_reg[117];
  assign x_symm[44] = shift_reg[44] + shift_reg[116];
  assign x_symm[45] = shift_reg[45] + shift_reg[115];
  assign x_symm[46] = shift_reg[46] + shift_reg[114];
  assign x_symm[47] = shift_reg[47] + shift_reg[113];
  assign x_symm[48] = shift_reg[48] + shift_reg[112];
  assign x_symm[49] = shift_reg[49] + shift_reg[111];
  assign x_symm[50] = shift_reg[50] + shift_reg[110];
  assign x_symm[51] = shift_reg[51] + shift_reg[109];
  assign x_symm[52] = shift_reg[52] + shift_reg[108];
  assign x_symm[53] = shift_reg[53] + shift_reg[107];
  assign x_symm[54] = shift_reg[54] + shift_reg[106];
  assign x_symm[55] = shift_reg[55] + shift_reg[105];
  assign x_symm[56] = shift_reg[56] + shift_reg[104];
  assign x_symm[57] = shift_reg[57] + shift_reg[103];
  assign x_symm[58] = shift_reg[58] + shift_reg[102];
  assign x_symm[59] = shift_reg[59] + shift_reg[101];
  assign x_symm[60] = shift_reg[60] + shift_reg[100];
  assign x_symm[61] = shift_reg[61] + shift_reg[99];
  assign x_symm[62] = shift_reg[62] + shift_reg[98];
  assign x_symm[63] = shift_reg[63] + shift_reg[97];
  assign x_symm[64] = shift_reg[64] + shift_reg[96];
  assign x_symm[65] = shift_reg[65] + shift_reg[95];
  assign x_symm[66] = shift_reg[66] + shift_reg[94];
  assign x_symm[67] = shift_reg[67] + shift_reg[93];
  assign x_symm[68] = shift_reg[68] + shift_reg[92];
  assign x_symm[69] = shift_reg[69] + shift_reg[91];
  assign x_symm[70] = shift_reg[70] + shift_reg[90];
  assign x_symm[71] = shift_reg[71] + shift_reg[89];
  assign x_symm[72] = shift_reg[72] + shift_reg[88];
  assign x_symm[73] = shift_reg[73] + shift_reg[87];
  assign x_symm[74] = shift_reg[74] + shift_reg[86];
  assign x_symm[75] = shift_reg[75] + shift_reg[85];
  assign x_symm[76] = shift_reg[76] + shift_reg[84];
  assign x_symm[77] = shift_reg[77] + shift_reg[83];
  assign x_symm[78] = shift_reg[78] + shift_reg[82];
  assign x_symm[79] = shift_reg[79] + shift_reg[81];
  assign x_symm[80] = {shift_reg[80][BX-1], shift_reg[80]};

  // Group Pre-Sums
  logic signed [17:0] g0_pre_sum;
  assign g0_pre_sum = - x_symm[52] - x_symm[56] - x_symm[59] - (x_symm[53] <<< 1) - (x_symm[54] <<< 1) - (x_symm[55] <<< 1) - (x_symm[57] <<< 1) - (x_symm[58] <<< 1) + (x_symm[68] <<< 1) + (x_symm[71] <<< 3) + (x_symm[77] <<< 4) + (x_symm[78] <<< 4);
  logic signed [19:0] g0_mult;
  assign g0_mult = g0_pre_sum;
  logic signed [10:0] g1_pre_sum;
  assign g1_pre_sum = x_symm[69];
  logic signed [14:0] g1_mult;
  (* use_dsp = "no" *) assign g1_mult = g1_pre_sum * 5;
  logic signed [10:0] g2_pre_sum;
  assign g2_pre_sum = x_symm[70];
  logic signed [14:0] g2_mult;
  (* use_dsp = "no" *) assign g2_mult = g2_pre_sum * 6;
  logic signed [10:0] g3_pre_sum;
  assign g3_pre_sum = x_symm[72];
  logic signed [15:0] g3_mult;
  (* use_dsp = "no" *) assign g3_mult = g3_pre_sum * 9;
  logic signed [11:0] g4_pre_sum;
  assign g4_pre_sum = x_symm[73] + x_symm[80];
  logic signed [16:0] g4_mult;
  (* use_dsp = "no" *) assign g4_mult = g4_pre_sum * 11;
  logic signed [10:0] g5_pre_sum;
  assign g5_pre_sum = x_symm[74];
  logic signed [15:0] g5_mult;
  (* use_dsp = "no" *) assign g5_mult = g5_pre_sum * 13;
  logic signed [10:0] g6_pre_sum;
  assign g6_pre_sum = x_symm[75];
  logic signed [15:0] g6_mult;
  (* use_dsp = "no" *) assign g6_mult = g6_pre_sum * 14;
  logic signed [10:0] g7_pre_sum;
  assign g7_pre_sum = x_symm[76];
  logic signed [15:0] g7_mult;
  (* use_dsp = "no" *) assign g7_mult = g7_pre_sum * 15;
  logic signed [10:0] g8_pre_sum;
  assign g8_pre_sum = x_symm[79];
  logic signed [16:0] g8_mult;
  (* use_dsp = "no" *) assign g8_mult = g8_pre_sum * 17;

  // Final Accumulation
  logic signed [16:0] final_sum;
  assign final_sum = g0_mult + g1_mult + g2_mult + g3_mult + g4_mult + g5_mult + g6_mult + g7_mult + g8_mult;
  always_comb begin
    if (ROUND && SHIFT > 0)
      y_out = (final_sum + (1 <<< (SHIFT-1))) >>> SHIFT;
    else
      y_out = final_sum >>> SHIFT;
  end
endmodule