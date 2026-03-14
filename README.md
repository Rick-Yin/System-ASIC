# System-ASIC Minimal Runbook

This repo currently supports three local entrypoints:

- `bash run_func.sh`
- `bash run_dc.sh`
- `bash run_pt.sh`
- `bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh`
- `bash syn_flow/designs/migo/tb/run_migo_struct_iverilog.sh`

All local outputs are written under `report/`.

## Minimal Migration Setup

Copy the repository to the target server and make sure the following tools are available in `PATH`:

- `python3`
- `iverilog`
- `vvp`
- `yosys`

For Yosys frontend runs, the installed Yosys must support:

- `plugin -i slang`
- `read_slang`

If `slang` is unavailable, the script can fall back to `sv2v` when present in `PATH` or under `tools/sv2v/sv2v-Linux/sv2v`.

## One-Click Run

Run the full local flow:

```bash
bash run_func.sh
```

Run the Synopsys synthesis flow for both designs:

```bash
bash run_dc.sh
bash run_pt.sh
```

Or run only one design:

```bash
bash run_dc.sh migo 2.0
bash run_pt.sh migo
```

Or set a custom output tag:

```bash
bash run_func.sh my_run
```

Run only selected stages:

```bash
RUN_STAGES=migo_tb,migo_struct bash run_func.sh my_migo_only
```

Outputs land in:

- `report/<tag>/joint_top/`
- `report/<tag>/l0/`
- `report/<tag>/migo/`

## Minimal Validation Commands

Check toolchain:

```bash
python3 --version
iverilog -V
vvp -V
yosys -Q -p 'plugin -i slang; help read_slang'
```

Run only Joint functional regression:

```bash
bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/func/joint_top
```

Run only MIGO bit-exact regression:

```bash
bash syn_flow/designs/migo/tb/run_migo_iverilog.sh report/func/migo
```

Run only MIGO structure regression:

```bash
bash syn_flow/designs/migo/tb/run_migo_struct_iverilog.sh report/func/migo
```

Run staged top validation profiles:

```bash
bash vsrc/Joint-CFR-DPD/tb/top/run_top_validation.sh report/joint_top_validation
```

Run only a fast smoke profile:

```bash
TOP_PROFILE=smoke bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_smoke
```

## Notes

- `run_func.sh` now only runs functional validation stages.
- CSV summaries are the table-format exports kept by the local functional flow.
- Top validation supports `smoke`, `medium`, and `full` profiles via `TOP_PROFILE`, and `tb_rwkvcnn_top_vec.sv` now reports linear-stage coverage and richer timeout diagnostics.
- MIGO regression now generates deterministic input/golden vectors and writes a bit-exact summary to `report/<tag>/migo/rtl_vec_eval.csv`.
- MIGO structure regression writes `report/<tag>/migo/migo_structure_validation.csv`.
- Top regression also accepts `TOP_MAX_FRAME_LATENCY` and `TOP_TIMEOUT_CYCLES` for bounded debug runs.
