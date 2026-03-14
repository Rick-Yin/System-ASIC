package rwkvcnn_pkg;

  // Auto-generated from vsrc/rom/manifest.json and vsrc/rom/bin/*.bin
  // MANIFEST_GENERATED_AT: 2026-03-13T13:14:15.695398+00:00

  localparam int IN_DIM = 2;
  localparam int MODEL_DIM = 6;
  localparam int LAYER_NUM = 2;
  localparam int OUT_DIM = 2;
  localparam int KERNEL_SIZE = 4;
  localparam int HIDDEN_SZ = 18;

  localparam int RES_EXP = -7;
  localparam int RES_BITS = 8;
  localparam int GATE_BITS = 8;
  localparam int K_BITS = 8;
  localparam int V_BITS = 8;
  localparam int R_BITS = 8;
  localparam int EXP_V = -7;
  localparam int EXP_R = -8;
  localparam int EXP_MUL = -7;
  localparam int MUL_BITS = 8;
  localparam int P_BITS = 16;
  localparam int A_BITS = 24;
  localparam int B_BITS = 24;
  localparam int IO_EXP_IN = -11;
  localparam int IO_EXP_OUT = -11;
  localparam int IO_IN_BITS = 12;
  localparam int IO_OUT_BITS = 12;

  localparam int ROM_COUNT = 49;

  localparam int ROM_ID_INPUT_PROJ_W = 0;
  localparam int INPUT_PROJ_W_NUMEL = 12;
  localparam int INPUT_PROJ_W_EXP = -10;
  localparam int INPUT_PROJ_W_LOGICAL_BITS = 12;
  localparam bit INPUT_PROJ_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_INPUT_PROJ_B = 1;
  localparam int INPUT_PROJ_B_NUMEL = 6;
  localparam int INPUT_PROJ_B_EXP = -10;
  localparam int INPUT_PROJ_B_LOGICAL_BITS = 20;
  localparam bit INPUT_PROJ_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W = 2;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_SHIFT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B = 3;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_LOGICAL_BITS = 16;
  localparam bit BLOCKS_0_ATT_TIME_SHIFT_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_KEY_W = 4;
  localparam int BLOCKS_0_ATT_KEY_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_KEY_W_EXP = -3;
  localparam int BLOCKS_0_ATT_KEY_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_ATT_KEY_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_VALUE_W = 5;
  localparam int BLOCKS_0_ATT_VALUE_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_VALUE_W_EXP = -8;
  localparam int BLOCKS_0_ATT_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_VALUE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W = 6;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_ATT_RECEPTANCE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_OUTPUT_W = 7;
  localparam int BLOCKS_0_ATT_OUTPUT_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_OUTPUT_W_EXP = -8;
  localparam int BLOCKS_0_ATT_OUTPUT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_OUTPUT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W = 8;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_EXP = -3;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_FFN_TIME_SHIFT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B = 9;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_EXP = -3;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_FFN_TIME_SHIFT_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_FFN_KEY_W = 10;
  localparam int BLOCKS_0_FFN_KEY_W_NUMEL = 108;
  localparam int BLOCKS_0_FFN_KEY_W_EXP = -7;
  localparam int BLOCKS_0_FFN_KEY_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_KEY_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W = 11;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_FFN_RECEPTANCE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_FFN_VALUE_W = 12;
  localparam int BLOCKS_0_FFN_VALUE_W_NUMEL = 108;
  localparam int BLOCKS_0_FFN_VALUE_W_EXP = -8;
  localparam int BLOCKS_0_FFN_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_VALUE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W = 13;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_EXP = -3;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_TIME_SHIFT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B = 14;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_EXP = -3;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_SHIFT_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_KEY_W = 15;
  localparam int BLOCKS_1_ATT_KEY_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_KEY_W_EXP = -3;
  localparam int BLOCKS_1_ATT_KEY_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_KEY_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_VALUE_W = 16;
  localparam int BLOCKS_1_ATT_VALUE_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_VALUE_W_EXP = -8;
  localparam int BLOCKS_1_ATT_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_VALUE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W = 17;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_RECEPTANCE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_OUTPUT_W = 18;
  localparam int BLOCKS_1_ATT_OUTPUT_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_OUTPUT_W_EXP = -8;
  localparam int BLOCKS_1_ATT_OUTPUT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_OUTPUT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W = 19;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_EXP = -7;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_SHIFT_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B = 20;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_EXP = -7;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_LOGICAL_BITS = 16;
  localparam bit BLOCKS_1_FFN_TIME_SHIFT_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_FFN_KEY_W = 21;
  localparam int BLOCKS_1_FFN_KEY_W_NUMEL = 108;
  localparam int BLOCKS_1_FFN_KEY_W_EXP = -7;
  localparam int BLOCKS_1_FFN_KEY_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_KEY_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W = 22;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_EXP = -8;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_RECEPTANCE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_FFN_VALUE_W = 23;
  localparam int BLOCKS_1_FFN_VALUE_W_NUMEL = 108;
  localparam int BLOCKS_1_FFN_VALUE_W_EXP = -8;
  localparam int BLOCKS_1_FFN_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_VALUE_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_OUTPUT_PROJ_W = 24;
  localparam int OUTPUT_PROJ_W_NUMEL = 12;
  localparam int OUTPUT_PROJ_W_EXP = -7;
  localparam int OUTPUT_PROJ_W_LOGICAL_BITS = 8;
  localparam bit OUTPUT_PROJ_W_IS_SIGNED = 1'b1;

  localparam int ROM_ID_OUTPUT_PROJ_B = 25;
  localparam int OUTPUT_PROJ_B_NUMEL = 2;
  localparam int OUTPUT_PROJ_B_EXP = -7;
  localparam int OUTPUT_PROJ_B_LOGICAL_BITS = 16;
  localparam bit OUTPUT_PROJ_B_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_K = 26;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_K_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_V = 27;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_V_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_R = 28;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_R_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_ATT_ONE_TM = 29;
  localparam int BLOCKS_0_ATT_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_0_ATT_ONE_TM_EXP = -8;
  localparam int BLOCKS_0_ATT_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_ONE_TM_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_MIX_K = 30;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_TIME_MIX_K_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_MIX_R = 31;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_TIME_MIX_R_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_0_FFN_ONE_TM = 32;
  localparam int BLOCKS_0_FFN_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_0_FFN_ONE_TM_EXP = -8;
  localparam int BLOCKS_0_FFN_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_ONE_TM_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_K = 33;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_K_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_V = 34;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_V_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_R = 35;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_R_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_ATT_ONE_TM = 36;
  localparam int BLOCKS_1_ATT_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_1_ATT_ONE_TM_EXP = -8;
  localparam int BLOCKS_1_ATT_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_ONE_TM_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_MIX_K = 37;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_MIX_K_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_MIX_R = 38;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_MIX_R_IS_SIGNED = 1'b0;

  localparam int ROM_ID_BLOCKS_1_FFN_ONE_TM = 39;
  localparam int BLOCKS_1_FFN_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_1_FFN_ONE_TM_EXP = -8;
  localparam int BLOCKS_1_FFN_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_ONE_TM_IS_SIGNED = 1'b0;

  localparam int ROM_ID_WKV_LUT = 40;
  localparam int WKV_LUT_NUMEL = 256;
  localparam int WKV_LUT_EXP = -16;
  localparam int WKV_LUT_LOGICAL_BITS = 16;
  localparam bit WKV_LUT_IS_SIGNED = 1'b0;

  localparam int ROM_ID_WKV_MIN_DELTA_I = 41;
  localparam int WKV_MIN_DELTA_I_NUMEL = 1;
  localparam int WKV_MIN_DELTA_I_EXP = -2;
  localparam int WKV_MIN_DELTA_I_LOGICAL_BITS = 32;
  localparam bit WKV_MIN_DELTA_I_IS_SIGNED = 1'b1;

  localparam int ROM_ID_WKV_STEP_I = 42;
  localparam int WKV_STEP_I_NUMEL = 1;
  localparam int WKV_STEP_I_EXP = -2;
  localparam int WKV_STEP_I_LOGICAL_BITS = 32;
  localparam bit WKV_STEP_I_IS_SIGNED = 1'b1;

  localparam int ROM_ID_WKV_E_FRAC = 43;
  localparam int WKV_E_FRAC_NUMEL = 1;
  localparam int WKV_E_FRAC_EXP = 0;
  localparam int WKV_E_FRAC_LOGICAL_BITS = 32;
  localparam bit WKV_E_FRAC_IS_SIGNED = 1'b0;

  localparam int ROM_ID_WKV_LOG_EXP = 44;
  localparam int WKV_LOG_EXP_NUMEL = 1;
  localparam int WKV_LOG_EXP_EXP = 0;
  localparam int WKV_LOG_EXP_LOGICAL_BITS = 32;
  localparam bit WKV_LOG_EXP_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_FIRST = 45;
  localparam int BLOCKS_0_ATT_TIME_FIRST_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_FIRST_EXP = -2;
  localparam int BLOCKS_0_ATT_TIME_FIRST_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_ATT_TIME_FIRST_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP = 46;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_EXP = -2;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_ATT_TIME_DECAY_WEXP_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_FIRST = 47;
  localparam int BLOCKS_1_ATT_TIME_FIRST_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_FIRST_EXP = -2;
  localparam int BLOCKS_1_ATT_TIME_FIRST_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_FIRST_IS_SIGNED = 1'b1;

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP = 48;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_EXP = -2;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_DECAY_WEXP_IS_SIGNED = 1'b1;

  function automatic logic signed [31:0] rom_read(input logic [7:0] rom_id, input logic [15:0] addr);
    logic signed [31:0] v;
    begin
      v = 32'sd0;
      case (rom_id)
        ROM_ID_INPUT_PROJ_W: begin
          if (addr < INPUT_PROJ_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd329;
              16'd1: v = -32'sd653;
              16'd2: v = 32'sd367;
              16'd3: v = -32'sd416;
              16'd4: v = -32'sd1045;
              16'd5: v = 32'sd1144;
              16'd6: v = -32'sd1267;
              16'd7: v = -32'sd960;
              16'd8: v = -32'sd452;
              16'd9: v = 32'sd7;
              16'd10: v = 32'sd488;
              16'd11: v = -32'sd238;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_INPUT_PROJ_B: begin
          if (addr < INPUT_PROJ_B_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd55;
              16'd1: v = -32'sd22;
              16'd2: v = 32'sd18;
              16'd3: v = 32'sd66;
              16'd4: v = -32'sd16;
              16'd5: v = 32'sd29;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W: begin
          if (addr < BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd7;
              16'd1: v = 32'sd5;
              16'd2: v = 32'sd72;
              16'd3: v = -32'sd99;
              16'd4: v = -32'sd29;
              16'd5: v = 32'sd80;
              16'd6: v = 32'sd125;
              16'd7: v = 32'sd18;
              16'd8: v = -32'sd32;
              16'd9: v = -32'sd7;
              16'd10: v = 32'sd22;
              16'd11: v = -32'sd114;
              16'd12: v = -32'sd88;
              16'd13: v = 32'sd24;
              16'd14: v = -32'sd31;
              16'd15: v = -32'sd118;
              16'd16: v = -32'sd62;
              16'd17: v = 32'sd66;
              16'd18: v = -32'sd66;
              16'd19: v = 32'sd49;
              16'd20: v = 32'sd106;
              16'd21: v = -32'sd8;
              16'd22: v = -32'sd50;
              16'd23: v = -32'sd99;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B: begin
          if (addr < BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd15;
              16'd1: v = 32'sd32;
              16'd2: v = -32'sd123;
              16'd3: v = -32'sd11;
              16'd4: v = -32'sd140;
              16'd5: v = 32'sd119;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_KEY_W: begin
          if (addr < BLOCKS_0_ATT_KEY_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd2;
              16'd1: v = 32'sd4;
              16'd2: v = -32'sd1;
              16'd3: v = -32'sd2;
              16'd4: v = 32'sd1;
              16'd5: v = 32'sd1;
              16'd6: v = 32'sd2;
              16'd7: v = 32'sd2;
              16'd8: v = -32'sd3;
              16'd9: v = 32'sd2;
              16'd10: v = 32'sd0;
              16'd11: v = -32'sd1;
              16'd12: v = 32'sd2;
              16'd13: v = 32'sd2;
              16'd14: v = -32'sd2;
              16'd15: v = -32'sd1;
              16'd16: v = 32'sd3;
              16'd17: v = 32'sd1;
              16'd18: v = 32'sd2;
              16'd19: v = -32'sd2;
              16'd20: v = -32'sd1;
              16'd21: v = 32'sd3;
              16'd22: v = 32'sd2;
              16'd23: v = 32'sd3;
              16'd24: v = -32'sd2;
              16'd25: v = -32'sd2;
              16'd26: v = 32'sd0;
              16'd27: v = -32'sd2;
              16'd28: v = 32'sd2;
              16'd29: v = 32'sd2;
              16'd30: v = 32'sd1;
              16'd31: v = -32'sd1;
              16'd32: v = 32'sd2;
              16'd33: v = -32'sd1;
              16'd34: v = 32'sd4;
              16'd35: v = -32'sd4;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_VALUE_W: begin
          if (addr < BLOCKS_0_ATT_VALUE_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd110;
              16'd1: v = -32'sd44;
              16'd2: v = 32'sd106;
              16'd3: v = 32'sd35;
              16'd4: v = 32'sd64;
              16'd5: v = -32'sd90;
              16'd6: v = 32'sd14;
              16'd7: v = -32'sd14;
              16'd8: v = 32'sd34;
              16'd9: v = 32'sd71;
              16'd10: v = 32'sd40;
              16'd11: v = 32'sd0;
              16'd12: v = 32'sd0;
              16'd13: v = -32'sd68;
              16'd14: v = -32'sd49;
              16'd15: v = 32'sd59;
              16'd16: v = -32'sd52;
              16'd17: v = 32'sd81;
              16'd18: v = -32'sd79;
              16'd19: v = -32'sd43;
              16'd20: v = 32'sd25;
              16'd21: v = -32'sd89;
              16'd22: v = 32'sd31;
              16'd23: v = -32'sd38;
              16'd24: v = -32'sd41;
              16'd25: v = -32'sd9;
              16'd26: v = 32'sd108;
              16'd27: v = 32'sd83;
              16'd28: v = -32'sd45;
              16'd29: v = 32'sd13;
              16'd30: v = -32'sd57;
              16'd31: v = -32'sd85;
              16'd32: v = 32'sd18;
              16'd33: v = -32'sd25;
              16'd34: v = -32'sd65;
              16'd35: v = -32'sd85;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W: begin
          if (addr < BLOCKS_0_ATT_RECEPTANCE_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd2;
              16'd2: v = -32'sd4;
              16'd3: v = -32'sd4;
              16'd4: v = 32'sd0;
              16'd5: v = -32'sd2;
              16'd6: v = -32'sd3;
              16'd7: v = -32'sd2;
              16'd8: v = 32'sd0;
              16'd9: v = -32'sd2;
              16'd10: v = -32'sd2;
              16'd11: v = 32'sd0;
              16'd12: v = -32'sd3;
              16'd13: v = 32'sd1;
              16'd14: v = -32'sd4;
              16'd15: v = -32'sd3;
              16'd16: v = 32'sd0;
              16'd17: v = -32'sd1;
              16'd18: v = -32'sd3;
              16'd19: v = 32'sd1;
              16'd20: v = 32'sd1;
              16'd21: v = 32'sd3;
              16'd22: v = -32'sd1;
              16'd23: v = -32'sd2;
              16'd24: v = -32'sd1;
              16'd25: v = 32'sd0;
              16'd26: v = 32'sd2;
              16'd27: v = -32'sd3;
              16'd28: v = 32'sd0;
              16'd29: v = 32'sd2;
              16'd30: v = -32'sd2;
              16'd31: v = -32'sd2;
              16'd32: v = 32'sd2;
              16'd33: v = -32'sd4;
              16'd34: v = 32'sd1;
              16'd35: v = -32'sd3;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_OUTPUT_W: begin
          if (addr < BLOCKS_0_ATT_OUTPUT_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd53;
              16'd1: v = -32'sd88;
              16'd2: v = 32'sd89;
              16'd3: v = -32'sd115;
              16'd4: v = -32'sd86;
              16'd5: v = -32'sd18;
              16'd6: v = 32'sd110;
              16'd7: v = -32'sd74;
              16'd8: v = -32'sd58;
              16'd9: v = 32'sd79;
              16'd10: v = 32'sd4;
              16'd11: v = 32'sd36;
              16'd12: v = -32'sd94;
              16'd13: v = -32'sd36;
              16'd14: v = -32'sd72;
              16'd15: v = 32'sd74;
              16'd16: v = 32'sd64;
              16'd17: v = -32'sd63;
              16'd18: v = 32'sd21;
              16'd19: v = -32'sd6;
              16'd20: v = -32'sd58;
              16'd21: v = -32'sd75;
              16'd22: v = -32'sd17;
              16'd23: v = 32'sd93;
              16'd24: v = -32'sd89;
              16'd25: v = -32'sd79;
              16'd26: v = -32'sd14;
              16'd27: v = 32'sd19;
              16'd28: v = 32'sd7;
              16'd29: v = -32'sd5;
              16'd30: v = -32'sd16;
              16'd31: v = -32'sd61;
              16'd32: v = -32'sd33;
              16'd33: v = -32'sd63;
              16'd34: v = 32'sd103;
              16'd35: v = -32'sd93;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W: begin
          if (addr < BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd3;
              16'd1: v = -32'sd3;
              16'd2: v = -32'sd1;
              16'd3: v = 32'sd4;
              16'd4: v = 32'sd4;
              16'd5: v = -32'sd2;
              16'd6: v = 32'sd0;
              16'd7: v = 32'sd2;
              16'd8: v = 32'sd0;
              16'd9: v = 32'sd2;
              16'd10: v = -32'sd1;
              16'd11: v = -32'sd3;
              16'd12: v = 32'sd1;
              16'd13: v = -32'sd2;
              16'd14: v = 32'sd1;
              16'd15: v = -32'sd1;
              16'd16: v = 32'sd3;
              16'd17: v = 32'sd5;
              16'd18: v = 32'sd4;
              16'd19: v = -32'sd4;
              16'd20: v = -32'sd1;
              16'd21: v = -32'sd1;
              16'd22: v = -32'sd1;
              16'd23: v = 32'sd4;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B: begin
          if (addr < BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = -32'sd4;
              16'd2: v = -32'sd3;
              16'd3: v = -32'sd2;
              16'd4: v = 32'sd3;
              16'd5: v = -32'sd4;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_KEY_W: begin
          if (addr < BLOCKS_0_FFN_KEY_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd42;
              16'd1: v = -32'sd69;
              16'd2: v = 32'sd40;
              16'd3: v = 32'sd27;
              16'd4: v = -32'sd16;
              16'd5: v = -32'sd3;
              16'd6: v = 32'sd22;
              16'd7: v = -32'sd16;
              16'd8: v = -32'sd33;
              16'd9: v = -32'sd18;
              16'd10: v = 32'sd13;
              16'd11: v = 32'sd51;
              16'd12: v = -32'sd32;
              16'd13: v = 32'sd31;
              16'd14: v = 32'sd38;
              16'd15: v = -32'sd27;
              16'd16: v = 32'sd47;
              16'd17: v = 32'sd42;
              16'd18: v = -32'sd14;
              16'd19: v = -32'sd35;
              16'd20: v = 32'sd41;
              16'd21: v = -32'sd41;
              16'd22: v = 32'sd37;
              16'd23: v = -32'sd3;
              16'd24: v = 32'sd37;
              16'd25: v = -32'sd58;
              16'd26: v = -32'sd26;
              16'd27: v = 32'sd28;
              16'd28: v = 32'sd33;
              16'd29: v = -32'sd63;
              16'd30: v = -32'sd44;
              16'd31: v = -32'sd55;
              16'd32: v = -32'sd56;
              16'd33: v = -32'sd36;
              16'd34: v = 32'sd30;
              16'd35: v = 32'sd8;
              16'd36: v = 32'sd30;
              16'd37: v = 32'sd53;
              16'd38: v = 32'sd25;
              16'd39: v = -32'sd44;
              16'd40: v = 32'sd28;
              16'd41: v = 32'sd18;
              16'd42: v = 32'sd59;
              16'd43: v = -32'sd71;
              16'd44: v = 32'sd57;
              16'd45: v = 32'sd47;
              16'd46: v = -32'sd28;
              16'd47: v = -32'sd15;
              16'd48: v = 32'sd55;
              16'd49: v = -32'sd50;
              16'd50: v = 32'sd33;
              16'd51: v = 32'sd30;
              16'd52: v = 32'sd30;
              16'd53: v = 32'sd36;
              16'd54: v = 32'sd42;
              16'd55: v = 32'sd46;
              16'd56: v = -32'sd6;
              16'd57: v = 32'sd42;
              16'd58: v = -32'sd50;
              16'd59: v = -32'sd27;
              16'd60: v = 32'sd5;
              16'd61: v = -32'sd19;
              16'd62: v = 32'sd66;
              16'd63: v = 32'sd6;
              16'd64: v = 32'sd35;
              16'd65: v = 32'sd35;
              16'd66: v = -32'sd44;
              16'd67: v = -32'sd24;
              16'd68: v = 32'sd13;
              16'd69: v = 32'sd7;
              16'd70: v = 32'sd44;
              16'd71: v = -32'sd36;
              16'd72: v = -32'sd26;
              16'd73: v = 32'sd25;
              16'd74: v = -32'sd31;
              16'd75: v = -32'sd53;
              16'd76: v = 32'sd40;
              16'd77: v = 32'sd55;
              16'd78: v = -32'sd13;
              16'd79: v = -32'sd8;
              16'd80: v = -32'sd33;
              16'd81: v = -32'sd36;
              16'd82: v = 32'sd30;
              16'd83: v = -32'sd30;
              16'd84: v = 32'sd25;
              16'd85: v = -32'sd60;
              16'd86: v = -32'sd26;
              16'd87: v = -32'sd14;
              16'd88: v = 32'sd12;
              16'd89: v = 32'sd62;
              16'd90: v = 32'sd28;
              16'd91: v = 32'sd5;
              16'd92: v = -32'sd41;
              16'd93: v = -32'sd51;
              16'd94: v = -32'sd33;
              16'd95: v = 32'sd22;
              16'd96: v = 32'sd45;
              16'd97: v = -32'sd15;
              16'd98: v = -32'sd10;
              16'd99: v = -32'sd40;
              16'd100: v = 32'sd16;
              16'd101: v = 32'sd43;
              16'd102: v = -32'sd41;
              16'd103: v = -32'sd51;
              16'd104: v = 32'sd62;
              16'd105: v = -32'sd1;
              16'd106: v = 32'sd14;
              16'd107: v = -32'sd7;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W: begin
          if (addr < BLOCKS_0_FFN_RECEPTANCE_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = -32'sd3;
              16'd2: v = -32'sd4;
              16'd3: v = 32'sd1;
              16'd4: v = 32'sd1;
              16'd5: v = -32'sd1;
              16'd6: v = -32'sd2;
              16'd7: v = -32'sd3;
              16'd8: v = -32'sd2;
              16'd9: v = -32'sd4;
              16'd10: v = 32'sd3;
              16'd11: v = 32'sd1;
              16'd12: v = -32'sd3;
              16'd13: v = -32'sd2;
              16'd14: v = 32'sd1;
              16'd15: v = -32'sd3;
              16'd16: v = 32'sd2;
              16'd17: v = 32'sd0;
              16'd18: v = -32'sd2;
              16'd19: v = 32'sd0;
              16'd20: v = -32'sd1;
              16'd21: v = 32'sd1;
              16'd22: v = -32'sd1;
              16'd23: v = 32'sd0;
              16'd24: v = 32'sd3;
              16'd25: v = -32'sd4;
              16'd26: v = 32'sd1;
              16'd27: v = 32'sd3;
              16'd28: v = 32'sd0;
              16'd29: v = 32'sd2;
              16'd30: v = 32'sd1;
              16'd31: v = 32'sd2;
              16'd32: v = -32'sd1;
              16'd33: v = 32'sd2;
              16'd34: v = 32'sd0;
              16'd35: v = 32'sd0;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_VALUE_W: begin
          if (addr < BLOCKS_0_FFN_VALUE_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd50;
              16'd1: v = -32'sd28;
              16'd2: v = 32'sd22;
              16'd3: v = 32'sd96;
              16'd4: v = -32'sd15;
              16'd5: v = 32'sd6;
              16'd6: v = 32'sd15;
              16'd7: v = 32'sd61;
              16'd8: v = 32'sd45;
              16'd9: v = -32'sd20;
              16'd10: v = -32'sd22;
              16'd11: v = 32'sd76;
              16'd12: v = -32'sd70;
              16'd13: v = 32'sd31;
              16'd14: v = -32'sd90;
              16'd15: v = -32'sd45;
              16'd16: v = -32'sd23;
              16'd17: v = 32'sd41;
              16'd18: v = 32'sd37;
              16'd19: v = -32'sd25;
              16'd20: v = -32'sd17;
              16'd21: v = 32'sd54;
              16'd22: v = 32'sd85;
              16'd23: v = -32'sd70;
              16'd24: v = -32'sd7;
              16'd25: v = 32'sd11;
              16'd26: v = 32'sd69;
              16'd27: v = 32'sd54;
              16'd28: v = 32'sd27;
              16'd29: v = 32'sd8;
              16'd30: v = -32'sd74;
              16'd31: v = 32'sd35;
              16'd32: v = -32'sd39;
              16'd33: v = 32'sd24;
              16'd34: v = 32'sd7;
              16'd35: v = 32'sd84;
              16'd36: v = 32'sd74;
              16'd37: v = -32'sd85;
              16'd38: v = 32'sd10;
              16'd39: v = 32'sd19;
              16'd40: v = 32'sd57;
              16'd41: v = -32'sd30;
              16'd42: v = 32'sd4;
              16'd43: v = -32'sd2;
              16'd44: v = -32'sd38;
              16'd45: v = 32'sd22;
              16'd46: v = 32'sd48;
              16'd47: v = 32'sd31;
              16'd48: v = 32'sd0;
              16'd49: v = -32'sd18;
              16'd50: v = -32'sd18;
              16'd51: v = -32'sd59;
              16'd52: v = -32'sd14;
              16'd53: v = 32'sd23;
              16'd54: v = 32'sd75;
              16'd55: v = 32'sd8;
              16'd56: v = 32'sd43;
              16'd57: v = 32'sd45;
              16'd58: v = 32'sd60;
              16'd59: v = -32'sd86;
              16'd60: v = -32'sd39;
              16'd61: v = 32'sd46;
              16'd62: v = 32'sd16;
              16'd63: v = -32'sd46;
              16'd64: v = 32'sd6;
              16'd65: v = 32'sd2;
              16'd66: v = -32'sd98;
              16'd67: v = 32'sd0;
              16'd68: v = 32'sd4;
              16'd69: v = -32'sd7;
              16'd70: v = -32'sd58;
              16'd71: v = -32'sd20;
              16'd72: v = -32'sd80;
              16'd73: v = 32'sd46;
              16'd74: v = 32'sd48;
              16'd75: v = -32'sd63;
              16'd76: v = -32'sd56;
              16'd77: v = -32'sd2;
              16'd78: v = -32'sd1;
              16'd79: v = -32'sd100;
              16'd80: v = -32'sd79;
              16'd81: v = 32'sd59;
              16'd82: v = -32'sd59;
              16'd83: v = -32'sd39;
              16'd84: v = 32'sd17;
              16'd85: v = -32'sd44;
              16'd86: v = 32'sd25;
              16'd87: v = 32'sd41;
              16'd88: v = -32'sd5;
              16'd89: v = -32'sd36;
              16'd90: v = 32'sd28;
              16'd91: v = -32'sd105;
              16'd92: v = 32'sd36;
              16'd93: v = 32'sd84;
              16'd94: v = 32'sd64;
              16'd95: v = -32'sd52;
              16'd96: v = 32'sd28;
              16'd97: v = -32'sd16;
              16'd98: v = 32'sd7;
              16'd99: v = -32'sd12;
              16'd100: v = 32'sd8;
              16'd101: v = 32'sd52;
              16'd102: v = -32'sd61;
              16'd103: v = -32'sd17;
              16'd104: v = -32'sd55;
              16'd105: v = -32'sd79;
              16'd106: v = -32'sd32;
              16'd107: v = -32'sd19;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W: begin
          if (addr < BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd2;
              16'd1: v = 32'sd1;
              16'd2: v = 32'sd3;
              16'd3: v = -32'sd3;
              16'd4: v = 32'sd0;
              16'd5: v = 32'sd1;
              16'd6: v = 32'sd3;
              16'd7: v = 32'sd4;
              16'd8: v = -32'sd3;
              16'd9: v = -32'sd4;
              16'd10: v = -32'sd4;
              16'd11: v = -32'sd3;
              16'd12: v = 32'sd3;
              16'd13: v = 32'sd2;
              16'd14: v = 32'sd5;
              16'd15: v = 32'sd5;
              16'd16: v = 32'sd0;
              16'd17: v = -32'sd3;
              16'd18: v = 32'sd4;
              16'd19: v = 32'sd3;
              16'd20: v = 32'sd2;
              16'd21: v = -32'sd2;
              16'd22: v = 32'sd3;
              16'd23: v = 32'sd1;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B: begin
          if (addr < BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd3;
              16'd1: v = 32'sd3;
              16'd2: v = 32'sd3;
              16'd3: v = -32'sd4;
              16'd4: v = -32'sd2;
              16'd5: v = 32'sd3;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_KEY_W: begin
          if (addr < BLOCKS_1_ATT_KEY_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = -32'sd2;
              16'd2: v = 32'sd3;
              16'd3: v = 32'sd0;
              16'd4: v = 32'sd2;
              16'd5: v = -32'sd2;
              16'd6: v = 32'sd1;
              16'd7: v = -32'sd1;
              16'd8: v = -32'sd1;
              16'd9: v = -32'sd1;
              16'd10: v = -32'sd1;
              16'd11: v = 32'sd2;
              16'd12: v = -32'sd1;
              16'd13: v = 32'sd2;
              16'd14: v = 32'sd1;
              16'd15: v = 32'sd0;
              16'd16: v = -32'sd2;
              16'd17: v = -32'sd3;
              16'd18: v = -32'sd1;
              16'd19: v = -32'sd4;
              16'd20: v = 32'sd0;
              16'd21: v = 32'sd0;
              16'd22: v = 32'sd0;
              16'd23: v = -32'sd2;
              16'd24: v = 32'sd2;
              16'd25: v = 32'sd1;
              16'd26: v = 32'sd1;
              16'd27: v = -32'sd1;
              16'd28: v = 32'sd3;
              16'd29: v = 32'sd2;
              16'd30: v = -32'sd3;
              16'd31: v = -32'sd1;
              16'd32: v = 32'sd0;
              16'd33: v = -32'sd1;
              16'd34: v = 32'sd3;
              16'd35: v = -32'sd1;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_VALUE_W: begin
          if (addr < BLOCKS_1_ATT_VALUE_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd102;
              16'd1: v = 32'sd12;
              16'd2: v = 32'sd11;
              16'd3: v = -32'sd42;
              16'd4: v = -32'sd22;
              16'd5: v = 32'sd17;
              16'd6: v = 32'sd45;
              16'd7: v = -32'sd3;
              16'd8: v = 32'sd82;
              16'd9: v = -32'sd75;
              16'd10: v = 32'sd35;
              16'd11: v = 32'sd100;
              16'd12: v = -32'sd28;
              16'd13: v = 32'sd93;
              16'd14: v = -32'sd34;
              16'd15: v = -32'sd93;
              16'd16: v = -32'sd77;
              16'd17: v = 32'sd63;
              16'd18: v = -32'sd26;
              16'd19: v = 32'sd34;
              16'd20: v = 32'sd119;
              16'd21: v = 32'sd39;
              16'd22: v = -32'sd1;
              16'd23: v = 32'sd9;
              16'd24: v = -32'sd88;
              16'd25: v = -32'sd65;
              16'd26: v = -32'sd107;
              16'd27: v = -32'sd91;
              16'd28: v = 32'sd3;
              16'd29: v = 32'sd48;
              16'd30: v = -32'sd33;
              16'd31: v = -32'sd90;
              16'd32: v = 32'sd40;
              16'd33: v = -32'sd61;
              16'd34: v = -32'sd36;
              16'd35: v = -32'sd74;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W: begin
          if (addr < BLOCKS_1_ATT_RECEPTANCE_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd2;
              16'd1: v = 32'sd2;
              16'd2: v = -32'sd4;
              16'd3: v = -32'sd3;
              16'd4: v = 32'sd2;
              16'd5: v = -32'sd1;
              16'd6: v = -32'sd1;
              16'd7: v = -32'sd1;
              16'd8: v = 32'sd1;
              16'd9: v = -32'sd2;
              16'd10: v = 32'sd0;
              16'd11: v = 32'sd2;
              16'd12: v = 32'sd1;
              16'd13: v = 32'sd2;
              16'd14: v = -32'sd4;
              16'd15: v = 32'sd1;
              16'd16: v = 32'sd0;
              16'd17: v = 32'sd1;
              16'd18: v = -32'sd3;
              16'd19: v = 32'sd2;
              16'd20: v = 32'sd2;
              16'd21: v = -32'sd1;
              16'd22: v = 32'sd1;
              16'd23: v = 32'sd2;
              16'd24: v = -32'sd1;
              16'd25: v = -32'sd1;
              16'd26: v = 32'sd4;
              16'd27: v = 32'sd0;
              16'd28: v = -32'sd2;
              16'd29: v = -32'sd1;
              16'd30: v = 32'sd1;
              16'd31: v = -32'sd1;
              16'd32: v = -32'sd2;
              16'd33: v = 32'sd2;
              16'd34: v = 32'sd1;
              16'd35: v = 32'sd0;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_OUTPUT_W: begin
          if (addr < BLOCKS_1_ATT_OUTPUT_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd1;
              16'd1: v = -32'sd18;
              16'd2: v = 32'sd34;
              16'd3: v = -32'sd16;
              16'd4: v = -32'sd77;
              16'd5: v = 32'sd4;
              16'd6: v = -32'sd21;
              16'd7: v = 32'sd10;
              16'd8: v = -32'sd9;
              16'd9: v = 32'sd25;
              16'd10: v = -32'sd102;
              16'd11: v = 32'sd24;
              16'd12: v = 32'sd46;
              16'd13: v = -32'sd2;
              16'd14: v = -32'sd59;
              16'd15: v = 32'sd5;
              16'd16: v = -32'sd25;
              16'd17: v = -32'sd74;
              16'd18: v = -32'sd86;
              16'd19: v = 32'sd107;
              16'd20: v = 32'sd102;
              16'd21: v = 32'sd59;
              16'd22: v = 32'sd52;
              16'd23: v = 32'sd59;
              16'd24: v = 32'sd67;
              16'd25: v = 32'sd58;
              16'd26: v = -32'sd38;
              16'd27: v = -32'sd20;
              16'd28: v = 32'sd95;
              16'd29: v = -32'sd11;
              16'd30: v = -32'sd82;
              16'd31: v = -32'sd73;
              16'd32: v = 32'sd82;
              16'd33: v = 32'sd92;
              16'd34: v = 32'sd60;
              16'd35: v = 32'sd32;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W: begin
          if (addr < BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd18;
              16'd1: v = -32'sd62;
              16'd2: v = -32'sd43;
              16'd3: v = -32'sd64;
              16'd4: v = 32'sd38;
              16'd5: v = -32'sd10;
              16'd6: v = -32'sd32;
              16'd7: v = 32'sd6;
              16'd8: v = -32'sd54;
              16'd9: v = -32'sd57;
              16'd10: v = 32'sd0;
              16'd11: v = 32'sd0;
              16'd12: v = -32'sd21;
              16'd13: v = -32'sd57;
              16'd14: v = 32'sd46;
              16'd15: v = 32'sd18;
              16'd16: v = 32'sd29;
              16'd17: v = -32'sd36;
              16'd18: v = 32'sd41;
              16'd19: v = -32'sd6;
              16'd20: v = -32'sd41;
              16'd21: v = -32'sd49;
              16'd22: v = 32'sd29;
              16'd23: v = 32'sd44;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B: begin
          if (addr < BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd38;
              16'd1: v = 32'sd52;
              16'd2: v = -32'sd55;
              16'd3: v = 32'sd84;
              16'd4: v = 32'sd44;
              16'd5: v = 32'sd30;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_KEY_W: begin
          if (addr < BLOCKS_1_FFN_KEY_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd41;
              16'd2: v = -32'sd53;
              16'd3: v = 32'sd15;
              16'd4: v = -32'sd10;
              16'd5: v = 32'sd6;
              16'd6: v = 32'sd44;
              16'd7: v = -32'sd16;
              16'd8: v = -32'sd51;
              16'd9: v = -32'sd23;
              16'd10: v = -32'sd52;
              16'd11: v = 32'sd44;
              16'd12: v = -32'sd19;
              16'd13: v = -32'sd41;
              16'd14: v = 32'sd0;
              16'd15: v = -32'sd30;
              16'd16: v = -32'sd22;
              16'd17: v = 32'sd21;
              16'd18: v = -32'sd45;
              16'd19: v = 32'sd38;
              16'd20: v = 32'sd50;
              16'd21: v = 32'sd5;
              16'd22: v = 32'sd35;
              16'd23: v = -32'sd40;
              16'd24: v = 32'sd15;
              16'd25: v = 32'sd72;
              16'd26: v = -32'sd9;
              16'd27: v = 32'sd58;
              16'd28: v = -32'sd74;
              16'd29: v = 32'sd13;
              16'd30: v = -32'sd10;
              16'd31: v = -32'sd19;
              16'd32: v = 32'sd46;
              16'd33: v = -32'sd12;
              16'd34: v = -32'sd3;
              16'd35: v = -32'sd62;
              16'd36: v = 32'sd23;
              16'd37: v = -32'sd40;
              16'd38: v = -32'sd11;
              16'd39: v = 32'sd22;
              16'd40: v = 32'sd38;
              16'd41: v = 32'sd13;
              16'd42: v = -32'sd36;
              16'd43: v = -32'sd1;
              16'd44: v = 32'sd48;
              16'd45: v = 32'sd24;
              16'd46: v = 32'sd64;
              16'd47: v = 32'sd1;
              16'd48: v = 32'sd31;
              16'd49: v = -32'sd31;
              16'd50: v = 32'sd50;
              16'd51: v = -32'sd28;
              16'd52: v = -32'sd8;
              16'd53: v = -32'sd7;
              16'd54: v = -32'sd11;
              16'd55: v = 32'sd14;
              16'd56: v = 32'sd43;
              16'd57: v = -32'sd38;
              16'd58: v = 32'sd10;
              16'd59: v = -32'sd40;
              16'd60: v = 32'sd7;
              16'd61: v = 32'sd48;
              16'd62: v = 32'sd32;
              16'd63: v = 32'sd42;
              16'd64: v = 32'sd28;
              16'd65: v = -32'sd3;
              16'd66: v = 32'sd8;
              16'd67: v = -32'sd9;
              16'd68: v = 32'sd54;
              16'd69: v = 32'sd29;
              16'd70: v = -32'sd22;
              16'd71: v = 32'sd35;
              16'd72: v = -32'sd17;
              16'd73: v = 32'sd21;
              16'd74: v = 32'sd9;
              16'd75: v = 32'sd2;
              16'd76: v = 32'sd26;
              16'd77: v = -32'sd47;
              16'd78: v = -32'sd51;
              16'd79: v = -32'sd22;
              16'd80: v = -32'sd1;
              16'd81: v = 32'sd44;
              16'd82: v = 32'sd48;
              16'd83: v = -32'sd39;
              16'd84: v = -32'sd23;
              16'd85: v = 32'sd5;
              16'd86: v = -32'sd47;
              16'd87: v = 32'sd1;
              16'd88: v = -32'sd38;
              16'd89: v = 32'sd41;
              16'd90: v = -32'sd32;
              16'd91: v = -32'sd6;
              16'd92: v = -32'sd11;
              16'd93: v = -32'sd2;
              16'd94: v = 32'sd59;
              16'd95: v = -32'sd43;
              16'd96: v = -32'sd5;
              16'd97: v = 32'sd51;
              16'd98: v = 32'sd34;
              16'd99: v = -32'sd27;
              16'd100: v = -32'sd23;
              16'd101: v = -32'sd32;
              16'd102: v = -32'sd40;
              16'd103: v = 32'sd42;
              16'd104: v = -32'sd29;
              16'd105: v = 32'sd39;
              16'd106: v = -32'sd45;
              16'd107: v = -32'sd3;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W: begin
          if (addr < BLOCKS_1_FFN_RECEPTANCE_W_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd7;
              16'd1: v = 32'sd121;
              16'd2: v = 32'sd80;
              16'd3: v = 32'sd48;
              16'd4: v = 32'sd41;
              16'd5: v = -32'sd85;
              16'd6: v = 32'sd55;
              16'd7: v = -32'sd43;
              16'd8: v = -32'sd56;
              16'd9: v = -32'sd99;
              16'd10: v = -32'sd115;
              16'd11: v = 32'sd73;
              16'd12: v = -32'sd14;
              16'd13: v = 32'sd120;
              16'd14: v = 32'sd103;
              16'd15: v = 32'sd63;
              16'd16: v = 32'sd69;
              16'd17: v = -32'sd49;
              16'd18: v = 32'sd44;
              16'd19: v = 32'sd81;
              16'd20: v = 32'sd4;
              16'd21: v = -32'sd16;
              16'd22: v = -32'sd3;
              16'd23: v = 32'sd16;
              16'd24: v = -32'sd114;
              16'd25: v = 32'sd70;
              16'd26: v = -32'sd110;
              16'd27: v = 32'sd72;
              16'd28: v = -32'sd30;
              16'd29: v = -32'sd54;
              16'd30: v = -32'sd85;
              16'd31: v = 32'sd122;
              16'd32: v = -32'sd113;
              16'd33: v = 32'sd74;
              16'd34: v = 32'sd86;
              16'd35: v = 32'sd50;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_VALUE_W: begin
          if (addr < BLOCKS_1_FFN_VALUE_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd19;
              16'd1: v = 32'sd14;
              16'd2: v = 32'sd35;
              16'd3: v = 32'sd35;
              16'd4: v = -32'sd17;
              16'd5: v = 32'sd1;
              16'd6: v = -32'sd6;
              16'd7: v = 32'sd39;
              16'd8: v = 32'sd21;
              16'd9: v = -32'sd3;
              16'd10: v = -32'sd39;
              16'd11: v = 32'sd35;
              16'd12: v = 32'sd66;
              16'd13: v = 32'sd72;
              16'd14: v = -32'sd84;
              16'd15: v = 32'sd58;
              16'd16: v = -32'sd52;
              16'd17: v = -32'sd92;
              16'd18: v = -32'sd75;
              16'd19: v = -32'sd25;
              16'd20: v = 32'sd7;
              16'd21: v = -32'sd22;
              16'd22: v = 32'sd10;
              16'd23: v = 32'sd95;
              16'd24: v = 32'sd14;
              16'd25: v = 32'sd80;
              16'd26: v = -32'sd14;
              16'd27: v = -32'sd5;
              16'd28: v = 32'sd14;
              16'd29: v = 32'sd34;
              16'd30: v = 32'sd1;
              16'd31: v = -32'sd27;
              16'd32: v = -32'sd9;
              16'd33: v = 32'sd46;
              16'd34: v = 32'sd67;
              16'd35: v = -32'sd64;
              16'd36: v = -32'sd22;
              16'd37: v = -32'sd42;
              16'd38: v = 32'sd21;
              16'd39: v = 32'sd23;
              16'd40: v = 32'sd9;
              16'd41: v = 32'sd66;
              16'd42: v = 32'sd62;
              16'd43: v = 32'sd58;
              16'd44: v = 32'sd18;
              16'd45: v = 32'sd78;
              16'd46: v = -32'sd14;
              16'd47: v = 32'sd52;
              16'd48: v = 32'sd98;
              16'd49: v = 32'sd78;
              16'd50: v = -32'sd68;
              16'd51: v = -32'sd7;
              16'd52: v = 32'sd43;
              16'd53: v = -32'sd24;
              16'd54: v = -32'sd11;
              16'd55: v = 32'sd6;
              16'd56: v = 32'sd43;
              16'd57: v = 32'sd12;
              16'd58: v = -32'sd57;
              16'd59: v = 32'sd60;
              16'd60: v = 32'sd28;
              16'd61: v = -32'sd4;
              16'd62: v = 32'sd20;
              16'd63: v = -32'sd23;
              16'd64: v = 32'sd7;
              16'd65: v = -32'sd12;
              16'd66: v = 32'sd96;
              16'd67: v = -32'sd34;
              16'd68: v = -32'sd73;
              16'd69: v = -32'sd32;
              16'd70: v = 32'sd38;
              16'd71: v = -32'sd89;
              16'd72: v = 32'sd59;
              16'd73: v = -32'sd26;
              16'd74: v = -32'sd31;
              16'd75: v = -32'sd53;
              16'd76: v = 32'sd45;
              16'd77: v = 32'sd21;
              16'd78: v = 32'sd46;
              16'd79: v = -32'sd30;
              16'd80: v = -32'sd72;
              16'd81: v = -32'sd40;
              16'd82: v = -32'sd42;
              16'd83: v = -32'sd15;
              16'd84: v = -32'sd16;
              16'd85: v = 32'sd14;
              16'd86: v = 32'sd62;
              16'd87: v = -32'sd6;
              16'd88: v = -32'sd42;
              16'd89: v = 32'sd40;
              16'd90: v = -32'sd32;
              16'd91: v = -32'sd46;
              16'd92: v = -32'sd13;
              16'd93: v = 32'sd14;
              16'd94: v = -32'sd92;
              16'd95: v = 32'sd74;
              16'd96: v = 32'sd5;
              16'd97: v = -32'sd27;
              16'd98: v = 32'sd61;
              16'd99: v = -32'sd12;
              16'd100: v = 32'sd40;
              16'd101: v = 32'sd60;
              16'd102: v = 32'sd41;
              16'd103: v = 32'sd34;
              16'd104: v = -32'sd11;
              16'd105: v = 32'sd68;
              16'd106: v = 32'sd0;
              16'd107: v = -32'sd75;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_OUTPUT_PROJ_W: begin
          if (addr < OUTPUT_PROJ_W_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd15;
              16'd1: v = -32'sd44;
              16'd2: v = -32'sd55;
              16'd3: v = -32'sd56;
              16'd4: v = 32'sd48;
              16'd5: v = -32'sd56;
              16'd6: v = -32'sd92;
              16'd7: v = -32'sd46;
              16'd8: v = 32'sd56;
              16'd9: v = -32'sd4;
              16'd10: v = -32'sd21;
              16'd11: v = 32'sd34;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_OUTPUT_PROJ_B: begin
          if (addr < OUTPUT_PROJ_B_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd3;
              16'd1: v = 32'sd4;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_K: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_K_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd73;
              16'd2: v = 32'sd97;
              16'd3: v = 32'sd152;
              16'd4: v = 32'sd217;
              16'd5: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_V: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_V_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd40;
              16'd2: v = 32'sd133;
              16'd3: v = 32'sd159;
              16'd4: v = 32'sd182;
              16'd5: v = 32'sd227;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_R: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_R_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd141;
              16'd2: v = 32'sd194;
              16'd3: v = 32'sd216;
              16'd4: v = 32'sd218;
              16'd5: v = 32'sd228;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_ONE_TM: begin
          if (addr < BLOCKS_0_ATT_ONE_TM_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_TIME_MIX_K: begin
          if (addr < BLOCKS_0_FFN_TIME_MIX_K_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd26;
              16'd2: v = 32'sd129;
              16'd3: v = 32'sd183;
              16'd4: v = 32'sd158;
              16'd5: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_TIME_MIX_R: begin
          if (addr < BLOCKS_0_FFN_TIME_MIX_R_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd42;
              16'd2: v = 32'sd77;
              16'd3: v = 32'sd186;
              16'd4: v = 32'sd160;
              16'd5: v = 32'sd246;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_FFN_ONE_TM: begin
          if (addr < BLOCKS_0_FFN_ONE_TM_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_K: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_K_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd8;
              16'd1: v = 32'sd104;
              16'd2: v = 32'sd154;
              16'd3: v = 32'sd173;
              16'd4: v = 32'sd254;
              16'd5: v = 32'sd226;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_V: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_V_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd55;
              16'd1: v = 32'sd163;
              16'd2: v = 32'sd212;
              16'd3: v = 32'sd255;
              16'd4: v = 32'sd255;
              16'd5: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_R: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_R_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd12;
              16'd1: v = 32'sd205;
              16'd2: v = 32'sd236;
              16'd3: v = 32'sd250;
              16'd4: v = 32'sd220;
              16'd5: v = 32'sd247;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_ONE_TM: begin
          if (addr < BLOCKS_1_ATT_ONE_TM_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_TIME_MIX_K: begin
          if (addr < BLOCKS_1_FFN_TIME_MIX_K_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd103;
              16'd2: v = 32'sd179;
              16'd3: v = 32'sd153;
              16'd4: v = 32'sd255;
              16'd5: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_TIME_MIX_R: begin
          if (addr < BLOCKS_1_FFN_TIME_MIX_R_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd71;
              16'd2: v = 32'sd173;
              16'd3: v = 32'sd158;
              16'd4: v = 32'sd217;
              16'd5: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_FFN_ONE_TM: begin
          if (addr < BLOCKS_1_FFN_ONE_TM_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd255;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_WKV_LUT: begin
          if (addr < WKV_LUT_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd0;
              16'd2: v = 32'sd0;
              16'd3: v = 32'sd0;
              16'd4: v = 32'sd0;
              16'd5: v = 32'sd1;
              16'd6: v = 32'sd1;
              16'd7: v = 32'sd1;
              16'd8: v = 32'sd1;
              16'd9: v = 32'sd1;
              16'd10: v = 32'sd1;
              16'd11: v = 32'sd1;
              16'd12: v = 32'sd1;
              16'd13: v = 32'sd1;
              16'd14: v = 32'sd1;
              16'd15: v = 32'sd1;
              16'd16: v = 32'sd1;
              16'd17: v = 32'sd1;
              16'd18: v = 32'sd1;
              16'd19: v = 32'sd1;
              16'd20: v = 32'sd1;
              16'd21: v = 32'sd1;
              16'd22: v = 32'sd1;
              16'd23: v = 32'sd1;
              16'd24: v = 32'sd1;
              16'd25: v = 32'sd1;
              16'd26: v = 32'sd1;
              16'd27: v = 32'sd1;
              16'd28: v = 32'sd2;
              16'd29: v = 32'sd2;
              16'd30: v = 32'sd2;
              16'd31: v = 32'sd2;
              16'd32: v = 32'sd2;
              16'd33: v = 32'sd2;
              16'd34: v = 32'sd2;
              16'd35: v = 32'sd2;
              16'd36: v = 32'sd2;
              16'd37: v = 32'sd2;
              16'd38: v = 32'sd2;
              16'd39: v = 32'sd3;
              16'd40: v = 32'sd3;
              16'd41: v = 32'sd3;
              16'd42: v = 32'sd3;
              16'd43: v = 32'sd3;
              16'd44: v = 32'sd3;
              16'd45: v = 32'sd3;
              16'd46: v = 32'sd4;
              16'd47: v = 32'sd4;
              16'd48: v = 32'sd4;
              16'd49: v = 32'sd4;
              16'd50: v = 32'sd4;
              16'd51: v = 32'sd4;
              16'd52: v = 32'sd5;
              16'd53: v = 32'sd5;
              16'd54: v = 32'sd5;
              16'd55: v = 32'sd5;
              16'd56: v = 32'sd6;
              16'd57: v = 32'sd6;
              16'd58: v = 32'sd6;
              16'd59: v = 32'sd6;
              16'd60: v = 32'sd7;
              16'd61: v = 32'sd7;
              16'd62: v = 32'sd7;
              16'd63: v = 32'sd8;
              16'd64: v = 32'sd8;
              16'd65: v = 32'sd9;
              16'd66: v = 32'sd9;
              16'd67: v = 32'sd9;
              16'd68: v = 32'sd10;
              16'd69: v = 32'sd10;
              16'd70: v = 32'sd11;
              16'd71: v = 32'sd11;
              16'd72: v = 32'sd12;
              16'd73: v = 32'sd12;
              16'd74: v = 32'sd13;
              16'd75: v = 32'sd14;
              16'd76: v = 32'sd14;
              16'd77: v = 32'sd15;
              16'd78: v = 32'sd16;
              16'd79: v = 32'sd17;
              16'd80: v = 32'sd17;
              16'd81: v = 32'sd18;
              16'd82: v = 32'sd19;
              16'd83: v = 32'sd20;
              16'd84: v = 32'sd21;
              16'd85: v = 32'sd22;
              16'd86: v = 32'sd23;
              16'd87: v = 32'sd24;
              16'd88: v = 32'sd25;
              16'd89: v = 32'sd27;
              16'd90: v = 32'sd28;
              16'd91: v = 32'sd29;
              16'd92: v = 32'sd31;
              16'd93: v = 32'sd32;
              16'd94: v = 32'sd34;
              16'd95: v = 32'sd35;
              16'd96: v = 32'sd37;
              16'd97: v = 32'sd39;
              16'd98: v = 32'sd41;
              16'd99: v = 32'sd42;
              16'd100: v = 32'sd45;
              16'd101: v = 32'sd47;
              16'd102: v = 32'sd49;
              16'd103: v = 32'sd51;
              16'd104: v = 32'sd54;
              16'd105: v = 32'sd56;
              16'd106: v = 32'sd59;
              16'd107: v = 32'sd62;
              16'd108: v = 32'sd65;
              16'd109: v = 32'sd68;
              16'd110: v = 32'sd71;
              16'd111: v = 32'sd75;
              16'd112: v = 32'sd78;
              16'd113: v = 32'sd82;
              16'd114: v = 32'sd86;
              16'd115: v = 32'sd90;
              16'd116: v = 32'sd95;
              16'd117: v = 32'sd99;
              16'd118: v = 32'sd104;
              16'd119: v = 32'sd109;
              16'd120: v = 32'sd114;
              16'd121: v = 32'sd120;
              16'd122: v = 32'sd125;
              16'd123: v = 32'sd131;
              16'd124: v = 32'sd138;
              16'd125: v = 32'sd144;
              16'd126: v = 32'sd151;
              16'd127: v = 32'sd159;
              16'd128: v = 32'sd166;
              16'd129: v = 32'sd174;
              16'd130: v = 32'sd183;
              16'd131: v = 32'sd192;
              16'd132: v = 32'sd201;
              16'd133: v = 32'sd210;
              16'd134: v = 32'sd221;
              16'd135: v = 32'sd231;
              16'd136: v = 32'sd242;
              16'd137: v = 32'sd254;
              16'd138: v = 32'sd266;
              16'd139: v = 32'sd279;
              16'd140: v = 32'sd293;
              16'd141: v = 32'sd307;
              16'd142: v = 32'sd321;
              16'd143: v = 32'sd337;
              16'd144: v = 32'sd353;
              16'd145: v = 32'sd370;
              16'd146: v = 32'sd388;
              16'd147: v = 32'sd407;
              16'd148: v = 32'sd426;
              16'd149: v = 32'sd447;
              16'd150: v = 32'sd468;
              16'd151: v = 32'sd491;
              16'd152: v = 32'sd515;
              16'd153: v = 32'sd539;
              16'd154: v = 32'sd565;
              16'd155: v = 32'sd593;
              16'd156: v = 32'sd621;
              16'd157: v = 32'sd651;
              16'd158: v = 32'sd682;
              16'd159: v = 32'sd715;
              16'd160: v = 32'sd750;
              16'd161: v = 32'sd786;
              16'd162: v = 32'sd824;
              16'd163: v = 32'sd863;
              16'd164: v = 32'sd905;
              16'd165: v = 32'sd949;
              16'd166: v = 32'sd994;
              16'd167: v = 32'sd1042;
              16'd168: v = 32'sd1092;
              16'd169: v = 32'sd1145;
              16'd170: v = 32'sd1200;
              16'd171: v = 32'sd1258;
              16'd172: v = 32'sd1319;
              16'd173: v = 32'sd1382;
              16'd174: v = 32'sd1449;
              16'd175: v = 32'sd1519;
              16'd176: v = 32'sd1592;
              16'd177: v = 32'sd1669;
              16'd178: v = 32'sd1749;
              16'd179: v = 32'sd1833;
              16'd180: v = 32'sd1922;
              16'd181: v = 32'sd2014;
              16'd182: v = 32'sd2111;
              16'd183: v = 32'sd2213;
              16'd184: v = 32'sd2320;
              16'd185: v = 32'sd2431;
              16'd186: v = 32'sd2549;
              16'd187: v = 32'sd2671;
              16'd188: v = 32'sd2800;
              16'd189: v = 32'sd2935;
              16'd190: v = 32'sd3076;
              16'd191: v = 32'sd3225;
              16'd192: v = 32'sd3380;
              16'd193: v = 32'sd3543;
              16'd194: v = 32'sd3714;
              16'd195: v = 32'sd3893;
              16'd196: v = 32'sd4080;
              16'd197: v = 32'sd4277;
              16'd198: v = 32'sd4483;
              16'd199: v = 32'sd4699;
              16'd200: v = 32'sd4925;
              16'd201: v = 32'sd5162;
              16'd202: v = 32'sd5411;
              16'd203: v = 32'sd5672;
              16'd204: v = 32'sd5945;
              16'd205: v = 32'sd6232;
              16'd206: v = 32'sd6532;
              16'd207: v = 32'sd6847;
              16'd208: v = 32'sd7177;
              16'd209: v = 32'sd7522;
              16'd210: v = 32'sd7885;
              16'd211: v = 32'sd8265;
              16'd212: v = 32'sd8663;
              16'd213: v = 32'sd9080;
              16'd214: v = 32'sd9518;
              16'd215: v = 32'sd9976;
              16'd216: v = 32'sd10457;
              16'd217: v = 32'sd10961;
              16'd218: v = 32'sd11489;
              16'd219: v = 32'sd12043;
              16'd220: v = 32'sd12623;
              16'd221: v = 32'sd13231;
              16'd222: v = 32'sd13869;
              16'd223: v = 32'sd14537;
              16'd224: v = 32'sd15238;
              16'd225: v = 32'sd15972;
              16'd226: v = 32'sd16741;
              16'd227: v = 32'sd17548;
              16'd228: v = 32'sd18393;
              16'd229: v = 32'sd19280;
              16'd230: v = 32'sd20209;
              16'd231: v = 32'sd21182;
              16'd232: v = 32'sd22203;
              16'd233: v = 32'sd23273;
              16'd234: v = 32'sd24394;
              16'd235: v = 32'sd25570;
              16'd236: v = 32'sd26802;
              16'd237: v = 32'sd28093;
              16'd238: v = 32'sd29447;
              16'd239: v = 32'sd30866;
              16'd240: v = 32'sd32353;
              16'd241: v = 32'sd33912;
              16'd242: v = 32'sd35546;
              16'd243: v = 32'sd37258;
              16'd244: v = 32'sd39054;
              16'd245: v = 32'sd40935;
              16'd246: v = 32'sd42908;
              16'd247: v = 32'sd44975;
              16'd248: v = 32'sd47142;
              16'd249: v = 32'sd49414;
              16'd250: v = 32'sd51795;
              16'd251: v = 32'sd54290;
              16'd252: v = 32'sd56906;
              16'd253: v = 32'sd59648;
              16'd254: v = 32'sd62522;
              16'd255: v = 32'sd65535;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_WKV_MIN_DELTA_I: begin
          if (addr < WKV_MIN_DELTA_I_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd48;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_WKV_STEP_I: begin
          if (addr < WKV_STEP_I_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd1;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_WKV_E_FRAC: begin
          if (addr < WKV_E_FRAC_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd16;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_WKV_LOG_EXP: begin
          if (addr < WKV_LOG_EXP_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd2;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_FIRST: begin
          if (addr < BLOCKS_0_ATT_TIME_FIRST_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd4;
              16'd1: v = -32'sd3;
              16'd2: v = -32'sd6;
              16'd3: v = -32'sd5;
              16'd4: v = -32'sd3;
              16'd5: v = -32'sd6;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP: begin
          if (addr < BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd0;
              16'd2: v = -32'sd2;
              16'd3: v = -32'sd8;
              16'd4: v = -32'sd27;
              16'd5: v = -32'sd80;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_FIRST: begin
          if (addr < BLOCKS_1_ATT_TIME_FIRST_NUMEL) begin
            case (addr)
              16'd0: v = -32'sd5;
              16'd1: v = -32'sd3;
              16'd2: v = -32'sd7;
              16'd3: v = -32'sd4;
              16'd4: v = -32'sd2;
              16'd5: v = -32'sd7;
              default: v = 32'sd0;
            endcase
          end
        end
        ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP: begin
          if (addr < BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL) begin
            case (addr)
              16'd0: v = 32'sd0;
              16'd1: v = 32'sd0;
              16'd2: v = 32'sd0;
              16'd3: v = -32'sd1;
              16'd4: v = -32'sd5;
              16'd5: v = -32'sd80;
              default: v = 32'sd0;
            endcase
          end
        end
        default: begin
          v = 32'sd0;
        end
      endcase
      rom_read = v;
    end
  endfunction

endpackage
