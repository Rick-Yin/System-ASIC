# expects TOP_MODULE and timing vars from config_*.tcl
create_clock -name core_clk -period $CLK_PERIOD_NS [get_ports clk]
set_clock_uncertainty 0.05 [get_clocks core_clk]
set_clock_transition 0.05 [get_clocks core_clk]

set_dont_touch_network [get_ports clk]

set nonclk_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
if {[sizeof_collection $nonclk_inputs] > 0} {
  set_input_delay $INPUT_DELAY_NS -clock core_clk $nonclk_inputs
  set_input_transition 0.05 $nonclk_inputs
}

set all_outs [all_outputs]
if {[sizeof_collection $all_outs] > 0} {
  set_output_delay $OUTPUT_DELAY_NS -clock core_clk $all_outs
  set_load $LOAD_PF $all_outs
}

set_max_transition 0.15 [current_design]
set_max_fanout 8 [current_design]
set_fix_hold [get_clocks core_clk]
