set DESIGN_NAME      "joint_cfr"
set TOP_MODULE       "rwkvcnn_top"
set RTL_FILELIST     [file normalize [file join $::env(REPO_ROOT) flow filelists joint.f]]
set DEFAULT_CLK_NS   2.0
set CLOCK_PORT       "clk"
set RESET_PORT       "rst_n"
set SELF_DIR         [file normalize [file dirname [info script]]]
set CONSTRAINTS_FILE [file normalize [file join $SELF_DIR constraints.sdc]]
set TB_FILE          [file normalize [file join $SELF_DIR tb tb_joint_saif.sv]]
set TB_TOP           "tb_joint_saif"
set SAIF_INST        "tb_joint_saif/u_dut"
