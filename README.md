# System-ASIC Minimal Runbook

This repo currently supports three local entrypoints:

- `bash run_all_frontend.sh`
- `bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh`
- `bash flow/yosys/run_presynth.sh --flow <joint|migo> --clocks <ns>`

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
bash run_all_frontend.sh
```

Or set a custom output tag:

```bash
bash run_all_frontend.sh my_run
```

Optional clock overrides:

```bash
JOINT_CLOCKS=2.0 MIGO_CLOCKS=2.0 bash run_all_frontend.sh my_run
```

Outputs land in:

- `report/<tag>/joint_top/`
- `report/<tag>/l0/`
- `report/<tag>/migo/`
- `report/<tag>/yosys/joint_frontend/`
- `report/<tag>/yosys/migo_frontend/`

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
bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top
```

Run staged top validation profiles:

```bash
bash vsrc/Joint-CFR-DPD/tb/top/run_top_validation.sh report/joint_top_validation
```

Run only a fast smoke profile:

```bash
TOP_PROFILE=smoke bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_smoke
```

Run only Joint frontend synthesis:

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0 --report-root report/yosys --tag joint_frontend
```

Run only MIGO frontend synthesis:

```bash
bash flow/yosys/run_presynth.sh --flow migo --clocks 2.0 --report-root report/yosys --tag migo_frontend
```

## Notes

- The local Yosys flow is frontend-only and is intended for trend exploration plus reusable frontend checkpoints.
- CSV summaries are the only table-format exports kept by the local flow.
- Top validation supports `smoke`, `medium`, and `full` profiles via `TOP_PROFILE`, and `tb_rwkvcnn_top_vec.sv` now reports linear-stage coverage and richer timeout diagnostics.
- Top regression also accepts `TOP_MAX_FRAME_LATENCY` and `TOP_TIMEOUT_CYCLES` for bounded debug runs.
