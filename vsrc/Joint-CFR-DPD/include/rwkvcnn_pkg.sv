package rwkvcnn_pkg;

  // Auto-generated from vsrc/rom/manifest.json and vsrc/rom/bin/*.bin
  localparam string MANIFEST_GENERATED_AT = "2026-03-02T02:46:55.537749+00:00";

  localparam int IN_DIM = 2;
  localparam int MODEL_DIM = 6;
  localparam int LAYER_NUM = 2;
  localparam int OUT_DIM = 2;
  localparam int KERNEL_SIZE = 4;
  localparam int HIDDEN_SZ = 18;

  localparam int RES_EXP = -6;
  localparam int RES_BITS = 8;
  localparam int GATE_BITS = 8;
  localparam int K_BITS = 8;
  localparam int V_BITS = 8;
  localparam int R_BITS = 8;
  localparam int EXP_V = -7;
  localparam int EXP_R = -7;
  localparam int EXP_MUL = -6;
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
  localparam logic signed [31:0] INPUT_PROJ_W_FLAT [0:11] = '{
    32'sd-330, 32'sd-628, 32'sd367, 32'sd-404, 32'sd-1039, 32'sd1116, 32'sd-1258, 32'sd-955,
    32'sd-439, 32'sd7, 32'sd472, 32'sd-241
  };

  localparam int ROM_ID_INPUT_PROJ_B = 1;
  localparam int INPUT_PROJ_B_NUMEL = 6;
  localparam int INPUT_PROJ_B_EXP = -10;
  localparam int INPUT_PROJ_B_LOGICAL_BITS = 20;
  localparam bit INPUT_PROJ_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] INPUT_PROJ_B_FLAT [0:5] = '{
    32'sd-6, 32'sd-14, 32'sd-28, 32'sd5, 32'sd2, 32'sd-40
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W = 2;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_EXP = -7;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_SHIFT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_SHIFT_W_FLAT [0:23] = '{
    32'sd-1, 32'sd7, 32'sd25, 32'sd-60, 32'sd-22, 32'sd37, 32'sd76, 32'sd6,
    32'sd-60, 32'sd13, 32'sd48, 32'sd-19, 32'sd-32, 32'sd31, 32'sd-8, 32'sd-70,
    32'sd-52, 32'sd3, 32'sd-40, 32'sd42, 32'sd61, 32'sd31, 32'sd23, 32'sd5
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B = 3;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_EXP = -7;
  localparam int BLOCKS_0_ATT_TIME_SHIFT_B_LOGICAL_BITS = 16;
  localparam bit BLOCKS_0_ATT_TIME_SHIFT_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_SHIFT_B_FLAT [0:5] = '{
    32'sd-2, 32'sd8, 32'sd-59, 32'sd-9, 32'sd-58, 32'sd30
  };

  localparam int ROM_ID_BLOCKS_0_ATT_KEY_W = 4;
  localparam int BLOCKS_0_ATT_KEY_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_KEY_W_EXP = -3;
  localparam int BLOCKS_0_ATT_KEY_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_ATT_KEY_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_KEY_W_FLAT [0:35] = '{
    32'sd-2, 32'sd3, 32'sd-1, 32'sd-2, 32'sd1, 32'sd1, 32'sd2, 32'sd1,
    32'sd-3, 32'sd2, 32'sd0, 32'sd-2, 32'sd2, 32'sd3, 32'sd-4, 32'sd-1,
    32'sd2, 32'sd2, 32'sd2, 32'sd-1, 32'sd-2, 32'sd3, 32'sd2, 32'sd3,
    32'sd-1, 32'sd-4, 32'sd2, 32'sd-3, 32'sd2, 32'sd2, 32'sd1, 32'sd0,
    32'sd2, 32'sd-1, 32'sd4, 32'sd-4
  };

  localparam int ROM_ID_BLOCKS_0_ATT_VALUE_W = 5;
  localparam int BLOCKS_0_ATT_VALUE_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_VALUE_W_EXP = -8;
  localparam int BLOCKS_0_ATT_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_VALUE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_VALUE_W_FLAT [0:35] = '{
    32'sd-119, 32'sd-21, 32'sd95, 32'sd29, 32'sd49, 32'sd-74, 32'sd64, 32'sd-1,
    32'sd33, 32'sd58, 32'sd38, 32'sd-12, 32'sd2, 32'sd-57, 32'sd-55, 32'sd45,
    32'sd-63, 32'sd81, 32'sd-34, 32'sd-67, 32'sd-6, 32'sd-104, 32'sd-2, 32'sd-6,
    32'sd9, 32'sd-65, 32'sd83, 32'sd63, 32'sd-74, 32'sd57, 32'sd-102, 32'sd-37,
    32'sd-8, 32'sd5, 32'sd-107, 32'sd-57
  };

  localparam int ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W = 6;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_0_ATT_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_ATT_RECEPTANCE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_RECEPTANCE_W_FLAT [0:35] = '{
    32'sd-2, 32'sd2, 32'sd-4, 32'sd-4, 32'sd0, 32'sd-2, 32'sd-3, 32'sd-2,
    32'sd0, 32'sd-2, 32'sd-2, 32'sd0, 32'sd-4, 32'sd0, 32'sd-3, 32'sd-2,
    32'sd1, 32'sd-2, 32'sd-3, 32'sd3, 32'sd-1, 32'sd2, 32'sd-2, 32'sd0,
    32'sd-1, 32'sd0, 32'sd4, 32'sd-3, 32'sd1, 32'sd0, 32'sd-1, 32'sd-2,
    32'sd2, 32'sd-4, 32'sd1, 32'sd-3
  };

  localparam int ROM_ID_BLOCKS_0_ATT_OUTPUT_W = 7;
  localparam int BLOCKS_0_ATT_OUTPUT_W_NUMEL = 36;
  localparam int BLOCKS_0_ATT_OUTPUT_W_EXP = -8;
  localparam int BLOCKS_0_ATT_OUTPUT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_OUTPUT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_OUTPUT_W_FLAT [0:35] = '{
    32'sd51, 32'sd-83, 32'sd86, 32'sd-111, 32'sd-97, 32'sd10, 32'sd87, 32'sd-79,
    32'sd-51, 32'sd75, 32'sd-43, 32'sd58, 32'sd-103, 32'sd-32, 32'sd-59, 32'sd68,
    32'sd13, 32'sd-56, 32'sd14, 32'sd3, 32'sd-49, 32'sd-77, 32'sd-64, 32'sd99,
    32'sd-80, 32'sd-81, 32'sd-14, 32'sd25, 32'sd55, 32'sd-11, 32'sd-8, 32'sd-49,
    32'sd-44, 32'sd-70, 32'sd55, 32'sd-85
  };

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W = 8;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_EXP = -3;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_FFN_TIME_SHIFT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_FFN_TIME_SHIFT_W_FLAT [0:23] = '{
    32'sd-3, 32'sd-4, 32'sd-2, 32'sd2, 32'sd4, 32'sd-4, 32'sd-1, 32'sd3,
    32'sd1, 32'sd4, 32'sd1, 32'sd-3, 32'sd3, 32'sd-1, 32'sd3, 32'sd0,
    32'sd2, 32'sd3, 32'sd3, 32'sd-3, 32'sd-3, 32'sd-3, 32'sd-4, 32'sd4
  };

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B = 9;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_EXP = -3;
  localparam int BLOCKS_0_FFN_TIME_SHIFT_B_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_FFN_TIME_SHIFT_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_FFN_TIME_SHIFT_B_FLAT [0:5] = '{
    32'sd1, 32'sd-4, 32'sd-3, 32'sd-2, 32'sd3, 32'sd-5
  };

  localparam int ROM_ID_BLOCKS_0_FFN_KEY_W = 10;
  localparam int BLOCKS_0_FFN_KEY_W_NUMEL = 108;
  localparam int BLOCKS_0_FFN_KEY_W_EXP = -7;
  localparam int BLOCKS_0_FFN_KEY_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_KEY_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_FFN_KEY_W_FLAT [0:107] = '{
    32'sd-46, 32'sd-63, 32'sd31, 32'sd29, 32'sd-20, 32'sd0, 32'sd53, 32'sd-14,
    32'sd-30, 32'sd-1, 32'sd-17, 32'sd45, 32'sd-32, 32'sd31, 32'sd33, 32'sd-27,
    32'sd47, 32'sd47, 32'sd-10, 32'sd-34, 32'sd27, 32'sd-33, 32'sd34, 32'sd-1,
    32'sd40, 32'sd-64, 32'sd-41, 32'sd16, 32'sd34, 32'sd-66, 32'sd-8, 32'sd-51,
    32'sd-38, 32'sd-30, 32'sd43, 32'sd-11, 32'sd29, 32'sd31, 32'sd29, 32'sd-63,
    32'sd14, 32'sd26, 32'sd46, 32'sd-55, 32'sd7, 32'sd42, 32'sd-55, 32'sd23,
    32'sd45, 32'sd-37, 32'sd10, 32'sd24, 32'sd12, 32'sd53, 32'sd32, 32'sd25,
    32'sd-45, 32'sd65, 32'sd-46, 32'sd-14, 32'sd13, 32'sd-25, 32'sd60, 32'sd26,
    32'sd40, 32'sd25, 32'sd-29, 32'sd-25, 32'sd-1, 32'sd12, 32'sd41, 32'sd-37,
    32'sd-27, 32'sd25, 32'sd-27, 32'sd-50, 32'sd27, 32'sd41, 32'sd8, 32'sd-35,
    32'sd-31, 32'sd-43, 32'sd39, 32'sd-42, 32'sd36, 32'sd-49, 32'sd-12, 32'sd-15,
    32'sd5, 32'sd65, 32'sd40, 32'sd7, 32'sd-36, 32'sd-44, 32'sd-58, 32'sd17,
    32'sd56, 32'sd-9, 32'sd1, 32'sd-34, 32'sd12, 32'sd38, 32'sd-45, 32'sd-27,
    32'sd46, 32'sd13, 32'sd-10, 32'sd15
  };

  localparam int ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W = 11;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_0_FFN_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_0_FFN_RECEPTANCE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_FFN_RECEPTANCE_W_FLAT [0:35] = '{
    32'sd2, 32'sd-4, 32'sd-3, 32'sd2, 32'sd1, 32'sd-3, 32'sd1, 32'sd-3,
    32'sd-1, 32'sd-3, 32'sd3, 32'sd0, 32'sd-1, 32'sd-2, 32'sd2, 32'sd-2,
    32'sd1, 32'sd0, 32'sd0, 32'sd0, 32'sd0, 32'sd1, 32'sd-1, 32'sd-1,
    32'sd3, 32'sd-4, 32'sd0, 32'sd3, 32'sd-1, 32'sd2, 32'sd4, 32'sd2,
    32'sd-1, 32'sd2, 32'sd0, 32'sd-1
  };

  localparam int ROM_ID_BLOCKS_0_FFN_VALUE_W = 12;
  localparam int BLOCKS_0_FFN_VALUE_W_NUMEL = 108;
  localparam int BLOCKS_0_FFN_VALUE_W_EXP = -8;
  localparam int BLOCKS_0_FFN_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_VALUE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_FFN_VALUE_W_FLAT [0:107] = '{
    32'sd29, 32'sd-18, 32'sd25, 32'sd50, 32'sd0, 32'sd62, 32'sd-27, 32'sd43,
    32'sd15, 32'sd20, 32'sd-45, 32'sd68, 32'sd-54, 32'sd68, 32'sd-86, 32'sd-37,
    32'sd-19, 32'sd15, 32'sd20, 32'sd-14, 32'sd-15, 32'sd13, 32'sd91, 32'sd-17,
    32'sd-32, 32'sd-15, 32'sd33, 32'sd72, 32'sd12, 32'sd-3, 32'sd-59, 32'sd70,
    32'sd-29, 32'sd33, 32'sd20, 32'sd62, 32'sd67, 32'sd-62, 32'sd7, 32'sd-7,
    32'sd54, 32'sd8, 32'sd2, 32'sd-35, 32'sd-67, 32'sd0, 32'sd58, 32'sd18,
    32'sd15, 32'sd1, 32'sd-1, 32'sd-46, 32'sd1, 32'sd-4, 32'sd56, 32'sd22,
    32'sd43, 32'sd15, 32'sd64, 32'sd-44, 32'sd-56, 32'sd18, 32'sd-18, 32'sd-50,
    32'sd-2, 32'sd-13, 32'sd-83, 32'sd36, 32'sd16, 32'sd5, 32'sd-43, 32'sd-45,
    32'sd-68, 32'sd31, 32'sd50, 32'sd-36, 32'sd-64, 32'sd-60, 32'sd7, 32'sd-53,
    32'sd-32, 32'sd126, 32'sd-41, 32'sd-30, 32'sd4, 32'sd-91, 32'sd12, 32'sd35,
    32'sd-11, 32'sd-11, 32'sd22, 32'sd-92, 32'sd34, 32'sd61, 32'sd74, 32'sd6,
    32'sd19, 32'sd-57, 32'sd-35, 32'sd-4, 32'sd-7, 32'sd47, 32'sd-47, 32'sd32,
    32'sd-43, 32'sd-74, 32'sd-27, 32'sd-42
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W = 13;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_EXP = -3;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_TIME_SHIFT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_SHIFT_W_FLAT [0:23] = '{
    32'sd2, 32'sd2, 32'sd4, 32'sd-2, 32'sd0, 32'sd0, 32'sd3, 32'sd3,
    32'sd-1, 32'sd-4, 32'sd-5, 32'sd-3, 32'sd4, 32'sd2, 32'sd5, 32'sd4,
    32'sd0, 32'sd-2, 32'sd4, 32'sd4, 32'sd2, 32'sd-1, 32'sd4, 32'sd1
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B = 14;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_EXP = -3;
  localparam int BLOCKS_1_ATT_TIME_SHIFT_B_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_SHIFT_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_SHIFT_B_FLAT [0:5] = '{
    32'sd3, 32'sd2, 32'sd2, 32'sd-4, 32'sd-2, 32'sd2
  };

  localparam int ROM_ID_BLOCKS_1_ATT_KEY_W = 15;
  localparam int BLOCKS_1_ATT_KEY_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_KEY_W_EXP = -4;
  localparam int BLOCKS_1_ATT_KEY_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_KEY_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_KEY_W_FLAT [0:35] = '{
    32'sd-1, 32'sd-5, 32'sd5, 32'sd-1, 32'sd4, 32'sd-4, 32'sd2, 32'sd-2,
    32'sd-3, 32'sd-1, 32'sd-2, 32'sd4, 32'sd-1, 32'sd5, 32'sd2, 32'sd-1,
    32'sd-3, 32'sd-6, 32'sd-2, 32'sd-6, 32'sd-3, 32'sd-1, 32'sd-1, 32'sd-3,
    32'sd3, 32'sd3, 32'sd-1, 32'sd-4, 32'sd4, 32'sd6, 32'sd-6, 32'sd0,
    32'sd0, 32'sd-2, 32'sd5, 32'sd0
  };

  localparam int ROM_ID_BLOCKS_1_ATT_VALUE_W = 16;
  localparam int BLOCKS_1_ATT_VALUE_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_VALUE_W_EXP = -8;
  localparam int BLOCKS_1_ATT_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_VALUE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_VALUE_W_FLAT [0:35] = '{
    32'sd102, 32'sd-1, 32'sd3, 32'sd-51, 32'sd-31, 32'sd21, 32'sd45, 32'sd10,
    32'sd78, 32'sd-72, 32'sd30, 32'sd109, 32'sd-14, 32'sd95, 32'sd-31, 32'sd-62,
    32'sd-50, 32'sd58, 32'sd-48, 32'sd17, 32'sd107, 32'sd39, 32'sd1, 32'sd18,
    32'sd-67, 32'sd-76, 32'sd-92, 32'sd-92, 32'sd3, 32'sd38, 32'sd-52, 32'sd-114,
    32'sd71, 32'sd-51, 32'sd1, 32'sd-103
  };

  localparam int ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W = 17;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_EXP = -3;
  localparam int BLOCKS_1_ATT_RECEPTANCE_W_LOGICAL_BITS = 4;
  localparam bit BLOCKS_1_ATT_RECEPTANCE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_RECEPTANCE_W_FLAT [0:35] = '{
    32'sd-2, 32'sd2, 32'sd-4, 32'sd-2, 32'sd2, 32'sd-1, 32'sd-2, 32'sd-1,
    32'sd1, 32'sd-2, 32'sd0, 32'sd2, 32'sd0, 32'sd1, 32'sd-3, 32'sd1,
    32'sd1, 32'sd0, 32'sd-3, 32'sd2, 32'sd2, 32'sd-1, 32'sd1, 32'sd2,
    32'sd-1, 32'sd-1, 32'sd4, 32'sd0, 32'sd-2, 32'sd-1, 32'sd2, 32'sd-1,
    32'sd-1, 32'sd2, 32'sd2, 32'sd-1
  };

  localparam int ROM_ID_BLOCKS_1_ATT_OUTPUT_W = 18;
  localparam int BLOCKS_1_ATT_OUTPUT_W_NUMEL = 36;
  localparam int BLOCKS_1_ATT_OUTPUT_W_EXP = -8;
  localparam int BLOCKS_1_ATT_OUTPUT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_OUTPUT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_OUTPUT_W_FLAT [0:35] = '{
    32'sd11, 32'sd-50, 32'sd30, 32'sd-23, 32'sd-66, 32'sd24, 32'sd3, 32'sd-10,
    32'sd-34, 32'sd18, 32'sd-97, 32'sd49, 32'sd49, 32'sd-10, 32'sd-57, 32'sd8,
    32'sd-24, 32'sd-63, 32'sd-75, 32'sd86, 32'sd92, 32'sd54, 32'sd55, 32'sd62,
    32'sd60, 32'sd61, 32'sd-33, 32'sd-20, 32'sd93, 32'sd-25, 32'sd-74, 32'sd-75,
    32'sd68, 32'sd93, 32'sd61, 32'sd42
  };

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W = 19;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL = 24;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_EXP = -7;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_SHIFT_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_FFN_TIME_SHIFT_W_FLAT [0:23] = '{
    32'sd54, 32'sd-56, 32'sd-50, 32'sd-71, 32'sd32, 32'sd-27, 32'sd-51, 32'sd12,
    32'sd-22, 32'sd-65, 32'sd6, 32'sd8, 32'sd-53, 32'sd-47, 32'sd27, 32'sd48,
    32'sd-20, 32'sd-30, 32'sd38, 32'sd6, 32'sd-94, 32'sd-27, 32'sd43, 32'sd49
  };

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B = 20;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_EXP = -7;
  localparam int BLOCKS_1_FFN_TIME_SHIFT_B_LOGICAL_BITS = 16;
  localparam bit BLOCKS_1_FFN_TIME_SHIFT_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_FFN_TIME_SHIFT_B_FLAT [0:5] = '{
    32'sd-42, 32'sd73, 32'sd-60, 32'sd54, 32'sd53, 32'sd29
  };

  localparam int ROM_ID_BLOCKS_1_FFN_KEY_W = 21;
  localparam int BLOCKS_1_FFN_KEY_W_NUMEL = 108;
  localparam int BLOCKS_1_FFN_KEY_W_EXP = -7;
  localparam int BLOCKS_1_FFN_KEY_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_KEY_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_FFN_KEY_W_FLAT [0:107] = '{
    32'sd0, 32'sd62, 32'sd-52, 32'sd-23, 32'sd-30, 32'sd3, 32'sd44, 32'sd-2,
    32'sd-60, 32'sd-35, 32'sd-66, 32'sd52, 32'sd-18, 32'sd-44, 32'sd1, 32'sd-26,
    32'sd-19, 32'sd21, 32'sd-41, 32'sd42, 32'sd41, 32'sd2, 32'sd39, 32'sd-45,
    32'sd46, 32'sd73, 32'sd24, 32'sd50, 32'sd-19, 32'sd-38, 32'sd2, 32'sd0,
    32'sd40, 32'sd-12, 32'sd-2, 32'sd-63, 32'sd24, 32'sd-44, 32'sd-8, 32'sd20,
    32'sd36, 32'sd14, 32'sd-23, 32'sd-5, 32'sd34, 32'sd20, 32'sd65, 32'sd5,
    32'sd53, 32'sd-31, 32'sd55, 32'sd-18, 32'sd5, 32'sd-16, 32'sd-10, 32'sd23,
    32'sd48, 32'sd-37, 32'sd18, 32'sd-47, 32'sd12, 32'sd36, 32'sd39, 32'sd43,
    32'sd24, 32'sd-5, 32'sd13, 32'sd-15, 32'sd55, 32'sd34, 32'sd-9, 32'sd29,
    32'sd-18, 32'sd35, 32'sd7, 32'sd-9, 32'sd45, 32'sd-71, 32'sd-50, 32'sd-29,
    32'sd-14, 32'sd48, 32'sd52, 32'sd-38, 32'sd-22, 32'sd16, 32'sd-42, 32'sd-30,
    32'sd-47, 32'sd37, 32'sd-28, 32'sd6, 32'sd-24, 32'sd-4, 32'sd56, 32'sd-44,
    32'sd-35, 32'sd60, 32'sd21, 32'sd-29, 32'sd-31, 32'sd-32, 32'sd-29, 32'sd57,
    32'sd-24, 32'sd38, 32'sd-52, 32'sd-5
  };

  localparam int ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W = 22;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_NUMEL = 36;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_EXP = -7;
  localparam int BLOCKS_1_FFN_RECEPTANCE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_RECEPTANCE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_FFN_RECEPTANCE_W_FLAT [0:35] = '{
    32'sd11, 32'sd67, 32'sd63, 32'sd18, 32'sd15, 32'sd-46, 32'sd47, 32'sd-25,
    32'sd-9, 32'sd-55, 32'sd-54, 32'sd30, 32'sd3, 32'sd64, 32'sd32, 32'sd29,
    32'sd36, 32'sd-22, 32'sd43, 32'sd34, 32'sd20, 32'sd-16, 32'sd0, 32'sd5,
    32'sd-33, 32'sd25, 32'sd-41, 32'sd28, 32'sd-16, 32'sd-25, 32'sd-21, 32'sd65,
    32'sd-58, 32'sd20, 32'sd31, 32'sd43
  };

  localparam int ROM_ID_BLOCKS_1_FFN_VALUE_W = 23;
  localparam int BLOCKS_1_FFN_VALUE_W_NUMEL = 108;
  localparam int BLOCKS_1_FFN_VALUE_W_EXP = -7;
  localparam int BLOCKS_1_FFN_VALUE_W_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_VALUE_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_FFN_VALUE_W_FLAT [0:107] = '{
    32'sd-18, 32'sd10, 32'sd17, 32'sd12, 32'sd22, 32'sd-17, 32'sd-3, 32'sd8,
    32'sd5, 32'sd1, 32'sd-24, 32'sd-4, 32'sd30, 32'sd35, 32'sd-39, 32'sd33,
    32'sd-45, 32'sd-36, 32'sd-39, 32'sd-12, 32'sd1, 32'sd-12, 32'sd41, 32'sd40,
    32'sd7, 32'sd33, 32'sd-5, 32'sd0, 32'sd4, 32'sd10, 32'sd20, 32'sd-16,
    32'sd0, 32'sd22, 32'sd23, 32'sd-27, 32'sd-18, 32'sd-27, 32'sd5, 32'sd10,
    32'sd29, 32'sd32, 32'sd28, 32'sd24, 32'sd13, 32'sd37, 32'sd-7, 32'sd37,
    32'sd62, 32'sd37, 32'sd-33, 32'sd-6, 32'sd23, 32'sd-6, 32'sd-11, 32'sd1,
    32'sd17, 32'sd4, 32'sd5, 32'sd24, 32'sd13, 32'sd-9, 32'sd13, 32'sd-11,
    32'sd0, 32'sd-6, 32'sd69, 32'sd-18, 32'sd-33, 32'sd-14, 32'sd13, 32'sd-40,
    32'sd35, 32'sd-10, 32'sd-12, 32'sd-25, 32'sd-7, 32'sd14, 32'sd24, 32'sd-10,
    32'sd-41, 32'sd-21, 32'sd-20, 32'sd-13, 32'sd-24, 32'sd7, 32'sd29, 32'sd-2,
    32'sd-20, 32'sd12, 32'sd-21, 32'sd-27, 32'sd-10, 32'sd6, 32'sd-19, 32'sd35,
    32'sd1, 32'sd-18, 32'sd35, 32'sd-5, 32'sd20, 32'sd37, 32'sd38, 32'sd16,
    32'sd-4, 32'sd32, 32'sd2, 32'sd-30
  };

  localparam int ROM_ID_OUTPUT_PROJ_W = 24;
  localparam int OUTPUT_PROJ_W_NUMEL = 12;
  localparam int OUTPUT_PROJ_W_EXP = -7;
  localparam int OUTPUT_PROJ_W_LOGICAL_BITS = 8;
  localparam bit OUTPUT_PROJ_W_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] OUTPUT_PROJ_W_FLAT [0:11] = '{
    32'sd-19, 32'sd-42, 32'sd-56, 32'sd-56, 32'sd49, 32'sd-56, 32'sd-98, 32'sd-35,
    32'sd53, 32'sd-3, 32'sd-26, 32'sd35
  };

  localparam int ROM_ID_OUTPUT_PROJ_B = 25;
  localparam int OUTPUT_PROJ_B_NUMEL = 2;
  localparam int OUTPUT_PROJ_B_EXP = -7;
  localparam int OUTPUT_PROJ_B_LOGICAL_BITS = 16;
  localparam bit OUTPUT_PROJ_B_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] OUTPUT_PROJ_B_FLAT [0:1] = '{
    32'sd1, 32'sd3
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_K = 26;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_K_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_MIX_K_FLAT [0:5] = '{
    32'sd6, 32'sd74, 32'sd128, 32'sd165, 32'sd188, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_V = 27;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_V_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_V_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_MIX_V_FLAT [0:5] = '{
    32'sd0, 32'sd36, 32'sd76, 32'sd132, 32'sd213, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_MIX_R = 28;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_0_ATT_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_TIME_MIX_R_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_MIX_R_FLAT [0:5] = '{
    32'sd0, 32'sd163, 32'sd207, 32'sd220, 32'sd225, 32'sd219
  };

  localparam int ROM_ID_BLOCKS_0_ATT_ONE_TM = 29;
  localparam int BLOCKS_0_ATT_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_0_ATT_ONE_TM_EXP = -8;
  localparam int BLOCKS_0_ATT_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_ATT_ONE_TM_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_ATT_ONE_TM_FLAT [0:0] = '{
    32'sd255
  };

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_MIX_K = 30;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_0_FFN_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_TIME_MIX_K_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_FFN_TIME_MIX_K_FLAT [0:5] = '{
    32'sd6, 32'sd46, 32'sd62, 32'sd167, 32'sd228, 32'sd241
  };

  localparam int ROM_ID_BLOCKS_0_FFN_TIME_MIX_R = 31;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_0_FFN_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_TIME_MIX_R_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_FFN_TIME_MIX_R_FLAT [0:5] = '{
    32'sd0, 32'sd55, 32'sd52, 32'sd180, 32'sd230, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_0_FFN_ONE_TM = 32;
  localparam int BLOCKS_0_FFN_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_0_FFN_ONE_TM_EXP = -8;
  localparam int BLOCKS_0_FFN_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_0_FFN_ONE_TM_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_0_FFN_ONE_TM_FLAT [0:0] = '{
    32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_K = 33;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_K_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_MIX_K_FLAT [0:5] = '{
    32'sd17, 32'sd98, 32'sd146, 32'sd184, 32'sd216, 32'sd235
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_V = 34;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_V_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_V_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_MIX_V_FLAT [0:5] = '{
    32'sd61, 32'sd196, 32'sd221, 32'sd255, 32'sd255, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_MIX_R = 35;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_1_ATT_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_TIME_MIX_R_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_MIX_R_FLAT [0:5] = '{
    32'sd0, 32'sd221, 32'sd202, 32'sd248, 32'sd219, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_ATT_ONE_TM = 36;
  localparam int BLOCKS_1_ATT_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_1_ATT_ONE_TM_EXP = -8;
  localparam int BLOCKS_1_ATT_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_ATT_ONE_TM_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_ATT_ONE_TM_FLAT [0:0] = '{
    32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_MIX_K = 37;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_EXP = -8;
  localparam int BLOCKS_1_FFN_TIME_MIX_K_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_MIX_K_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_FFN_TIME_MIX_K_FLAT [0:5] = '{
    32'sd0, 32'sd61, 32'sd188, 32'sd215, 32'sd255, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_FFN_TIME_MIX_R = 38;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_NUMEL = 6;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_EXP = -8;
  localparam int BLOCKS_1_FFN_TIME_MIX_R_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_TIME_MIX_R_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_FFN_TIME_MIX_R_FLAT [0:5] = '{
    32'sd0, 32'sd51, 32'sd225, 32'sd161, 32'sd206, 32'sd255
  };

  localparam int ROM_ID_BLOCKS_1_FFN_ONE_TM = 39;
  localparam int BLOCKS_1_FFN_ONE_TM_NUMEL = 1;
  localparam int BLOCKS_1_FFN_ONE_TM_EXP = -8;
  localparam int BLOCKS_1_FFN_ONE_TM_LOGICAL_BITS = 8;
  localparam bit BLOCKS_1_FFN_ONE_TM_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] BLOCKS_1_FFN_ONE_TM_FLAT [0:0] = '{
    32'sd255
  };

  localparam int ROM_ID_WKV_LUT = 40;
  localparam int WKV_LUT_NUMEL = 256;
  localparam int WKV_LUT_EXP = -16;
  localparam int WKV_LUT_LOGICAL_BITS = 16;
  localparam bit WKV_LUT_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] WKV_LUT_FLAT [0:255] = '{
    32'sd0, 32'sd0, 32'sd0, 32'sd0, 32'sd0, 32'sd1, 32'sd1, 32'sd1,
    32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1,
    32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd1,
    32'sd1, 32'sd1, 32'sd1, 32'sd1, 32'sd2, 32'sd2, 32'sd2, 32'sd2,
    32'sd2, 32'sd2, 32'sd2, 32'sd2, 32'sd2, 32'sd2, 32'sd2, 32'sd3,
    32'sd3, 32'sd3, 32'sd3, 32'sd3, 32'sd3, 32'sd3, 32'sd4, 32'sd4,
    32'sd4, 32'sd4, 32'sd4, 32'sd4, 32'sd5, 32'sd5, 32'sd5, 32'sd5,
    32'sd6, 32'sd6, 32'sd6, 32'sd6, 32'sd7, 32'sd7, 32'sd7, 32'sd8,
    32'sd8, 32'sd9, 32'sd9, 32'sd9, 32'sd10, 32'sd10, 32'sd11, 32'sd11,
    32'sd12, 32'sd12, 32'sd13, 32'sd14, 32'sd14, 32'sd15, 32'sd16, 32'sd17,
    32'sd17, 32'sd18, 32'sd19, 32'sd20, 32'sd21, 32'sd22, 32'sd23, 32'sd24,
    32'sd25, 32'sd27, 32'sd28, 32'sd29, 32'sd31, 32'sd32, 32'sd34, 32'sd35,
    32'sd37, 32'sd39, 32'sd41, 32'sd42, 32'sd45, 32'sd47, 32'sd49, 32'sd51,
    32'sd54, 32'sd56, 32'sd59, 32'sd62, 32'sd65, 32'sd68, 32'sd71, 32'sd75,
    32'sd78, 32'sd82, 32'sd86, 32'sd90, 32'sd95, 32'sd99, 32'sd104, 32'sd109,
    32'sd114, 32'sd120, 32'sd125, 32'sd131, 32'sd138, 32'sd144, 32'sd151, 32'sd159,
    32'sd166, 32'sd174, 32'sd183, 32'sd192, 32'sd201, 32'sd210, 32'sd221, 32'sd231,
    32'sd242, 32'sd254, 32'sd266, 32'sd279, 32'sd293, 32'sd307, 32'sd321, 32'sd337,
    32'sd353, 32'sd370, 32'sd388, 32'sd407, 32'sd426, 32'sd447, 32'sd468, 32'sd491,
    32'sd515, 32'sd539, 32'sd565, 32'sd593, 32'sd621, 32'sd651, 32'sd682, 32'sd715,
    32'sd750, 32'sd786, 32'sd824, 32'sd863, 32'sd905, 32'sd949, 32'sd994, 32'sd1042,
    32'sd1092, 32'sd1145, 32'sd1200, 32'sd1258, 32'sd1319, 32'sd1382, 32'sd1449, 32'sd1519,
    32'sd1592, 32'sd1669, 32'sd1749, 32'sd1833, 32'sd1922, 32'sd2014, 32'sd2111, 32'sd2213,
    32'sd2320, 32'sd2431, 32'sd2549, 32'sd2671, 32'sd2800, 32'sd2935, 32'sd3076, 32'sd3225,
    32'sd3380, 32'sd3543, 32'sd3714, 32'sd3893, 32'sd4080, 32'sd4277, 32'sd4483, 32'sd4699,
    32'sd4925, 32'sd5162, 32'sd5411, 32'sd5672, 32'sd5945, 32'sd6232, 32'sd6532, 32'sd6847,
    32'sd7177, 32'sd7522, 32'sd7885, 32'sd8265, 32'sd8663, 32'sd9080, 32'sd9518, 32'sd9976,
    32'sd10457, 32'sd10961, 32'sd11489, 32'sd12043, 32'sd12623, 32'sd13231, 32'sd13869, 32'sd14537,
    32'sd15238, 32'sd15972, 32'sd16741, 32'sd17548, 32'sd18393, 32'sd19280, 32'sd20209, 32'sd21182,
    32'sd22203, 32'sd23273, 32'sd24394, 32'sd25570, 32'sd26802, 32'sd28093, 32'sd29447, 32'sd30866,
    32'sd32353, 32'sd33912, 32'sd35546, 32'sd37258, 32'sd39054, 32'sd40935, 32'sd42908, 32'sd44975,
    32'sd47142, 32'sd49414, 32'sd51795, 32'sd54290, 32'sd56906, 32'sd59648, 32'sd62522, 32'sd65535
  };

  localparam int ROM_ID_WKV_MIN_DELTA_I = 41;
  localparam int WKV_MIN_DELTA_I_NUMEL = 1;
  localparam int WKV_MIN_DELTA_I_EXP = -2;
  localparam int WKV_MIN_DELTA_I_LOGICAL_BITS = 32;
  localparam bit WKV_MIN_DELTA_I_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] WKV_MIN_DELTA_I_FLAT [0:0] = '{
    32'sd-48
  };

  localparam int ROM_ID_WKV_STEP_I = 42;
  localparam int WKV_STEP_I_NUMEL = 1;
  localparam int WKV_STEP_I_EXP = -2;
  localparam int WKV_STEP_I_LOGICAL_BITS = 32;
  localparam bit WKV_STEP_I_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] WKV_STEP_I_FLAT [0:0] = '{
    32'sd1
  };

  localparam int ROM_ID_WKV_E_FRAC = 43;
  localparam int WKV_E_FRAC_NUMEL = 1;
  localparam int WKV_E_FRAC_EXP = 0;
  localparam int WKV_E_FRAC_LOGICAL_BITS = 32;
  localparam bit WKV_E_FRAC_IS_SIGNED = 1'b0;
  localparam logic signed [31:0] WKV_E_FRAC_FLAT [0:0] = '{
    32'sd16
  };

  localparam int ROM_ID_WKV_LOG_EXP = 44;
  localparam int WKV_LOG_EXP_NUMEL = 1;
  localparam int WKV_LOG_EXP_EXP = 0;
  localparam int WKV_LOG_EXP_LOGICAL_BITS = 32;
  localparam bit WKV_LOG_EXP_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] WKV_LOG_EXP_FLAT [0:0] = '{
    32'sd-2
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_FIRST = 45;
  localparam int BLOCKS_0_ATT_TIME_FIRST_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_FIRST_EXP = -2;
  localparam int BLOCKS_0_ATT_TIME_FIRST_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_ATT_TIME_FIRST_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_FIRST_FLAT [0:5] = '{
    32'sd-4, 32'sd-3, 32'sd-6, 32'sd-3, 32'sd-1, 32'sd-6
  };

  localparam int ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP = 46;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL = 6;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_EXP = -2;
  localparam int BLOCKS_0_ATT_TIME_DECAY_WEXP_LOGICAL_BITS = 12;
  localparam bit BLOCKS_0_ATT_TIME_DECAY_WEXP_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_0_ATT_TIME_DECAY_WEXP_FLAT [0:5] = '{
    32'sd0, 32'sd0, 32'sd-2, 32'sd-10, 32'sd-32, 32'sd-78
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_FIRST = 47;
  localparam int BLOCKS_1_ATT_TIME_FIRST_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_FIRST_EXP = -2;
  localparam int BLOCKS_1_ATT_TIME_FIRST_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_FIRST_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_FIRST_FLAT [0:5] = '{
    32'sd-4, 32'sd-3, 32'sd-7, 32'sd-4, 32'sd-2, 32'sd-5
  };

  localparam int ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP = 48;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL = 6;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_EXP = -2;
  localparam int BLOCKS_1_ATT_TIME_DECAY_WEXP_LOGICAL_BITS = 12;
  localparam bit BLOCKS_1_ATT_TIME_DECAY_WEXP_IS_SIGNED = 1'b1;
  localparam logic signed [31:0] BLOCKS_1_ATT_TIME_DECAY_WEXP_FLAT [0:5] = '{
    32'sd0, 32'sd0, 32'sd0, 32'sd-1, 32'sd-5, 32'sd-79
  };

  localparam int ROM_NUMEL [0:ROM_COUNT-1] = '{12, 6, 24, 6, 36, 36, 36, 36, 24, 6, 108, 36, 108, 24, 6, 36, 36, 36, 36, 24, 6, 108, 36, 108, 12, 2, 6, 6, 6, 1, 6, 6, 1, 6, 6, 6, 1, 6, 6, 1, 256, 1, 1, 1, 1, 6, 6, 6, 6};

  function automatic logic signed [31:0] rom_read(input logic [7:0] rom_id, input logic [15:0] addr);
    logic signed [31:0] v;
    begin
      v = 32'sd0;
      unique case (rom_id)
        ROM_ID_INPUT_PROJ_W: begin
          if (addr < INPUT_PROJ_W_NUMEL) v = INPUT_PROJ_W_FLAT[addr];
        end
        ROM_ID_INPUT_PROJ_B: begin
          if (addr < INPUT_PROJ_B_NUMEL) v = INPUT_PROJ_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_W: begin
          if (addr < BLOCKS_0_ATT_TIME_SHIFT_W_NUMEL) v = BLOCKS_0_ATT_TIME_SHIFT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_SHIFT_B: begin
          if (addr < BLOCKS_0_ATT_TIME_SHIFT_B_NUMEL) v = BLOCKS_0_ATT_TIME_SHIFT_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_KEY_W: begin
          if (addr < BLOCKS_0_ATT_KEY_W_NUMEL) v = BLOCKS_0_ATT_KEY_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_VALUE_W: begin
          if (addr < BLOCKS_0_ATT_VALUE_W_NUMEL) v = BLOCKS_0_ATT_VALUE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_RECEPTANCE_W: begin
          if (addr < BLOCKS_0_ATT_RECEPTANCE_W_NUMEL) v = BLOCKS_0_ATT_RECEPTANCE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_OUTPUT_W: begin
          if (addr < BLOCKS_0_ATT_OUTPUT_W_NUMEL) v = BLOCKS_0_ATT_OUTPUT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_W: begin
          if (addr < BLOCKS_0_FFN_TIME_SHIFT_W_NUMEL) v = BLOCKS_0_FFN_TIME_SHIFT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_TIME_SHIFT_B: begin
          if (addr < BLOCKS_0_FFN_TIME_SHIFT_B_NUMEL) v = BLOCKS_0_FFN_TIME_SHIFT_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_KEY_W: begin
          if (addr < BLOCKS_0_FFN_KEY_W_NUMEL) v = BLOCKS_0_FFN_KEY_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_RECEPTANCE_W: begin
          if (addr < BLOCKS_0_FFN_RECEPTANCE_W_NUMEL) v = BLOCKS_0_FFN_RECEPTANCE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_VALUE_W: begin
          if (addr < BLOCKS_0_FFN_VALUE_W_NUMEL) v = BLOCKS_0_FFN_VALUE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_W: begin
          if (addr < BLOCKS_1_ATT_TIME_SHIFT_W_NUMEL) v = BLOCKS_1_ATT_TIME_SHIFT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_SHIFT_B: begin
          if (addr < BLOCKS_1_ATT_TIME_SHIFT_B_NUMEL) v = BLOCKS_1_ATT_TIME_SHIFT_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_KEY_W: begin
          if (addr < BLOCKS_1_ATT_KEY_W_NUMEL) v = BLOCKS_1_ATT_KEY_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_VALUE_W: begin
          if (addr < BLOCKS_1_ATT_VALUE_W_NUMEL) v = BLOCKS_1_ATT_VALUE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_RECEPTANCE_W: begin
          if (addr < BLOCKS_1_ATT_RECEPTANCE_W_NUMEL) v = BLOCKS_1_ATT_RECEPTANCE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_OUTPUT_W: begin
          if (addr < BLOCKS_1_ATT_OUTPUT_W_NUMEL) v = BLOCKS_1_ATT_OUTPUT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_W: begin
          if (addr < BLOCKS_1_FFN_TIME_SHIFT_W_NUMEL) v = BLOCKS_1_FFN_TIME_SHIFT_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_TIME_SHIFT_B: begin
          if (addr < BLOCKS_1_FFN_TIME_SHIFT_B_NUMEL) v = BLOCKS_1_FFN_TIME_SHIFT_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_KEY_W: begin
          if (addr < BLOCKS_1_FFN_KEY_W_NUMEL) v = BLOCKS_1_FFN_KEY_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_RECEPTANCE_W: begin
          if (addr < BLOCKS_1_FFN_RECEPTANCE_W_NUMEL) v = BLOCKS_1_FFN_RECEPTANCE_W_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_VALUE_W: begin
          if (addr < BLOCKS_1_FFN_VALUE_W_NUMEL) v = BLOCKS_1_FFN_VALUE_W_FLAT[addr];
        end
        ROM_ID_OUTPUT_PROJ_W: begin
          if (addr < OUTPUT_PROJ_W_NUMEL) v = OUTPUT_PROJ_W_FLAT[addr];
        end
        ROM_ID_OUTPUT_PROJ_B: begin
          if (addr < OUTPUT_PROJ_B_NUMEL) v = OUTPUT_PROJ_B_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_K: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_K_NUMEL) v = BLOCKS_0_ATT_TIME_MIX_K_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_V: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_V_NUMEL) v = BLOCKS_0_ATT_TIME_MIX_V_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_MIX_R: begin
          if (addr < BLOCKS_0_ATT_TIME_MIX_R_NUMEL) v = BLOCKS_0_ATT_TIME_MIX_R_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_ONE_TM: begin
          if (addr < BLOCKS_0_ATT_ONE_TM_NUMEL) v = BLOCKS_0_ATT_ONE_TM_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_TIME_MIX_K: begin
          if (addr < BLOCKS_0_FFN_TIME_MIX_K_NUMEL) v = BLOCKS_0_FFN_TIME_MIX_K_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_TIME_MIX_R: begin
          if (addr < BLOCKS_0_FFN_TIME_MIX_R_NUMEL) v = BLOCKS_0_FFN_TIME_MIX_R_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_FFN_ONE_TM: begin
          if (addr < BLOCKS_0_FFN_ONE_TM_NUMEL) v = BLOCKS_0_FFN_ONE_TM_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_K: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_K_NUMEL) v = BLOCKS_1_ATT_TIME_MIX_K_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_V: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_V_NUMEL) v = BLOCKS_1_ATT_TIME_MIX_V_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_MIX_R: begin
          if (addr < BLOCKS_1_ATT_TIME_MIX_R_NUMEL) v = BLOCKS_1_ATT_TIME_MIX_R_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_ONE_TM: begin
          if (addr < BLOCKS_1_ATT_ONE_TM_NUMEL) v = BLOCKS_1_ATT_ONE_TM_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_TIME_MIX_K: begin
          if (addr < BLOCKS_1_FFN_TIME_MIX_K_NUMEL) v = BLOCKS_1_FFN_TIME_MIX_K_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_TIME_MIX_R: begin
          if (addr < BLOCKS_1_FFN_TIME_MIX_R_NUMEL) v = BLOCKS_1_FFN_TIME_MIX_R_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_FFN_ONE_TM: begin
          if (addr < BLOCKS_1_FFN_ONE_TM_NUMEL) v = BLOCKS_1_FFN_ONE_TM_FLAT[addr];
        end
        ROM_ID_WKV_LUT: begin
          if (addr < WKV_LUT_NUMEL) v = WKV_LUT_FLAT[addr];
        end
        ROM_ID_WKV_MIN_DELTA_I: begin
          if (addr < WKV_MIN_DELTA_I_NUMEL) v = WKV_MIN_DELTA_I_FLAT[addr];
        end
        ROM_ID_WKV_STEP_I: begin
          if (addr < WKV_STEP_I_NUMEL) v = WKV_STEP_I_FLAT[addr];
        end
        ROM_ID_WKV_E_FRAC: begin
          if (addr < WKV_E_FRAC_NUMEL) v = WKV_E_FRAC_FLAT[addr];
        end
        ROM_ID_WKV_LOG_EXP: begin
          if (addr < WKV_LOG_EXP_NUMEL) v = WKV_LOG_EXP_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_FIRST: begin
          if (addr < BLOCKS_0_ATT_TIME_FIRST_NUMEL) v = BLOCKS_0_ATT_TIME_FIRST_FLAT[addr];
        end
        ROM_ID_BLOCKS_0_ATT_TIME_DECAY_WEXP: begin
          if (addr < BLOCKS_0_ATT_TIME_DECAY_WEXP_NUMEL) v = BLOCKS_0_ATT_TIME_DECAY_WEXP_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_FIRST: begin
          if (addr < BLOCKS_1_ATT_TIME_FIRST_NUMEL) v = BLOCKS_1_ATT_TIME_FIRST_FLAT[addr];
        end
        ROM_ID_BLOCKS_1_ATT_TIME_DECAY_WEXP: begin
          if (addr < BLOCKS_1_ATT_TIME_DECAY_WEXP_NUMEL) v = BLOCKS_1_ATT_TIME_DECAY_WEXP_FLAT[addr];
        end
        default: begin
          v = 32'sd0;
        end
      endcase
      rom_read = v;
    end
  endfunction

endpackage
