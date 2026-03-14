create_clock -name CLK -period $CLK_PERIOD_NS -waveform "0 [expr {$CLK_PERIOD_NS / 2.0}]" [get_ports $CLOCK_PORT]
set_clock_uncertainty [expr {$CLK_PERIOD_NS * 0.05}] [get_clocks CLK]

set_ideal_network -no_propagate [get_ports $RESET_PORT]
set_dont_touch_network [get_ports $RESET_PORT]
set_false_path -from [get_ports $RESET_PORT]

set_input_delay  0.20 -clock CLK [get_ports {in_valid x_in}]
set_output_delay 0.20 -clock CLK [get_ports {out_valid y_out}]

set_max_transition 0.15 [current_design]
set_max_fanout 8 [current_design]
