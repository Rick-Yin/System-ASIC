set DESIGN_NAME      "migo"
set TOP_MODULE       "MIGO_method_migo_n_65_q_bit_8_wp_pi_0_2_width_pi_0_02_alpha_p_0_1_alpha_s_0_01_lam1_0_01_lam2_0_1_e_topk_1_e_d_max_2_e_e_max_0"
set RTL_FILELIST     [file normalize [file join $::env(REPO_ROOT) flow filelists migo.f]]
set DEFAULT_CLK_NS   2.0
set CLOCK_PORT       "clk"
set RESET_PORT       "rst_n"
set CONSTRAINTS_FILE [file normalize [file join $::env(REPO_ROOT) dc designs migo constraints.sdc]]
set TB_FILE          [file normalize [file join $::env(REPO_ROOT) dc designs migo tb tb_migo_saif.sv]]
set TB_TOP           "tb_migo_saif"
set SAIF_INST        "tb_migo_saif/u_dut"
