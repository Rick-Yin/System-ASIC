# Design Compiler Flow (Split Synthesis)

## Required

- Synopsys Design Compiler
- Liberty DB (set `DC_LIB_DB` if not at repo root):
  - `tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db`

## Run

```tcl
# inside dc_shell
source dc/run_joint_dc.tcl
```

```tcl
# inside dc_shell
source dc/run_migo_dc.tcl
```

Legacy compatibility entry (Joint-CFR-DPD):

```tcl
source dc/run_dc.tcl
```

## Main files

- Shared:
  - `dc/config_base.tcl`
  - `dc/constraints_base.sdc`
  - `dc/run_common.tcl`
- Joint-CFR-DPD:
  - `dc/filelist_joint.f`
  - `dc/config_joint.tcl`
  - `dc/run_joint_dc.tcl`
- MIGO-filter:
  - `dc/filelist_migo.f`
  - `dc/config_migo.tcl`
  - `dc/run_migo_dc.tcl`

## Outputs

- Joint-CFR-DPD:
  - Netlist/DDC/SDC: `dc/out/joint/`
  - Reports: `dc/reports/joint/`
- MIGO-filter:
  - Netlist/DDC/SDC: `dc/out/migo/`
  - Reports: `dc/reports/migo/`
