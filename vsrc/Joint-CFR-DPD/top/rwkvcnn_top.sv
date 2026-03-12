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

  typedef enum logic [4:0] {
    S_IDLE        = 5'd0,
    S_IP          = 5'd1,
    S_IP_WAIT     = 5'd2,
    S_ATT_TS      = 5'd3,
    S_ATT_QK      = 5'd4,
    S_ATT_QK_WAIT = 5'd5,
    S_ATT_QV      = 5'd6,
    S_ATT_QV_WAIT = 5'd7,
    S_ATT_QR      = 5'd8,
    S_ATT_QR_WAIT = 5'd9,
    S_ATT_GATE    = 5'd10,
    S_ATT_WKV     = 5'd11,
    S_ATT_DIV     = 5'd12,
    S_ATT_OUT     = 5'd13,
    S_ATT_OUT_WAIT = 5'd14,
    S_FFN_TS      = 5'd15,
    S_FFN_KEY     = 5'd16,
    S_FFN_KEY_WAIT = 5'd17,
    S_FFN_VAL     = 5'd18,
    S_FFN_VAL_WAIT = 5'd19,
    S_FFN_REC     = 5'd20,
    S_FFN_REC_WAIT = 5'd21,
    S_FFN_OUT     = 5'd22,
    S_OP          = 5'd23,
    S_OP_WAIT     = 5'd24,
    S_OUT         = 5'd25
  } state_t;

  localparam int KERNEL_HEAD_W = (KERNEL_SIZE <= 1) ? 1 : $clog2(KERNEL_SIZE);
  localparam int LINEAR_MAX_DIM = HIDDEN_SZ;
  localparam logic [3:0] LIN_NONE      = 4'd0;
  localparam logic [3:0] LIN_IP        = 4'd1;
  localparam logic [3:0] LIN_ATT_KEY   = 4'd2;
  localparam logic [3:0] LIN_ATT_VALUE = 4'd3;
  localparam logic [3:0] LIN_ATT_REC   = 4'd4;
  localparam logic [3:0] LIN_ATT_OUT   = 4'd5;
  localparam logic [3:0] LIN_FFN_KEY   = 4'd6;
  localparam logic [3:0] LIN_FFN_VAL   = 4'd7;
  localparam logic [3:0] LIN_FFN_REC   = 4'd8;
  localparam logic [3:0] LIN_OP        = 4'd9;

  state_t state;
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

  always @* begin
    out_data = '0;
    for (oi = 0; oi < OUT_DIM; oi++) begin
      out_data[oi*32 +: 32] = out_vec[oi];
    end
  end

`define DECL_ROM_FLAT(SIG, ROM_ID_PARAM, NUMEL_PARAM) \
  wire signed [((NUMEL_PARAM) * 32) - 1:0] SIG; \
  rwkv_rom_flat #(.ROM_ID(ROM_ID_PARAM), .LEN(NUMEL_PARAM)) SIG``_inst ( \
    .data(SIG) \
  );

`define DECL_ROM_SCALAR(SIG, ROM_ID_PARAM) \
  logic signed [31:0] SIG; \
  rwkv_rom #(.ROM_ID(ROM_ID_PARAM)) SIG``_inst ( \
    .addr(16'd0), \
    .rdata(SIG) \
  );

  `DECL_ROM_FLAT(blocks_0_att_time_shift_w_rom, ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W, BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_shift_w_rom, ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W, BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL)
  `DECL_ROM_FLAT(blocks_0_att_time_shift_b_rom, ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B, BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_shift_b_rom, ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B, BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL)
  `DECL_ROM_FLAT(blocks_0_att_time_mix_k_rom, ROM_ID_BLOCKS_0_ATT_TIME_MIX_K, BLOCKS_0_ATT_TIME_MIX_K_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_mix_k_rom, ROM_ID_BLOCKS_1_ATT_TIME_MIX_K, BLOCKS_1_ATT_TIME_MIX_K_NUMEL)
  `DECL_ROM_FLAT(blocks_0_att_time_mix_v_rom, ROM_ID_BLOCKS_0_ATT_TIME_MIX_V, BLOCKS_0_ATT_TIME_MIX_V_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_mix_v_rom, ROM_ID_BLOCKS_1_ATT_TIME_MIX_V, BLOCKS_1_ATT_TIME_MIX_V_NUMEL)
  `DECL_ROM_FLAT(blocks_0_att_time_mix_r_rom, ROM_ID_BLOCKS_0_ATT_TIME_MIX_R, BLOCKS_0_ATT_TIME_MIX_R_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_mix_r_rom, ROM_ID_BLOCKS_1_ATT_TIME_MIX_R, BLOCKS_1_ATT_TIME_MIX_R_NUMEL)
  `DECL_ROM_SCALAR(blocks_0_att_one_tm_rom, ROM_ID_BLOCKS_0_ATT_ONE_TM)
  `DECL_ROM_SCALAR(blocks_1_att_one_tm_rom, ROM_ID_BLOCKS_1_ATT_ONE_TM)
  `DECL_ROM_FLAT(blocks_0_att_time_first_rom, ROM_ID_BLOCKS_0_ATT_TIME_FIRST, BLOCKS_0_ATT_TIME_FIRST_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_first_rom, ROM_ID_BLOCKS_1_ATT_TIME_FIRST, BLOCKS_1_ATT_TIME_FIRST_NUMEL)
  `DECL_ROM_FLAT(blocks_0_att_time_decay_wexp_rom, ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP, BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL)
  `DECL_ROM_FLAT(blocks_1_att_time_decay_wexp_rom, ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP, BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL)
  `DECL_ROM_FLAT(blocks_0_ffn_time_shift_w_rom, ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W, BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL)
  `DECL_ROM_FLAT(blocks_1_ffn_time_shift_w_rom, ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W, BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL)
  `DECL_ROM_FLAT(blocks_0_ffn_time_shift_b_rom, ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B, BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL)
  `DECL_ROM_FLAT(blocks_1_ffn_time_shift_b_rom, ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B, BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL)
  `DECL_ROM_FLAT(blocks_0_ffn_time_mix_k_rom, ROM_ID_BLOCKS_0_FFN_TIME_MIX_K, BLOCKS_0_FFN_TIME_MIX_K_NUMEL)
  `DECL_ROM_FLAT(blocks_1_ffn_time_mix_k_rom, ROM_ID_BLOCKS_1_FFN_TIME_MIX_K, BLOCKS_1_FFN_TIME_MIX_K_NUMEL)
  `DECL_ROM_FLAT(blocks_0_ffn_time_mix_r_rom, ROM_ID_BLOCKS_0_FFN_TIME_MIX_R, BLOCKS_0_FFN_TIME_MIX_R_NUMEL)
  `DECL_ROM_FLAT(blocks_1_ffn_time_mix_r_rom, ROM_ID_BLOCKS_1_FFN_TIME_MIX_R, BLOCKS_1_FFN_TIME_MIX_R_NUMEL)
  `DECL_ROM_SCALAR(blocks_0_ffn_one_tm_rom, ROM_ID_BLOCKS_0_FFN_ONE_TM)
  `DECL_ROM_SCALAR(blocks_1_ffn_one_tm_rom, ROM_ID_BLOCKS_1_FFN_ONE_TM)
  `DECL_ROM_FLAT(wkv_lut_rom, ROM_ID_WKV_LUT, WKV_LUT_NUMEL)
  `DECL_ROM_SCALAR(wkv_min_delta_i_rom, ROM_ID_WKV_MIN_DELTA_I)
  `DECL_ROM_SCALAR(wkv_step_i_rom, ROM_ID_WKV_STEP_I)
  `DECL_ROM_SCALAR(wkv_e_frac_rom, ROM_ID_WKV_E_FRAC)
  `DECL_ROM_SCALAR(wkv_log_exp_rom, ROM_ID_WKV_LOG_EXP)

  logic signed [31:0] input_proj_w_data;
  logic signed [31:0] input_proj_b_data;
  logic signed [31:0] blocks_0_att_key_w_data;
  logic signed [31:0] blocks_1_att_key_w_data;
  logic signed [31:0] blocks_0_att_value_w_data;
  logic signed [31:0] blocks_1_att_value_w_data;
  logic signed [31:0] blocks_0_att_receptance_w_data;
  logic signed [31:0] blocks_1_att_receptance_w_data;
  logic signed [31:0] blocks_0_att_output_w_data;
  logic signed [31:0] blocks_1_att_output_w_data;
  logic signed [31:0] blocks_0_ffn_key_w_data;
  logic signed [31:0] blocks_1_ffn_key_w_data;
  logic signed [31:0] blocks_0_ffn_receptance_w_data;
  logic signed [31:0] blocks_1_ffn_receptance_w_data;
  logic signed [31:0] blocks_0_ffn_value_w_data;
  logic signed [31:0] blocks_1_ffn_value_w_data;
  logic signed [31:0] output_proj_w_data;
  logic signed [31:0] output_proj_b_data;

  logic [15:0] lin_w_addr;
  logic [15:0] lin_b_addr;
  logic [3:0] lin_stage;
  logic lin_start;
  logic lin_bias_en;
  logic [15:0] lin_in_dim;
  logic [15:0] lin_out_dim;
  logic signed [31:0] lin_exp_x;
  logic signed [31:0] lin_exp_out;
  logic signed [31:0] lin_w_exp;
  logic signed [31:0] lin_b_exp;
  logic [7:0] lin_out_bits;
  logic signed [31:0] lin_x_vec [0:LINEAR_MAX_DIM-1];
  logic signed [LINEAR_MAX_DIM*32-1:0] lin_y_bus;
  logic signed [31:0] lin_w_data;
  logic signed [31:0] lin_b_data;
  logic lin_busy;
  logic lin_done;

  rwkv_rom #(.ROM_ID(ROM_ID_INPUT_PROJ_W)) u_input_proj_w (
    .addr((lin_stage == LIN_IP) ? lin_w_addr : 16'd0),
    .rdata(input_proj_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_INPUT_PROJ_B)) u_input_proj_b (
    .addr((lin_stage == LIN_IP) ? lin_b_addr : 16'd0),
    .rdata(input_proj_b_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_ATT_KEY_W)) u_blocks_0_att_key_w (
    .addr((lin_stage == LIN_ATT_KEY) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_att_key_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_ATT_KEY_W)) u_blocks_1_att_key_w (
    .addr((lin_stage == LIN_ATT_KEY) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_att_key_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_ATT_VALUE_W)) u_blocks_0_att_value_w (
    .addr((lin_stage == LIN_ATT_VALUE) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_att_value_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_ATT_VALUE_W)) u_blocks_1_att_value_w (
    .addr((lin_stage == LIN_ATT_VALUE) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_att_value_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W)) u_blocks_0_att_receptance_w (
    .addr((lin_stage == LIN_ATT_REC) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_att_receptance_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W)) u_blocks_1_att_receptance_w (
    .addr((lin_stage == LIN_ATT_REC) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_att_receptance_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_ATT_OUTPUT_W)) u_blocks_0_att_output_w (
    .addr((lin_stage == LIN_ATT_OUT) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_att_output_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_ATT_OUTPUT_W)) u_blocks_1_att_output_w (
    .addr((lin_stage == LIN_ATT_OUT) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_att_output_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_FFN_KEY_W)) u_blocks_0_ffn_key_w (
    .addr((lin_stage == LIN_FFN_KEY) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_ffn_key_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_FFN_KEY_W)) u_blocks_1_ffn_key_w (
    .addr((lin_stage == LIN_FFN_KEY) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_ffn_key_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W)) u_blocks_0_ffn_receptance_w (
    .addr((lin_stage == LIN_FFN_REC) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_ffn_receptance_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W)) u_blocks_1_ffn_receptance_w (
    .addr((lin_stage == LIN_FFN_REC) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_ffn_receptance_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_0_FFN_VALUE_W)) u_blocks_0_ffn_value_w (
    .addr((lin_stage == LIN_FFN_VAL) ? lin_w_addr : 16'd0),
    .rdata(blocks_0_ffn_value_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_BLOCKS_1_FFN_VALUE_W)) u_blocks_1_ffn_value_w (
    .addr((lin_stage == LIN_FFN_VAL) ? lin_w_addr : 16'd0),
    .rdata(blocks_1_ffn_value_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_OUTPUT_PROJ_W)) u_output_proj_w (
    .addr((lin_stage == LIN_OP) ? lin_w_addr : 16'd0),
    .rdata(output_proj_w_data)
  );
  rwkv_rom #(.ROM_ID(ROM_ID_OUTPUT_PROJ_B)) u_output_proj_b (
    .addr((lin_stage == LIN_OP) ? lin_b_addr : 16'd0),
    .rdata(output_proj_b_data)
  );

`undef DECL_ROM_FLAT
`undef DECL_ROM_SCALAR

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
        att_ts_w = blocks_0_att_time_shift_w_rom[idx*32 +: 32];
      end else begin
        att_ts_w = blocks_1_att_time_shift_w_rom[idx*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] att_ts_b(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_ts_b = blocks_0_att_time_shift_b_rom[c*32 +: 32];
      end else begin
        att_ts_b = blocks_1_att_time_shift_b_rom[c*32 +: 32];
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
        att_tm_k = blocks_0_att_time_mix_k_rom[c*32 +: 32];
      end else begin
        att_tm_k = blocks_1_att_time_mix_k_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] att_tm_v(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_tm_v = blocks_0_att_time_mix_v_rom[c*32 +: 32];
      end else begin
        att_tm_v = blocks_1_att_time_mix_v_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] att_tm_r(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_tm_r = blocks_0_att_time_mix_r_rom[c*32 +: 32];
      end else begin
        att_tm_r = blocks_1_att_time_mix_r_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] att_one_tm(input int blk);
    begin
      if (blk == 0) begin
        att_one_tm = blocks_0_att_one_tm_rom;
      end else begin
        att_one_tm = blocks_1_att_one_tm_rom;
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
        att_time_first = blocks_0_att_time_first_rom[c*32 +: 32];
      end else begin
        att_time_first = blocks_1_att_time_first_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] att_time_decay(input int blk, input int c);
    begin
      if (blk == 0) begin
        att_time_decay = blocks_0_att_time_decay_wexp_rom[c*32 +: 32];
      end else begin
        att_time_decay = blocks_1_att_time_decay_wexp_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_ts_w(input int blk, input int c, input int k);
    int idx;
    begin
      idx = c*KERNEL_SIZE + k;
      if (blk == 0) begin
        ffn_ts_w = blocks_0_ffn_time_shift_w_rom[idx*32 +: 32];
      end else begin
        ffn_ts_w = blocks_1_ffn_time_shift_w_rom[idx*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_ts_b(input int blk, input int c);
    begin
      if (blk == 0) begin
        ffn_ts_b = blocks_0_ffn_time_shift_b_rom[c*32 +: 32];
      end else begin
        ffn_ts_b = blocks_1_ffn_time_shift_b_rom[c*32 +: 32];
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
        ffn_tm_k = blocks_0_ffn_time_mix_k_rom[c*32 +: 32];
      end else begin
        ffn_tm_k = blocks_1_ffn_time_mix_k_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_tm_r(input int blk, input int c);
    begin
      if (blk == 0) begin
        ffn_tm_r = blocks_0_ffn_time_mix_r_rom[c*32 +: 32];
      end else begin
        ffn_tm_r = blocks_1_ffn_time_mix_r_rom[c*32 +: 32];
      end
    end
  endfunction

  function automatic logic signed [31:0] ffn_one_tm(input int blk);
    begin
      if (blk == 0) begin
        ffn_one_tm = blocks_0_ffn_one_tm_rom;
      end else begin
        ffn_one_tm = blocks_1_ffn_one_tm_rom;
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
        wkv_min_delta_i_rom,
        wkv_step_i_rom,
        WKV_LUT_NUMEL
      );
      wkv_lut_lookup = wkv_lut_rom[idx*32 +: 32];
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
  logic signed [31:0] att_out [0:MODEL_DIM-1];
  logic signed [31:0] att_pp_next [0:MODEL_DIM-1];
  logic signed [63:0] att_aa_div [0:MODEL_DIM-1];
  logic signed [63:0] att_bb_div [0:MODEL_DIM-1];
  logic signed [63:0] att_aa_next [0:MODEL_DIM-1];
  logic signed [63:0] att_bb_next [0:MODEL_DIM-1];
  logic signed [A_BITS-1:0] att_div_x [0:MODEL_DIM-1];
  logic [B_BITS-1:0] att_div_d [0:MODEL_DIM-1];
  logic signed [31:0] att_div_q [0:MODEL_DIM-1];

  logic signed [31:0] k_ffn [0:HIDDEN_SZ-1];
  logic signed [31:0] k_sq [0:HIDDEN_SZ-1];
  logic signed [31:0] kv_ffn [0:MODEL_DIM-1];
  logic signed [31:0] gate_in_ffn [0:MODEL_DIM-1];
  logic signed [31:0] gate_ffn [0:MODEL_DIM-1];
  logic signed [31:0] ffn_out [0:MODEL_DIM-1];
  logic signed [31:0] mul_att_pre [0:MODEL_DIM-1];

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

  function automatic logic signed [31:0] lin_y_word(input int idx);
    begin
      lin_y_word = lin_y_bus[idx*32 +: 32];
    end
  endfunction

  always @* begin
    for (int idx = 0; idx < MODEL_DIM; idx++) begin
      mul_att_pre[idx] = requant_pow2_signed(
        $signed(y_wkv[idx]) * $signed(gate_att[idx]),
        (EXP_V - GATE_BITS),
        EXP_MUL,
        MUL_BITS
      );
    end
  end

  always @* begin
    lin_stage = LIN_NONE;
    lin_start = 1'b0;
    lin_bias_en = 1'b0;
    lin_in_dim = 16'd0;
    lin_out_dim = 16'd0;
    lin_exp_x = 32'sd0;
    lin_exp_out = 32'sd0;
    lin_w_exp = 32'sd0;
    lin_b_exp = 32'sd0;
    lin_out_bits = 8'd0;

    case (state)
      S_IP, S_IP_WAIT: begin
        lin_stage = LIN_IP;
        lin_start = (state == S_IP);
        lin_bias_en = 1'b1;
        lin_in_dim = IN_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = IO_EXP_IN;
        lin_exp_out = RES_EXP;
        lin_w_exp = INPUT_PROJ_W_EXP;
        lin_b_exp = INPUT_PROJ_B_EXP;
        lin_out_bits = RES_BITS;
      end

      S_ATT_QK, S_ATT_QK_WAIT: begin
        lin_stage = LIN_ATT_KEY;
        lin_start = (state == S_ATT_QK);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = wkv_log_exp_rom;
        lin_w_exp = att_key_w_exp(blk_idx);
        lin_out_bits = K_BITS;
      end

      S_ATT_QV, S_ATT_QV_WAIT: begin
        lin_stage = LIN_ATT_VALUE;
        lin_start = (state == S_ATT_QV);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = EXP_V;
        lin_w_exp = att_value_w_exp(blk_idx);
        lin_out_bits = V_BITS;
      end

      S_ATT_QR, S_ATT_QR_WAIT: begin
        lin_stage = LIN_ATT_REC;
        lin_start = (state == S_ATT_QR);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = EXP_R;
        lin_w_exp = att_receptance_w_exp(blk_idx);
        lin_out_bits = R_BITS;
      end

      S_ATT_OUT, S_ATT_OUT_WAIT: begin
        lin_stage = LIN_ATT_OUT;
        lin_start = (state == S_ATT_OUT);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = EXP_MUL;
        lin_exp_out = RES_EXP;
        lin_w_exp = att_output_w_exp(blk_idx);
        lin_out_bits = RES_BITS;
      end

      S_FFN_KEY, S_FFN_KEY_WAIT: begin
        lin_stage = LIN_FFN_KEY;
        lin_start = (state == S_FFN_KEY);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = HIDDEN_SZ;
        lin_exp_x = RES_EXP;
        lin_exp_out = RES_EXP;
        lin_w_exp = ffn_key_w_exp(blk_idx);
        lin_out_bits = RES_BITS;
      end

      S_FFN_VAL, S_FFN_VAL_WAIT: begin
        lin_stage = LIN_FFN_VAL;
        lin_start = (state == S_FFN_VAL);
        lin_in_dim = HIDDEN_SZ;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = RES_EXP;
        lin_w_exp = ffn_value_w_exp(blk_idx);
        lin_out_bits = RES_BITS;
      end

      S_FFN_REC, S_FFN_REC_WAIT: begin
        lin_stage = LIN_FFN_REC;
        lin_start = (state == S_FFN_REC);
        lin_in_dim = MODEL_DIM;
        lin_out_dim = MODEL_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = RES_EXP;
        lin_w_exp = ffn_receptance_w_exp(blk_idx);
        lin_out_bits = RES_BITS;
      end

      S_OP, S_OP_WAIT: begin
        lin_stage = LIN_OP;
        lin_start = (state == S_OP);
        lin_bias_en = 1'b1;
        lin_in_dim = MODEL_DIM;
        lin_out_dim = OUT_DIM;
        lin_exp_x = RES_EXP;
        lin_exp_out = IO_EXP_OUT;
        lin_w_exp = OUTPUT_PROJ_W_EXP;
        lin_b_exp = OUTPUT_PROJ_B_EXP;
        lin_out_bits = IO_OUT_BITS;
      end

      default: begin
      end
    endcase
  end

  always @* begin
    for (int idx = 0; idx < LINEAR_MAX_DIM; idx++) begin
      lin_x_vec[idx] = 32'sd0;
    end

    case (lin_stage)
      LIN_IP: begin
        for (int idx = 0; idx < IN_DIM; idx++) begin
          lin_x_vec[idx] = in_vec[idx];
        end
      end
      LIN_ATT_KEY: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = xk[idx];
        end
      end
      LIN_ATT_VALUE: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = xv[idx];
        end
      end
      LIN_ATT_REC: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = xr[idx];
        end
      end
      LIN_ATT_OUT: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = mul_att_pre[idx];
        end
      end
      LIN_FFN_KEY: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = xk[idx];
        end
      end
      LIN_FFN_VAL: begin
        for (int idx = 0; idx < HIDDEN_SZ; idx++) begin
          lin_x_vec[idx] = k_sq[idx];
        end
      end
      LIN_FFN_REC: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = xr[idx];
        end
      end
      LIN_OP: begin
        for (int idx = 0; idx < MODEL_DIM; idx++) begin
          lin_x_vec[idx] = work_vec[idx];
        end
      end
      default: begin
      end
    endcase
  end

  always @* begin
    lin_w_data = 32'sd0;
    lin_b_data = 32'sd0;

    case (lin_stage)
      LIN_IP: begin
        lin_w_data = input_proj_w_data;
        lin_b_data = input_proj_b_data;
      end
      LIN_ATT_KEY: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_att_key_w_data : blocks_1_att_key_w_data;
      end
      LIN_ATT_VALUE: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_att_value_w_data : blocks_1_att_value_w_data;
      end
      LIN_ATT_REC: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_att_receptance_w_data : blocks_1_att_receptance_w_data;
      end
      LIN_ATT_OUT: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_att_output_w_data : blocks_1_att_output_w_data;
      end
      LIN_FFN_KEY: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_ffn_key_w_data : blocks_1_ffn_key_w_data;
      end
      LIN_FFN_VAL: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_ffn_value_w_data : blocks_1_ffn_value_w_data;
      end
      LIN_FFN_REC: begin
        lin_w_data = (blk_idx == 0) ? blocks_0_ffn_receptance_w_data : blocks_1_ffn_receptance_w_data;
      end
      LIN_OP: begin
        lin_w_data = output_proj_w_data;
        lin_b_data = output_proj_b_data;
      end
      default: begin
      end
    endcase
  end

  linear_engine_rom #(
    .MAX_IN_DIM(LINEAR_MAX_DIM),
    .MAX_OUT_DIM(LINEAR_MAX_DIM)
  ) u_linear_engine_rom (
    .clk(clk),
    .rst_n(rst_n),
    .start(lin_start),
    .x_vec(lin_x_vec),
    .in_dim(lin_in_dim),
    .out_dim(lin_out_dim),
    .bias_en(lin_bias_en),
    .exp_x(lin_exp_x),
    .exp_out(lin_exp_out),
    .w_exp(lin_w_exp),
    .b_exp(lin_b_exp),
    .out_bits(lin_out_bits),
    .w_data(lin_w_data),
    .b_data(lin_b_data),
    .w_addr(lin_w_addr),
    .b_addr(lin_b_addr),
    .busy(lin_busy),
    .done(lin_done),
    .y_bus(lin_y_bus)
  );

  generate
    for (genvar div_idx = 0; div_idx < MODEL_DIM; div_idx++) begin : gen_att_div
      assign att_div_x[div_idx] = att_aa_div[div_idx][A_BITS-1:0];
      assign att_div_d[div_idx] = (att_bb_div[div_idx][B_BITS-1:0] == {B_BITS{1'b0}})
        ? {{(B_BITS-1){1'b0}}, 1'b1}
        : att_bb_div[div_idx][B_BITS-1:0];

      div_rne_su #(
        .X_WIDTH(A_BITS),
        .D_WIDTH(B_BITS),
        .Q_WIDTH(32)
      ) u_div_rne_su (
        .x(att_div_x[div_idx]),
        .d(att_div_d[div_idx]),
        .q(att_div_q[div_idx])
      );
    end
  endgenerate

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
        x_base[i] <= '0;
        xx[i] <= '0;
        xk[i] <= '0;
        xv[i] <= '0;
        xr[i] <= '0;
        k_att[i] <= '0;
        v_att[i] <= '0;
        r_att[i] <= '0;
        gate_att[i] <= '0;
        y_wkv[i] <= '0;
        att_out[i] <= '0;
        att_pp_next[i] <= '0;
        att_aa_div[i] <= '0;
        att_bb_div[i] <= '0;
        att_aa_next[i] <= '0;
        att_bb_next[i] <= '0;
      end
      for (i = 0; i < HIDDEN_SZ; i++) begin
        k_ffn[i] <= '0;
        k_sq[i] <= '0;
      end
      for (i = 0; i < MODEL_DIM; i++) begin
        kv_ffn[i] <= '0;
        gate_in_ffn[i] <= '0;
        gate_ffn[i] <= '0;
        ffn_out[i] <= '0;
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
          state <= S_IP_WAIT;
        end

        S_IP_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              work_vec[o] <= lin_y_word(o);
            end
            blk_idx <= '0;
            state <= S_ATT_TS;
          end
        end

        S_ATT_TS: begin
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

          state <= S_ATT_QK;
        end

        S_ATT_QK: begin
          state <= S_ATT_QK_WAIT;
        end

        S_ATT_QK_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              k_att[o] = lin_y_word(o);
            end
            state <= S_ATT_QV;
          end
        end

        S_ATT_QV: begin
          state <= S_ATT_QV_WAIT;
        end

        S_ATT_QV_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              v_att[o] = lin_y_word(o);
            end
            state <= S_ATT_QR;
          end
        end

        S_ATT_QR: begin
          state <= S_ATT_QR_WAIT;
        end

        S_ATT_QR_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              r_att[o] = lin_y_word(o);
            end
            state <= S_ATT_GATE;
          end
        end

        S_ATT_GATE: begin
          for (o = 0; o < MODEL_DIM; o++) begin
            gate_att[o] = hardsigmoid_int_default(r_att[o], EXP_R, GATE_BITS);
          end
          state <= S_ATT_WKV;
        end

        S_ATT_WKV: begin
          for (c = 0; c < MODEL_DIM; c++) begin
            uu = att_time_first(blk_idx, c);
            wd = att_time_decay(blk_idx, c);

            ww = $signed(k_att[c]) + $signed(uu);
            p = ($signed(pp_state[blk_idx][c]) > $signed(ww)) ? pp_state[blk_idx][c] : ww;

            e1 = $signed(wkv_lut_lookup(pp_state[blk_idx][c] - p));
            e2 = $signed(wkv_lut_lookup(ww - p));

            aa = aa_state[blk_idx][c];
            bb = bb_state[blk_idx][c];

            t1 = rshift_rne64(aa * e1, wkv_e_frac_rom);
            t2 = $signed(v_att[c]) * e2;
            aa = sat_signed64(t1 + t2, A_BITS);

            t1 = rshift_rne64(bb * e1, wkv_e_frac_rom);
            t2 = e2;
            bb = $signed(sat_unsigned64(t1 + t2, B_BITS));

            att_aa_div[c] = aa;
            att_bb_div[c] = bb;

            ww2 = $signed(pp_state[blk_idx][c]) + $signed(wd);
            p2 = ($signed(ww2) > $signed(k_att[c])) ? ww2 : k_att[c];

            e1n = $signed(wkv_lut_lookup(ww2 - p2));
            e2n = $signed(wkv_lut_lookup(k_att[c] - p2));

            t1 = rshift_rne64(aa * e1n, wkv_e_frac_rom);
            t2 = $signed(v_att[c]) * e2n;
            att_aa_next[c] = sat_signed64(t1 + t2, A_BITS);

            t1 = rshift_rne64(bb * e1n, wkv_e_frac_rom);
            t2 = e2n;
            att_bb_next[c] = $signed(sat_unsigned64(t1 + t2, B_BITS));
            att_pp_next[c] = p2;
          end

          state <= S_ATT_DIV;
        end

        S_ATT_DIV: begin
          for (c = 0; c < MODEL_DIM; c++) begin
            y_wkv[c] = att_div_q[c];

            pp_state[blk_idx][c] <= att_pp_next[c];
            aa_state[blk_idx][c] <= att_aa_next[c];
            bb_state[blk_idx][c] <= att_bb_next[c];
          end

          state <= S_ATT_OUT;
        end

        S_ATT_OUT: begin
          state <= S_ATT_OUT_WAIT;
        end

        S_ATT_OUT_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              att_out[o] = lin_y_word(o);
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

            state <= S_FFN_TS;
          end
        end

        S_FFN_TS: begin
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

          state <= S_FFN_KEY;
        end

        S_FFN_KEY: begin
          state <= S_FFN_KEY_WAIT;
        end

        S_FFN_KEY_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < HIDDEN_SZ; o++) begin
              k_ffn[o] = lin_y_word(o);

              if (k_ffn[o] < 0) begin
                k_ffn[o] = 32'sd0;
              end else if ($signed(k_ffn[o]) > qmax_signed64(RES_BITS)) begin
                k_ffn[o] = qmax_signed64(RES_BITS);
              end

              prod = $signed(k_ffn[o]) * $signed(k_ffn[o]);
              k_sq[o] = requant_pow2_signed(prod, RES_EXP + RES_EXP, RES_EXP, RES_BITS);
            end

            state <= S_FFN_VAL;
          end
        end

        S_FFN_VAL: begin
          state <= S_FFN_VAL_WAIT;
        end

        S_FFN_VAL_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              kv_ffn[o] = lin_y_word(o);
            end
            state <= S_FFN_REC;
          end
        end

        S_FFN_REC: begin
          state <= S_FFN_REC_WAIT;
        end

        S_FFN_REC_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < MODEL_DIM; o++) begin
              gate_in_ffn[o] = lin_y_word(o);
            end
            state <= S_FFN_OUT;
          end
        end

        S_FFN_OUT: begin
          for (o = 0; o < MODEL_DIM; o++) begin
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
            state <= S_ATT_TS;
          end
        end

        S_OP: begin
          state <= S_OP_WAIT;
        end

        S_OP_WAIT: begin
          if (lin_done) begin
            for (o = 0; o < OUT_DIM; o++) begin
              out_vec[o] <= lin_y_word(o);
            end
            out_valid_r <= 1'b1;
            state <= S_OUT;
          end
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
