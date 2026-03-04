set FLOW_NAME joint
source [file join [file dirname [info script]] config_base.tcl]

set TOP_MODULE rwkvcnn_top
set RTL_FILELIST [file join $ROOT_DIR dc filelist_joint.f]
