proc colon_split {value} {
    if {$value eq ""} {
        return {}
    }
    return [split $value ":"]
}

proc resolve_list_paths {paths} {
    set resolved {}
    foreach item $paths {
        if {$item eq ""} {
            continue
        }
        lappend resolved [file normalize $item]
    }
    return $resolved
}

if {![info exists ::env(REPO_ROOT)]} {
    error "REPO_ROOT environment variable is required."
}
if {![info exists ::env(DESIGN_CONFIG)]} {
    error "DESIGN_CONFIG environment variable is required."
}
if {![info exists ::env(RUN_ROOT)]} {
    error "RUN_ROOT environment variable is required."
}
if {![info exists ::env(SAIF_FILE)]} {
    error "SAIF_FILE environment variable is required."
}

set repo_root    [file normalize $::env(REPO_ROOT)]
set design_cfg   [file normalize $::env(DESIGN_CONFIG)]
set run_root     [file normalize $::env(RUN_ROOT)]
set mapped_dir   [file join $run_root mapped]
set reports_dir  [file join $run_root reports]
set power_dir    [file join $run_root power]
set saif_file    [file normalize $::env(SAIF_FILE)]

file mkdir $reports_dir
file mkdir $power_dir

source $design_cfg

if {![info exists TOP_MODULE]} {
    error "TOP_MODULE must be set by $design_cfg"
}
if {![info exists SAIF_INST]} {
    error "SAIF_INST must be set by $design_cfg"
}

set default_target_lib "/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db"

set target_libs [list $default_target_lib]
if {[info exists ::env(TARGET_LIB)] && $::env(TARGET_LIB) ne ""} {
    set target_libs [resolve_list_paths [colon_split $::env(TARGET_LIB)]]
}

set link_libs $target_libs
if {[info exists ::env(LINK_LIB)] && $::env(LINK_LIB) ne ""} {
    set link_libs [resolve_list_paths [colon_split $::env(LINK_LIB)]]
}

set extra_search_paths {}
if {[info exists ::env(SEARCH_PATHS)] && $::env(SEARCH_PATHS) ne ""} {
    set extra_search_paths [resolve_list_paths [colon_split $::env(SEARCH_PATHS)]]
}

set netlist_file [file join $mapped_dir "${TOP_MODULE}-mapped.v"]
set mapped_sdc   [file join $mapped_dir "${TOP_MODULE}-mapped.sdc"]

if {![file exists $netlist_file]} {
    error "Mapped netlist not found: $netlist_file"
}
if {![file exists $mapped_sdc]} {
    error "Mapped SDC not found: $mapped_sdc"
}
if {![file exists $saif_file]} {
    error "SAIF file not found: $saif_file"
}

set synthetic_library [list dw_foundation.sldb]
set_app_var search_path [concat [list . $repo_root $mapped_dir] $extra_search_paths]
set link_path [concat [list *] $link_libs $synthetic_library]

set_app_var power_enable_analysis true

read_verilog $netlist_file
link_design $TOP_MODULE

read_sdc $mapped_sdc
read_saif -strip_path $SAIF_INST $saif_file

check_timing
update_timing
update_power

redirect [file join $reports_dir "pt_timing_max.rpt"] {
    report_timing -path full -net -cap -input -tran -delay max -max_paths 20 -nworst 20
}
redirect [file join $reports_dir "pt_timing_min.rpt"] {
    report_timing -path full -net -cap -input -tran -delay min -max_paths 20 -nworst 20
}
redirect [file join $reports_dir "pt_constraints.rpt"] { report_constraints -all_violators }
redirect [file join $reports_dir "power_pt.rpt"] { report_power -hier }
redirect [file join $reports_dir "switching_activity.rpt"] { report_switching_activity -list_not_annotated }

quit
