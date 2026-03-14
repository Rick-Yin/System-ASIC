set DESIGN_NAME      "migo"
set TOP_MODULE       "MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4"
set RTL_FILELIST     [file normalize [file join $::env(REPO_ROOT) flow filelists migo.f]]
set DEFAULT_CLK_NS   2.0
set CLOCK_PORT       "clk"
set RESET_PORT       "rst_n"
set SELF_DIR         [file normalize [file dirname [info script]]]
set CONSTRAINTS_FILE [file normalize [file join $SELF_DIR constraints.sdc]]
set TB_FILE          [file normalize [file join $SELF_DIR tb tb_migo_saif.sv]]
set TB_TOP           "tb_migo_saif"
set SAIF_INST        "tb_migo_saif/u_dut"
