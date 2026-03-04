set ROOT_DIR [file normalize [file join [file dirname [info script]] ..]]

# Default timing target: 500 MHz
set CLK_PERIOD_NS 2.0
set INPUT_DELAY_NS 0.20
set OUTPUT_DELAY_NS 0.20
set LOAD_PF 0.02

if {[info exists ::env(DC_LIB_DB)]} {
  set LIB_DB $::env(DC_LIB_DB)
} else {
  set LIB_DB [file join $ROOT_DIR tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db]
}

if {![file exists $LIB_DB]} {
  puts "[WARN] Liberty DB not found at: $LIB_DB"
  puts "[WARN] Set env DC_LIB_DB to your real .db path before running DC"
}

if {![info exists FLOW_NAME]} {
  set FLOW_NAME default
}

set OUT_DIR [file join $ROOT_DIR dc out $FLOW_NAME]
set RPT_DIR [file join $ROOT_DIR dc reports $FLOW_NAME]

set_app_var search_path [list $ROOT_DIR [file dirname $LIB_DB]]
set_app_var target_library [list $LIB_DB]
set_app_var link_library [concat * $target_library]
