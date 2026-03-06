######This option helps check the environment consistency of DC & ICC2
#write_environment -consistency -output DCT.env
#write_environment -consistency -output ICC.env
#consistency_checker -file1 DCT.env -file2 ICC.env \
# -folder temp \
# -html html_report | tee cc.log

######Synthesis Flow######
#set TOP cc_orx_top ;#Specify top design name
set TOP viterbi_quan_lvl4_SPNQ ;#Specify top design name

source ../.synopsys_dc.setup.tcl ;#This scripts specify basic libraries, such as target lib, link lib and DW lib, search path and environment variables

set_host_options -max_cores 1 ;# Multicore technology is not supported in DC Expert

set_svf ./$TOP.svf ;#SVF file is used in Formality for LEC check

set_app_var hdlin_enable_hier_map true ;# Set this variable before reading or analyzing any RTL files, this tracks all logical hierarchy transformations performed by the tool

set hdlin_infer_multibit default_all ;#Infer multibit registers for all buses during RTL reading

#saif_map -start ;#Enable activate SAIF name mapping for PTPX

#set_max_delay 10 {A B C}

#set_max_transition 3.2 [get_designs zuc256_top]

#remove_attribute [get_designs zuc256_top] max_transition

source ../analyze_file.tcl > ./reports/analyze_file.rpt ;#Reading RTL codes

elaborate $TOP > ./reports/elaborate.rpt ;#This command translates the design into a technology-independent design (GTECH) from the intermediate files produced during analysis

link > ./reports/link.rpt ;#This command resolves design references

#create_multibit -name my_multi_reg1 {***} ;#Manually assign bits to specific multibit registers

#set_multibit_options -mode timing_driven ;#Choose timing-driven multibit register mapping

current_design $TOP ;#Use this command to set any design in dc_shell memory as the current design

#saif_map -create_map -source_instance tb_eia_zuc256 -input ../../../sim/zuc256_ptpx.saif ;#Reading in saif file for mapping file creation

set_verification_top ;#This command improves how complex hierarchy transformations are handled in the verification guidance, it is a part of the recommended SVF creation flow, this command requires that the hdlin_enable_hier_map application variable was set to true prior to reading any RTL files

set_dynamic_optimization true ;#Use this command to enable dynamic power optimization

#set_critical_range 3.0 zuc256_top

uniquify > ./reports/uniquify.rpt ;#This command copies and renames any multiply referenced design so that each instance references a unique design

#remove_unconnected_ports -blast_buses [find -hierarchy cell {"*"}] > ../report/chip_top_test/remove_ports.rpt

source ../quan_top.sdc

#set compile_seqmap_propagate_constants false ;#Constant register removal is enabled by default when you run the compile_ultra, set this variable to false to prevent constant register removal

#When you enable the following variable, the weights of all path groups are set to 1, After area optimization, the weight on each path group is restored to the original user-specified value. By default, the variable is false
#optimize_area_ignore_path_group_weights true ;

check_design -summary > ./reports/check_design.rpt
check_timing > ./reports/check_timing.rpt
check_library > ./reports/check_library.rpt ;#This command checks the integrity of individual logical and physical libraries, consistency between logic libraries, consistency between logic libraries and physical libraries and consistency between physical libraries and technology files

#group_path -name *** -from *** -to *** -weight *** ;#This option helps optimize the maximum delay cost function

create_auto_path_groups -mode rtl ;#create path groups before the initial compile, use -min_regs_per_hierarchy option to specify minimum number of registers per hierarchy

#You can isolate input and output ports to improve the accuracy of timing models, the isolation logic can be a buffer or a pair of inverters, port isolation can be applied only to input or output ports of the current design, port isolation is currently intended for use only during bottom-up compile.use the propagate_constraints command to propagate the constraints upward after the subblock ports are isolated and before you compile the top-level design
#set_isolate_ports

#compile_ultra -check_only

compile_ultra -no_autoungroup > ./reports/compile_ultra.rpt ;#-retime -no_autoungroup -gate_clock > ./reports/compile_ultra.rpt

create_auto_path_groups -mode mapped ;#This creates one path group per hierarchy only for those hierarchical blocks in the design that do not meet timing

# compile_ultra -incremental -scan -gate_clock -no_autoungroup -retime > ./reports/compile_ultra_inc.rpt

#remove_auto_path_groups ;#this command does not remove the user-created path groups.

#The following command helps fix heavily loaded nets, supported only in wire load mode, if the large loads reside across the hierarchy from several modules, apply -only_design_rule option with compile_ultra to fix the problem
#balance_buffer -from [get_pins ***]

#balance_buffer ;#this command build balanced buffer trees to fix design rule violations and improve timing delays caused by high-fanout nets

optimize_netlist -area ;#This command performs monotonic gate-to-gate optimization to improve area without degrading timing or leakage

update_timing

check_design -summary > ./reports/check_design2.rpt
check_timing > ./reports/check_timing2.rpt
report_threshold_voltage_group > ./reports/threshold_cell.rpt ;#Use thiscommand to see the percentage of the total design, by cell count and by area, that is occupied by the low threshold-voltage cells
report_qor > ./reports/qor.rpt
report_area -hierarchy -designware -physical > ./reports/area.rpt
report_power > ./reports/power.rpt
report_clock_gating -verbose > ./reports/clock_gate.rpt
report_timing -path full -net -cap -input -tran -delay max -max_paths 20 -nworst 20 > ./reports/timing_max.rpt
report_timing -path full -net -cap -input -tran -delay min -max_paths 20 -nworst 20 > ./reports/timing_min.rpt
report_constraints -all_violators > ./reports/constraints.rpt

######Outputs######
change_names -rules verilog -hierarchy ;#Always use this command whenever you want to write out a Verilog or VHDL design because naming in the design database file is not Verilog or VHDL compliant.

#saif_map -write_map ../../../ptpx/zuc256_top_ptpxmap.tcl -type ptpx

write_file -f verilog -hierarchy -output ./mapped/$TOP-mapped.v ;#Use this command to write a mapped netlist

write_parasitics -output ./mapped/$TOP.spef ;#Write parasitics file

#write_sdf -version 2.1 ./mapped/$TOP-mapped.sdf ;#SDF file contains back-annotation delay information, mainly used for post simulation after APR

write_file -f ddc -hierarchy -output ./mapped/$TOP-mapped.ddc ;#Synopsys internal database format (the default format)

write_sdc ./mapped/$TOP-mapped.sdc