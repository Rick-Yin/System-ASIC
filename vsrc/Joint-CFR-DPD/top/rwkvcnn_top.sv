module rwkvcnn_top (
  input  logic clk,
  input  logic rst_n,
  input  logic in_valid,
  output logic in_ready,
  input  logic signed [rwkvcnn_pkg::IN_DIM*32-1:0] in_data,
  output logic out_valid,
  input  logic out_ready,
  output logic signed [rwkvcnn_pkg::OUT_DIM*32-1:0] out_data
);
  import rwkvcnn_pkg::*;
  import quant_utils_pkg::*;

  typedef enum logic [2:0] {
    S_IDLE     = 3'd0,
    S_IP       = 3'd1,
    S_ATT_PRE  = 3'd2,
    S_ATT_POST = 3'd3,
    S_FFN_PRE  = 3'd4,
    S_FFN_POST = 3'd5,
    S_OP       = 3'd6,
    S_OUT      = 3'd7
  } state_t;

  state_t state;
  localparam int KERNEL_HEAD_W = (KERNEL_SIZE <= 1) ? 1 : $clog2(KERNEL_SIZE);
  logic [$clog2(LAYER_NUM)-1:0] blk_idx;

  logic signed [31:0] in_vec [0:IN_DIM-1];
  logic signed [31:0] work_vec [0:MODEL_DIM-1];
  logic signed [31:0] out_vec [0:OUT_DIM-1];

  logic signed [31:0] att_hist [0:LAYER_NUM-1][0:MODEL_DIM-1][0:KERNEL_SIZE-1];
  logic signed [31:0] ffn_hist [0:LAYER_NUM-1][0:MODEL_DIM-1][0:KERNEL_SIZE-1];
  logic [KERNEL_HEAD_W-1:0] att_hist_head [0:LAYER_NUM-1][0:MODEL_DIM-1];
  logic [KERNEL_HEAD_W-1:0] ffn_hist_head [0:LAYER_NUM-1][0:MODEL_DIM-1];

  logic signed [31:0] pp_state [0:LAYER_NUM-1][0:MODEL_DIM-1];
  logic signed [63:0] aa_state [0:LAYER_NUM-1][0:MODEL_DIM-1];
  logic signed [63:0] bb_state [0:LAYER_NUM-1][0:MODEL_DIM-1];

  logic out_valid_r;
  integer oi;
  localparam logic signed [31:0] PP_INIT = - (32'sd1 <<< (P_BITS - 1));

  assign in_ready = (state == S_IDLE);
  assign out_valid = out_valid_r;

  always_comb begin
    out_data = '0;
    for (oi = 0; oi < OUT_DIM; oi++) begin
      out_data[oi*32 +: 32] = out_vec[oi];
    end
  end

  function automatic logic signed [31:0] in_word(input logic signed [IN_DIM*32-1:0] bus, input int idx);
    begin
      in_word = bus[idx*32 +: 32];
    end
  endfunction

  function automatic logic signed [31:0] att_ts_w(input int blk, input int c, input int k);
    int idx;
    begin
      idx = c*KERNEL_SIZE + k;
      if (blk == 0) begin
        att_ts_w = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W, idx);
      end else begin
        att_ts_w = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_ts_b(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_ts_b = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B, c);
      end else begin
        att_ts_b = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B, c);
      end
    end
  endfunction

  function automatic int att_ts_w_exp(input int blk);
    begin
      if (blk == 0) begin
        att_ts_w_exp = BLOCKS_0_ATT_TIME_SHIFT_W_EXP;
      end else begin
        att_ts_w_exp = BLOCKS_1_ATT_TIME_SHIFT_W_EXP;
      end
    end
  endfunction

  function automatic int att_ts_b_exp(input int blk);
    begin
      if (blk == 0) begin
        att_ts_b_exp = BLOCKS_0_ATT_TIME_SHIFT_B_EXP;
      end else begin
        att_ts_b_exp = BLOCKS_1_ATT_TIME_SHIFT_B_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] att_tm_k(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_tm_k = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_MIX_K, c);
      end else begin
        att_tm_k = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_MIX_K, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_tm_v(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_tm_v = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_MIX_V, c);
      end else begin
        att_tm_v = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_MIX_V, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_tm_r(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_tm_r = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_MIX_R, c);
      end else begin
        att_tm_r = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_MIX_R, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_one_tm(input int blk);
    begin
      if (blk == 0) begin
        att_one_tm = rom_read(ROM_ID_BLOCKS_0_ATT_ONE_TM, 0);
      end else begin
        att_one_tm = rom_read(ROM_ID_BLOCKS_1_ATT_ONE_TM, 0);
      end
    end
  endfunction

  function automatic int att_tm_exp(input int blk);
    begin
      if (blk == 0) begin
        att_tm_exp = BLOCKS_0_ATT_TIME_MIX_K_EXP;
      end else begin
        att_tm_exp = BLOCKS_1_ATT_TIME_MIX_K_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] att_key_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        att_key_w = rom_read(ROM_ID_BLOCKS_0_ATT_KEY_W, idx);
      end else begin
        att_key_w = rom_read(ROM_ID_BLOCKS_1_ATT_KEY_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_value_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        att_value_w = rom_read(ROM_ID_BLOCKS_0_ATT_VALUE_W, idx);
      end else begin
        att_value_w = rom_read(ROM_ID_BLOCKS_1_ATT_VALUE_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_receptance_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        att_receptance_w = rom_read(ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W, idx);
      end else begin
        att_receptance_w = rom_read(ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_output_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        att_output_w = rom_read(ROM_ID_BLOCKS_0_ATT_OUTPUT_W, idx);
      end else begin
        att_output_w = rom_read(ROM_ID_BLOCKS_1_ATT_OUTPUT_W, idx);
      end
    end
  endfunction

  function automatic int att_key_w_exp(input int blk);
    begin
      if (blk == 0) begin
        att_key_w_exp = BLOCKS_0_ATT_KEY_W_EXP;
      end else begin
        att_key_w_exp = BLOCKS_1_ATT_KEY_W_EXP;
      end
    end
  endfunction

  function automatic int att_value_w_exp(input int blk);
    begin
      if (blk == 0) begin
        att_value_w_exp = BLOCKS_0_ATT_VALUE_W_EXP;
      end else begin
        att_value_w_exp = BLOCKS_1_ATT_VALUE_W_EXP;
      end
    end
  endfunction

  function automatic int att_receptance_w_exp(input int blk);
    begin
      if (blk == 0) begin
        att_receptance_w_exp = BLOCKS_0_ATT_RECEPTANCE_W_EXP;
      end else begin
        att_receptance_w_exp = BLOCKS_1_ATT_RECEPTANCE_W_EXP;
      end
    end
  endfunction

  function automatic int att_output_w_exp(input int blk);
    begin
      if (blk == 0) begin
        att_output_w_exp = BLOCKS_0_ATT_OUTPUT_W_EXP;
      end else begin
        att_output_w_exp = BLOCKS_1_ATT_OUTPUT_W_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] att_time_first(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_time_first = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_FIRST, c);
      end else begin
        att_time_first = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_FIRST, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] att_time_decay(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_time_decay = rom_read(ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP, c);
      end else begin
        att_time_decay = rom_read(ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_ts_w(input int blk, input int c, input int k);
    int idx;
    begin
      idx = c*KERNEL_SIZE + k;
      if (blk == 0) begin
        ffn_ts_w = rom_read(ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W, idx);
      end else begin
        ffn_ts_w = rom_read(ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_ts_b(input int blk, input int c);
    begin
      if (blk == 0) begin
        ffn_ts_b = rom_read(ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B, c);
      end else begin
        ffn_ts_b = rom_read(ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B, c);
      end
    end
  endfunction

  function automatic int ffn_ts_w_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_ts_w_exp = BLOCKS_0_FFN_TIME_SHIFT_W_EXP;
      end else begin
        ffn_ts_w_exp = BLOCKS_1_FFN_TIME_SHIFT_W_EXP;
      end
    end
  endfunction

  function automatic int ffn_ts_b_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_ts_b_exp = BLOCKS_0_FFN_TIME_SHIFT_B_EXP;
      end else begin
        ffn_ts_b_exp = BLOCKS_1_FFN_TIME_SHIFT_B_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_tm_k(input int blk, input int c);
    begin
      if (blk == 0) begin
        ffn_tm_k = rom_read(ROM_ID_BLOCKS_0_FFN_TIME_MIX_K, c);
      end else begin
        ffn_tm_k = rom_read(ROM_ID_BLOCKS_1_FFN_TIME_MIX_K, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_tm_r(input int blk, input int c);
    begin
      if (blk == 0) begin
        ffn_tm_r = rom_read(ROM_ID_BLOCKS_0_FFN_TIME_MIX_R, c);
      end else begin
        ffn_tm_r = rom_read(ROM_ID_BLOCKS_1_FFN_TIME_MIX_R, c);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_one_tm(input int blk);
    begin
      if (blk == 0) begin
        ffn_one_tm = rom_read(ROM_ID_BLOCKS_0_FFN_ONE_TM, 0);
      end else begin
        ffn_one_tm = rom_read(ROM_ID_BLOCKS_1_FFN_ONE_TM, 0);
      end
    end
  endfunction

  function automatic int ffn_tm_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_tm_exp = BLOCKS_0_FFN_TIME_MIX_K_EXP;
      end else begin
        ffn_tm_exp = BLOCKS_1_FFN_TIME_MIX_K_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_key_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        ffn_key_w = rom_read(ROM_ID_BLOCKS_0_FFN_KEY_W, idx);
      end else begin
        ffn_key_w = rom_read(ROM_ID_BLOCKS_1_FFN_KEY_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_receptance_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*MODEL_DIM + i;
      if (blk == 0) begin
        ffn_receptance_w = rom_read(ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W, idx);
      end else begin
        ffn_receptance_w = rom_read(ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W, idx);
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_value_w(input int blk, input int o, input int i);
    int idx;
    begin
      idx = o*HIDDEN_SZ + i;
      if (blk == 0) begin
        ffn_value_w = rom_read(ROM_ID_BLOCKS_0_FFN_VALUE_W, idx);
      end else begin
        ffn_value_w = rom_read(ROM_ID_BLOCKS_1_FFN_VALUE_W, idx);
      end
    end
  endfunction

  function automatic int ffn_key_w_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_key_w_exp = BLOCKS_0_FFN_KEY_W_EXP;
      end else begin
        ffn_key_w_exp = BLOCKS_1_FFN_KEY_W_EXP;
      end
    end
  endfunction

  function automatic int ffn_receptance_w_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_receptance_w_exp = BLOCKS_0_FFN_RECEPTANCE_W_EXP;
      end else begin
        ffn_receptance_w_exp = BLOCKS_1_FFN_RECEPTANCE_W_EXP;
      end
    end
  endfunction

  function automatic int ffn_value_w_exp(input int blk);
    begin
      if (blk == 0) begin
        ffn_value_w_exp = BLOCKS_0_FFN_VALUE_W_EXP;
      end else begin
        ffn_value_w_exp = BLOCKS_1_FFN_VALUE_W_EXP;
      end
    end
  endfunction

  function automatic logic signed [31:0] wkv_lut_lookup(input logic signed [31:0] delta_i);
    integer idx;
    begin
      idx = wkv_lut_lookup_idx(
        delta_i,
        rom_read(ROM_ID_WKV_MIN_DELTA_I, 0),
        rom_read(ROM_ID_WKV_STEP_I, 0),
        WKV_LUT_NUMEL
      );
      wkv_lut_lookup = rom_read(ROM_ID_WKV_LUT, idx);
    end
  endfunction

  integer i, j, k, c, o;
  logic signed [31:0] x_base [0:MODEL_DIM-1];
  logic signed [31:0] xx [0:MODEL_DIM-1];
  logic signed [31:0] xk [0:MODEL_DIM-1];
  logic signed [31:0] xv [0:MODEL_DIM-1];
  logic signed [31:0] xr [0:MODEL_DIM-1];
  logic signed [31:0] k_att [0:MODEL_DIM-1];
  logic signed [31:0] v_att [0:MODEL_DIM-1];
  logic signed [31:0] r_att [0:MODEL_DIM-1];
  logic signed [31:0] gate_att [0:MODEL_DIM-1];
  logic signed [31:0] y_wkv [0:MODEL_DIM-1];
  logic signed [31:0] mul_att [0:MODEL_DIM-1];
  logic signed [31:0] att_out [0:MODEL_DIM-1];

  logic signed [31:0] k_ffn [0:HIDDEN_SZ-1];
  logic signed [31:0] k_sq [0:HIDDEN_SZ-1];
  logic signed [31:0] kv_ffn [0:MODEL_DIM-1];
  logic signed [31:0] gate_in_ffn [0:MODEL_DIM-1];
  logic signed [31:0] gate_ffn [0:MODEL_DIM-1];
  logic signed [31:0] ffn_out [0:MODEL_DIM-1];

  logic signed [63:0] acc;
  logic signed [63:0] prod;
  logic signed [63:0] aa;
  logic signed [63:0] bb;
  logic signed [63:0] e1;
  logic signed [63:0] e2;
  logic signed [63:0] e1n;
  logic signed [63:0] e2n;
  logic signed [63:0] t1;
  logic signed [63:0] t2;
  logic signed [63:0] yi;
  logic signed [63:0] bb_safe;

  logic signed [31:0] ww;
  logic signed [31:0] p;
  logic signed [31:0] ww2;
  logic signed [31:0] p2;

  logic signed [31:0] b_aligned;
  logic signed [31:0] one_tm;
  logic signed [31:0] tmv;
  logic signed [31:0] wd;
  logic signed [31:0] uu;

  integer exp_acc;
  integer hist_head_idx;
  integer hist_rd_idx;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE;
      blk_idx <= '0;
      out_valid_r <= 1'b0;
      for (i = 0; i < IN_DIM; i++) begin
        in_vec[i] <= '0;
      end
      for (i = 0; i < OUT_DIM; i++) begin
        out_vec[i] <= '0;
      end
      for (i = 0; i < MODEL_DIM; i++) begin
        work_vec[i] <= '0;
      end
      for (j = 0; j < LAYER_NUM; j++) begin
        for (i = 0; i < MODEL_DIM; i++) begin
          pp_state[j][i] <= PP_INIT;
          aa_state[j][i] <= 64'sd0;
          bb_state[j][i] <= 64'sd0;
          att_hist_head[j][i] <= '0;
          ffn_hist_head[j][i] <= '0;
          for (k = 0; k < KERNEL_SIZE; k++) begin
            att_hist[j][i][k] <= '0;
            ffn_hist[j][i][k] <= '0;
          end
        end
      end
    end else begin
      case (state)
        S_IDLE: begin
          out_valid_r <= 1'b0;
          if (in_valid && in_ready) begin
            for (i = 0; i < IN_DIM; i++) begin
              in_vec[i] <= in_word(in_data, i);
            end
            state <= S_IP;
          end
        end

        S_IP: begin
          for (o = 0; o < MODEL_DIM; o++) begin
            acc = 64'sd0;
            for (i = 0; i < IN_DIM; i++) begin
              acc = acc + $signed(in_vec[i]) * $signed(rom_read(ROM_ID_INPUT_PROJ_W, o*IN_DIM + i));
            end
            exp_acc = IO_EXP_IN + INPUT_PROJ_W_EXP;
            b_aligned = requant_pow2_signed($signed(rom_read(ROM_ID_INPUT_PROJ_B, o)), INPUT_PROJ_B_EXP, exp_acc, 32);
            acc = acc + $signed(b_aligned);
            work_vec[o] <= requant_pow2_signed(acc, exp_acc, RES_EXP, RES_BITS);
          end
          blk_idx <= '0;
          state <= S_ATT_PRE;
        end

        S_ATT_PRE: begin
          for (c = 0; c < MODEL_DIM; c++) begin
            x_base[c] = work_vec[c];
          end

          for (c = 0; c < MODEL_DIM; c++) begin
            acc = 64'sd0;
            hist_head_idx = att_hist_head[blk_idx][c];
            for (k = 0; k < KERNEL_SIZE; k++) begin
              hist_rd_idx = hist_head_idx + k;
              if (hist_rd_idx >= KERNEL_SIZE) begin
                hist_rd_idx = hist_rd_idx - KERNEL_SIZE;
              end
              acc = acc + $signed(att_hist[blk_idx][c][hist_rd_idx]) * $signed(att_ts_w(blk_idx, c, k));
            end
            exp_acc = RES_EXP + att_ts_w_exp(blk_idx);
            b_aligned = requant_pow2_signed($signed(att_ts_b(blk_idx, c)), att_ts_b_exp(blk_idx), exp_acc, 32);
            acc = acc + $signed(b_aligned);
            xx[c] = requant_pow2_signed(acc, exp_acc, RES_EXP, RES_BITS);
          end

          one_tm = att_one_tm(blk_idx);
          for (c = 0; c < MODEL_DIM; c++) begin
            tmv = att_tm_k(blk_idx, c);
            prod = $signed(work_vec[c]) * $signed(tmv) + $signed(xx[c]) * $signed(one_tm - tmv);
            xk[c] = sat_signed32(rshift_rne64(prod, -att_tm_exp(blk_idx)), RES_BITS);

            tmv = att_tm_v(blk_idx, c);
            prod = $signed(work_vec[c]) * $signed(tmv) + $signed(xx[c]) * $signed(one_tm - tmv);
            xv[c] = sat_signed32(rshift_rne64(prod, -att_tm_exp(blk_idx)), RES_BITS);

            tmv = att_tm_r(blk_idx, c);
            prod = $signed(work_vec[c]) * $signed(tmv) + $signed(xx[c]) * $signed(one_tm - tmv);
            xr[c] = sat_signed32(rshift_rne64(prod, -att_tm_exp(blk_idx)), RES_BITS);
          end

          for (o = 0; o < MODEL_DIM; o++) begin
            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(xk[i]) * $signed(att_key_w(blk_idx, o, i));
            end
            k_att[o] = requant_pow2_signed(acc, RES_EXP + att_key_w_exp(blk_idx), rom_read(ROM_ID_WKV_LOG_EXP, 0), K_BITS);

            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(xv[i]) * $signed(att_value_w(blk_idx, o, i));
            end
            v_att[o] = requant_pow2_signed(acc, RES_EXP + att_value_w_exp(blk_idx), EXP_V, V_BITS);

            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(xr[i]) * $signed(att_receptance_w(blk_idx, o, i));
            end
            r_att[o] = requant_pow2_signed(acc, RES_EXP + att_receptance_w_exp(blk_idx), EXP_R, R_BITS);
            gate_att[o] = hardsigmoid_int_default(r_att[o], EXP_R, GATE_BITS);
          end

          state <= S_ATT_POST;
        end

        S_ATT_POST: begin
          for (c = 0; c < MODEL_DIM; c++) begin
            uu = att_time_first(blk_idx, c);
            wd = att_time_decay(blk_idx, c);

            ww = $signed(k_att[c]) + $signed(uu);
            p = ($signed(pp_state[blk_idx][c]) > $signed(ww)) ? pp_state[blk_idx][c] : ww;

            e1 = $signed(wkv_lut_lookup(pp_state[blk_idx][c] - p));
            e2 = $signed(wkv_lut_lookup(ww - p));

            aa = aa_state[blk_idx][c];
            bb = bb_state[blk_idx][c];

            t1 = rshift_rne64(aa * e1, rom_read(ROM_ID_WKV_E_FRAC, 0));
            t2 = $signed(v_att[c]) * e2;
            aa = sat_signed64(t1 + t2, A_BITS);

            t1 = rshift_rne64(bb * e1, rom_read(ROM_ID_WKV_E_FRAC, 0));
            t2 = e2;
            bb = $signed(sat_unsigned64(t1 + t2, B_BITS));

            bb_safe = (bb <= 0) ? 64'sd1 : bb;
            yi = div_rne64(aa, bb_safe);
            y_wkv[c] = yi[31:0];

            ww2 = $signed(pp_state[blk_idx][c]) + $signed(wd);
            p2 = ($signed(ww2) > $signed(k_att[c])) ? ww2 : k_att[c];

            e1n = $signed(wkv_lut_lookup(ww2 - p2));
            e2n = $signed(wkv_lut_lookup(k_att[c] - p2));

            t1 = rshift_rne64(aa * e1n, rom_read(ROM_ID_WKV_E_FRAC, 0));
            t2 = $signed(v_att[c]) * e2n;
            aa = sat_signed64(t1 + t2, A_BITS);

            t1 = rshift_rne64(bb * e1n, rom_read(ROM_ID_WKV_E_FRAC, 0));
            t2 = e2n;
            bb = $signed(sat_unsigned64(t1 + t2, B_BITS));

            pp_state[blk_idx][c] <= p2;
            aa_state[blk_idx][c] <= aa;
            bb_state[blk_idx][c] <= bb;
          end

          for (c = 0; c < MODEL_DIM; c++) begin
            prod = $signed(y_wkv[c]) * $signed(gate_att[c]);
            mul_att[c] = requant_pow2_signed(prod, (EXP_V - GATE_BITS), EXP_MUL, MUL_BITS);
          end

          for (o = 0; o < MODEL_DIM; o++) begin
            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(mul_att[i]) * $signed(att_output_w(blk_idx, o, i));
            end
            att_out[o] = requant_pow2_signed(acc, EXP_MUL + att_output_w_exp(blk_idx), RES_EXP, RES_BITS);
            work_vec[o] <= sat_signed32($signed(work_vec[o]) + $signed(att_out[o]), RES_BITS);
          end

          for (c = 0; c < MODEL_DIM; c++) begin
            hist_head_idx = att_hist_head[blk_idx][c];
            att_hist[blk_idx][c][hist_head_idx] <= x_base[c];
            if (KERNEL_SIZE > 1) begin
              if (hist_head_idx == (KERNEL_SIZE - 1)) begin
                att_hist_head[blk_idx][c] <= '0;
              end else begin
                att_hist_head[blk_idx][c] <= hist_head_idx + 1;
              end
            end
          end

          state <= S_FFN_PRE;
        end

        S_FFN_PRE: begin
          for (c = 0; c < MODEL_DIM; c++) begin
            x_base[c] = work_vec[c];
          end

          for (c = 0; c < MODEL_DIM; c++) begin
            acc = 64'sd0;
            hist_head_idx = ffn_hist_head[blk_idx][c];
            for (k = 0; k < KERNEL_SIZE; k++) begin
              hist_rd_idx = hist_head_idx + k;
              if (hist_rd_idx >= KERNEL_SIZE) begin
                hist_rd_idx = hist_rd_idx - KERNEL_SIZE;
              end
              acc = acc + $signed(ffn_hist[blk_idx][c][hist_rd_idx]) * $signed(ffn_ts_w(blk_idx, c, k));
            end
            exp_acc = RES_EXP + ffn_ts_w_exp(blk_idx);
            b_aligned = requant_pow2_signed($signed(ffn_ts_b(blk_idx, c)), ffn_ts_b_exp(blk_idx), exp_acc, 32);
            acc = acc + $signed(b_aligned);
            xx[c] = requant_pow2_signed(acc, exp_acc, RES_EXP, RES_BITS);
          end

          one_tm = ffn_one_tm(blk_idx);
          for (c = 0; c < MODEL_DIM; c++) begin
            tmv = ffn_tm_k(blk_idx, c);
            prod = $signed(work_vec[c]) * $signed(tmv) + $signed(xx[c]) * $signed(one_tm - tmv);
            xk[c] = sat_signed32(rshift_rne64(prod, -ffn_tm_exp(blk_idx)), RES_BITS);

            tmv = ffn_tm_r(blk_idx, c);
            prod = $signed(work_vec[c]) * $signed(tmv) + $signed(xx[c]) * $signed(one_tm - tmv);
            xr[c] = sat_signed32(rshift_rne64(prod, -ffn_tm_exp(blk_idx)), RES_BITS);
          end

          for (o = 0; o < HIDDEN_SZ; o++) begin
            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(xk[i]) * $signed(ffn_key_w(blk_idx, o, i));
            end
            k_ffn[o] = requant_pow2_signed(acc, RES_EXP + ffn_key_w_exp(blk_idx), RES_EXP, RES_BITS);

            if (k_ffn[o] < 0) begin
              k_ffn[o] = 32'sd0;
            end else if ($signed(k_ffn[o]) > qmax_signed64(RES_BITS)) begin
              k_ffn[o] = qmax_signed64(RES_BITS);
            end

            prod = $signed(k_ffn[o]) * $signed(k_ffn[o]);
            k_sq[o] = requant_pow2_signed(prod, RES_EXP + RES_EXP, RES_EXP, RES_BITS);
          end

          state <= S_FFN_POST;
        end

        S_FFN_POST: begin
          for (o = 0; o < MODEL_DIM; o++) begin
            acc = 64'sd0;
            for (i = 0; i < HIDDEN_SZ; i++) begin
              acc = acc + $signed(k_sq[i]) * $signed(ffn_value_w(blk_idx, o, i));
            end
            kv_ffn[o] = requant_pow2_signed(acc, RES_EXP + ffn_value_w_exp(blk_idx), RES_EXP, RES_BITS);

            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(xr[i]) * $signed(ffn_receptance_w(blk_idx, o, i));
            end
            gate_in_ffn[o] = requant_pow2_signed(acc, RES_EXP + ffn_receptance_w_exp(blk_idx), RES_EXP, RES_BITS);
            gate_ffn[o] = hardsigmoid_int_default(gate_in_ffn[o], RES_EXP, GATE_BITS);

            prod = $signed(kv_ffn[o]) * $signed(gate_ffn[o]);
            ffn_out[o] = requant_pow2_signed(prod, RES_EXP - GATE_BITS, RES_EXP, RES_BITS);
            work_vec[o] <= sat_signed32($signed(work_vec[o]) + $signed(ffn_out[o]), RES_BITS);
          end

          for (c = 0; c < MODEL_DIM; c++) begin
            hist_head_idx = ffn_hist_head[blk_idx][c];
            ffn_hist[blk_idx][c][hist_head_idx] <= x_base[c];
            if (KERNEL_SIZE > 1) begin
              if (hist_head_idx == (KERNEL_SIZE - 1)) begin
                ffn_hist_head[blk_idx][c] <= '0;
              end else begin
                ffn_hist_head[blk_idx][c] <= hist_head_idx + 1;
              end
            end
          end

          if (blk_idx == (LAYER_NUM - 1)) begin
            state <= S_OP;
          end else begin
            blk_idx <= blk_idx + 1'b1;
            state <= S_ATT_PRE;
          end
        end

        S_OP: begin
          for (o = 0; o < OUT_DIM; o++) begin
            acc = 64'sd0;
            for (i = 0; i < MODEL_DIM; i++) begin
              acc = acc + $signed(work_vec[i]) * $signed(rom_read(ROM_ID_OUTPUT_PROJ_W, o*MODEL_DIM + i));
            end
            exp_acc = RES_EXP + OUTPUT_PROJ_W_EXP;
            b_aligned = requant_pow2_signed($signed(rom_read(ROM_ID_OUTPUT_PROJ_B, o)), OUTPUT_PROJ_B_EXP, exp_acc, 32);
            acc = acc + $signed(b_aligned);
            out_vec[o] <= requant_pow2_signed(acc, exp_acc, IO_EXP_OUT, IO_OUT_BITS);
          end

          out_valid_r <= 1'b1;
          state <= S_OUT;
        end

        S_OUT: begin
          if (out_valid_r && out_ready) begin
            out_valid_r <= 1'b0;
            state <= S_IDLE;
          end
        end

        default: begin
          state <= S_IDLE;
        end
      endcase
    end
  end

endmodule
