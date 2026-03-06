set WORK_PATH ./WORK

define_design_lib WORK -path $WORK_PATH

set ASIC_WORKDIR /dx_s702/vol_s702a0_dev/zhuhao/S702/asic
set ASIC_ACC_WORKDIR ../../../..
set ASIC_INCLUDE_WORKDIR "+incdir+$ASIC_ACC_WORKDIR"
#os.environ['ASIC_INCLUDE_WORKDIR'] = '+incdir+../../../..'

set search_path [list \
$ASIC_WORKDIR/golden_module/dx_t503/rtl/dx502/soc/ap_sub/AXI/00_macmatrix \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/SOURCE \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/AXI/00_phymatrix \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_asip_v2/RTL/maotu_etm \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_asip_v2/RTL/r4cpu_etm \
$ASIC_WORKDIR/lib/backend/dft_include \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/AXI/02_AXIAHB \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL/CORE \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sdio_host/src/core/cmn \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/PERIPHERAL/IP/atcspi200/hdl \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_dap/RTL \
$ASIC_WORKDIR/layout_block/common \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/AXI/04_AXIAPB \
$ASIC_WORKDIR/layout_block/lb_lsp1/code/rtl/include \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL/CORE/cr4axis/verilog \
$ASIC_WORKDIR/golden_module/zkjs_axi \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sdio_host/src/core \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_asip_v2/RTL \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/SOURCE/DCD_SPI.V \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/cop_sub/nr_rfiu/rtl/mipi \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/SOURCE/CDC.V \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_top_v2/RTL \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/PERIPHERAL/IP/usart_new/rtl \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL/models/cells/cr4_conf_stage3 \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_daplite/RTL \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/PERIPHERAL/IP/atcspi200/hdl/include \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/SOURCE/DFSPI.V \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_rfiu_v2/RTL \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/SOURCE/SYNCH.V \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL/CORE/cr4dpu/verilog \
$ASIC_WORKDIR/lib/backend/lib/logic \
$ASIC_WORKDIR/golden_module/dx_t502/rtl/dx502/soc/ap_sub/PERIPHERAL/IP/usart_new \
$ASIC_WORKDIR/golden_module/DFSPI/20240216/DFSPI/DFSPI_VERILOG/DFSPI_VER_V2.52d/DFSPI_VER_V2.52d/SRC/BUSSES/APB/DAPBWRAP.V \
$ASIC_WORKDIR/golden_module/s301/soc_wx_fullmask_final_regression/gmr_bp_sp/RTL/CORE/cr4mpu/verilog \
]

set_app_var target_library [list \
/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db]

set_app_var link_library [list \
/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db\
]

set_app_var synthetic_library "dw_foundation.sldb"