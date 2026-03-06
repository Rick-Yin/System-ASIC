if {![info exists ::env(LVL)] || ![info exists ::env(METHOD)]} {
    puts "Error: environment variables LVL and METHOD must be set."
    exit 1
}

set lvl        $::env(LVL)
set method     $::env(METHOD)
set method_lc  [string tolower $method]

set TOP        "viterbi_quan_lvl${lvl}_${method}"
set NETLIST    "./mapped/${TOP}-mapped.v"
set SDC_FILE   "./mapped/${TOP}-mapped.sdc"

set OUT_DIR    "./power"
set SAIF_FILE  "${OUT_DIR}/${TOP}_L${lvl}.saif"
set TB_TOP     "tb_quan_lvl${lvl}_${method_lc}"
set SAIF_INST  "${TB_TOP}/u_dut"

set LIB  "/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db"

set search_path ". ./mapped"
set link_path   "* $LIB"

set_app_var power_enable_analysis true

read_verilog $NETLIST

link_design $TOP

read_sdc $SDC_FILE
read_saif -strip_path $SAIF_INST $SAIF_FILE

update_timing
update_power

redirect "${OUT_DIR}/power_pt.rpt" {report_power -hier}

quit