#create_clock -name CLK -period $CLK_PERIOD -waveform "0 [expr $CLK_PERIOD/2]" [get_ports clk]

#create_clock -name PCLK -period $PCLK_PERIOD -waveform "0 [expr $PCLK_PERIOD/2]" [get_ports pclk]

#create_clock -name VCLK -period $CLK_PERIOD -waveform "0 [expr $CLK_PERIOD/2]"

#set_clock_uncertainty [expr $CLK_PERIOD*0.25] [get_clocks CLK]

#set_clock_uncertainty [expr $PCLK_PERIOD*0.25] [get_clocks PCLK]

#set_ideal_network -no_propagate [get_ports rst_n]

#set_ideal_network -no_propagate [get_ports prst_n]

#set_dont_touch_network [get_ports rst_n]

#set_dont_touch_network [get_ports prst_n]

#set_false_path -from [get_ports rst_n]

#set_false_path -from [get_ports prst_n]

set input_list "code_i"

set output_list "data"

#set_input_delay -clock VCLK -max [expr $CLK_PERIOD/2] [get_ports $input_list]

#set_input_delay -clock VCLK -min [expr $CLK_PERIOD/4] [get_ports $input_list]

#set_output_delay -clock VCLK -max [expr $CLK_PERIOD/2] [get_ports $output_list]

#set_output_delay -clock VCLK -min [expr $CLK_PERIOD/4] [get_ports $output_list]