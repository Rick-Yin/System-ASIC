analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/lib/frontend/ram_wrapper/gmr_conv_gdec/orx_wrap_spram_256x128.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/lib/frontend/ram_wrapper/gmr_conv_gec/orx_wrap_spram_64x128.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/lib/frontend/ram_wrapper/gmr_conv_gec/orx_wrap_spram_256x32.v

analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/cc_orx_top.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/cdc_apb.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/crc_check.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/crc_check_top.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_bufferflybase2.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_in_buffer.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_max16.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_mem.v

analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/Quan_UQvsSPNQ/viterbi_quantify.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_top.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_trellis.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/conv_dec/viterbi_traceback.v


analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/wrap_fifo_sync.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/wdma_data_in.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/rdma_ctrl.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/axi_wdma.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/wdma.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/axi_rdma.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/rdma_apb_reg.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/wdma_ctrl.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/rdma_data_out.v


analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/mcp_apb_reg.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/fifo_sync_mcp.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/mcp_axi.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/wrap_fifo_sync_mcp.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/mcp_semi_in.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/mcp_ctrl.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/mcp/mcp.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/fifo_sync.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/wdma_apb_reg.v
analyze -format verilog -work WORK $ASIC_ACC_WORKDIR/block/gmr_conv_gdec/rtl/dma/rdma.v