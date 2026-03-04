if {![info exists TOP_MODULE]} {
  echo "[ERR] TOP_MODULE is not set"
  exit 2
}
if {![info exists RTL_FILELIST]} {
  echo "[ERR] RTL_FILELIST is not set"
  exit 2
}

file mkdir $OUT_DIR
file mkdir $RPT_DIR

if {![file exists $RTL_FILELIST]} {
  echo "[ERR] RTL filelist missing: $RTL_FILELIST"
  exit 2
}

analyze -format sverilog -vcs "-f $RTL_FILELIST"
elaborate $TOP_MODULE
current_design $TOP_MODULE
link
check_design > [file join $RPT_DIR check_design_pre_compile.rpt]

source [file join [file dirname [info script]] constraints_base.sdc]

compile_ultra -timing_high_effort_script

check_design > [file join $RPT_DIR check_design_post_compile.rpt]
report_qor > [file join $RPT_DIR qor.rpt]
report_area -hierarchy > [file join $RPT_DIR area_hier.rpt]
report_area > [file join $RPT_DIR area.rpt]
report_timing -max_paths 20 -delay max > [file join $RPT_DIR timing_max_20.rpt]
report_timing -max_paths 20 -delay min > [file join $RPT_DIR timing_min_20.rpt]
report_constraint -all_violators > [file join $RPT_DIR constraint_violators.rpt]

write_file -format verilog -hierarchy -output [file join $OUT_DIR ${TOP_MODULE}_syn.v]
write_file -format ddc -hierarchy -output [file join $OUT_DIR ${TOP_MODULE}.ddc]
write_sdc [file join $OUT_DIR ${TOP_MODULE}_syn.sdc]

exit
