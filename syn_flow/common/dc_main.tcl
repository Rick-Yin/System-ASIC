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

proc read_filelist {filelist_path repo_root} {
    if {![file exists $filelist_path]} {
        error "RTL filelist not found: $filelist_path"
    }

    set rtl_files {}
    set file_handle [open $filelist_path r]
    while {[gets $file_handle line] >= 0} {
        regsub {#.*$} $line "" line
        set line [string trim $line]
        if {$line eq ""} {
            continue
        }
        if {[file pathtype $line] eq "absolute"} {
            set rtl_file [file normalize $line]
        } else {
            set rtl_file [file normalize [file join $repo_root $line]]
        }
        if {![file exists $rtl_file]} {
            close $file_handle
            error "RTL source from filelist does not exist: $rtl_file"
        }
        lappend rtl_files $rtl_file
    }
    close $file_handle
    return $rtl_files
}

proc fail_step {step_name message} {
    puts stderr [format {[DC][ERR] %s: %s} $step_name $message]
    quit -f
}

proc run_or_die {step_name script} {
    if {[catch {uplevel 1 $script} result options]} {
        if {[dict exists $options -errorinfo]} {
            puts stderr [dict get $options -errorinfo]
        }
        fail_step $step_name $result
    }
    return $result
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

set repo_root    [file normalize $::env(REPO_ROOT)]
set design_cfg   [file normalize $::env(DESIGN_CONFIG)]
set run_root     [file normalize $::env(RUN_ROOT)]
set reports_dir  [file join $run_root reports]
set mapped_dir   [file join $run_root mapped]
set logs_dir     [file join $run_root logs]
set work_dir     [file join $run_root WORK]

file mkdir $reports_dir
file mkdir $mapped_dir
file mkdir $logs_dir
file mkdir $work_dir

source $design_cfg

if {![info exists DESIGN_NAME]} {
    error "DESIGN_NAME must be set by $design_cfg"
}
if {![info exists TOP_MODULE]} {
    error "TOP_MODULE must be set by $design_cfg"
}
if {![info exists RTL_FILELIST]} {
    error "RTL_FILELIST must be set by $design_cfg"
}
if {![info exists DEFAULT_CLK_NS]} {
    error "DEFAULT_CLK_NS must be set by $design_cfg"
}
if {![info exists CONSTRAINTS_FILE]} {
    error "CONSTRAINTS_FILE must be set by $design_cfg"
}

set CLK_PERIOD_NS $DEFAULT_CLK_NS
if {[info exists ::env(CLOCK_NS)] && $::env(CLOCK_NS) ne ""} {
    set CLK_PERIOD_NS $::env(CLOCK_NS)
}

set max_cores 1
if {[info exists ::env(MAX_CORES)] && $::env(MAX_CORES) ne ""} {
    set max_cores $::env(MAX_CORES)
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

set rtl_files [read_filelist $RTL_FILELIST $repo_root]
set rtl_dirs {}
foreach rtl_file $rtl_files {
    set rtl_dir [file dirname $rtl_file]
    if {[lsearch -exact $rtl_dirs $rtl_dir] < 0} {
        lappend rtl_dirs $rtl_dir
    }
}

define_design_lib WORK -path $work_dir

set_app_var search_path [concat [list . $repo_root $mapped_dir] $rtl_dirs $extra_search_paths]
set_app_var target_library $target_libs
set_app_var synthetic_library [list dw_foundation.sldb]
set_app_var link_library [concat [list *] $link_libs $synthetic_library]

set_host_options -max_cores $max_cores

set_svf [file join $mapped_dir "${TOP_MODULE}.svf"]

set_app_var hdlin_enable_hier_map true
set hdlin_infer_multibit default_all

run_or_die "analyze" {
    redirect [file join $reports_dir "analyze_file.rpt"] {
    foreach rtl_file $rtl_files {
        analyze -format sverilog -work WORK $rtl_file
    }
}
}

run_or_die "elaborate" {
    redirect [file join $reports_dir "elaborate.rpt"] { elaborate $TOP_MODULE }
}
if {[sizeof_collection [get_designs $TOP_MODULE]] == 0} {
    fail_step "elaborate" "top design not found after elaborate: $TOP_MODULE"
}

run_or_die "link" {
    redirect [file join $reports_dir "link.rpt"] { link }
}

run_or_die "current_design" [list current_design $TOP_MODULE]

set_verification_top
set_dynamic_optimization true

run_or_die "uniquify" {
    redirect [file join $reports_dir "uniquify.rpt"] { uniquify }
}

set CONSTRAINTS_FILE [file normalize $CONSTRAINTS_FILE]
if {![file exists $CONSTRAINTS_FILE]} {
    error "Constraints file not found: $CONSTRAINTS_FILE"
}

run_or_die "constraints" [list source $CONSTRAINTS_FILE]

run_or_die "check_design_pre" {
    redirect [file join $reports_dir "check_design_pre.rpt"] { check_design -summary }
}
run_or_die "check_timing_pre" {
    redirect [file join $reports_dir "check_timing_pre.rpt"] { check_timing }
}
run_or_die "check_library" {
    redirect [file join $reports_dir "check_library.rpt"] { check_library }
}

run_or_die "create_auto_path_groups_rtl" { create_auto_path_groups -mode rtl }
run_or_die "compile_ultra" {
    redirect [file join $reports_dir "compile_ultra.rpt"] {
    compile_ultra -no_autoungroup
}
}
run_or_die "create_auto_path_groups_mapped" { create_auto_path_groups -mode mapped }
run_or_die "optimize_netlist" { optimize_netlist -area }

run_or_die "update_timing" { update_timing }

run_or_die "check_design_post" {
    redirect [file join $reports_dir "check_design_post.rpt"] { check_design -summary }
}
run_or_die "check_timing_post" {
    redirect [file join $reports_dir "check_timing_post.rpt"] { check_timing }
}
run_or_die "threshold_cell" {
    redirect [file join $reports_dir "threshold_cell.rpt"] { report_threshold_voltage_group }
}
run_or_die "qor" {
    redirect [file join $reports_dir "qor.rpt"] { report_qor }
}
run_or_die "area" {
    redirect [file join $reports_dir "area.rpt"] { report_area -hierarchy -designware }
}
run_or_die "power_dc" {
    redirect [file join $reports_dir "power_dc.rpt"] { report_power }
}
run_or_die "clock_gate" {
    redirect [file join $reports_dir "clock_gate.rpt"] { report_clock_gating -verbose }
}
run_or_die "timing_max" {
    redirect [file join $reports_dir "timing_max.rpt"] {
        report_timing -path full -net -cap -input -tran -delay max -max_paths 20 -nworst 20
    }
}
run_or_die "timing_min" {
    redirect [file join $reports_dir "timing_min.rpt"] {
        report_timing -path full -net -cap -input -tran -delay min -max_paths 20 -nworst 20
    }
}
run_or_die "constraints_report" {
    redirect [file join $reports_dir "constraints.rpt"] { report_constraints -all_violators }
}

run_or_die "change_names" { change_names -rules verilog -hierarchy }

run_or_die "write_mapped_verilog" {
    write_file -f verilog -hierarchy -output [file join $mapped_dir "${TOP_MODULE}-mapped.v"]
}
run_or_die "write_mapped_ddc" {
    write_file -f ddc -hierarchy -output [file join $mapped_dir "${TOP_MODULE}-mapped.ddc"]
}
run_or_die "write_mapped_sdc" {
    write_sdc [file join $mapped_dir "${TOP_MODULE}-mapped.sdc"]
}

quit
