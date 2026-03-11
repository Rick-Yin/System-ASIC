# System-ASIC Minimal Runbook

This repo currently supports three local entrypoints:

- `bash run_all_mapped.sh`
- `bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh`
- `bash flow/yosys/run_presynth.sh --flow <joint|migo> --mode mapped --clocks <ns>`

All local outputs are written under `report/`.

## Minimal Migration Setup

Copy the repository to the target server and make sure the following tools are available in `PATH`:

- `python3`
- `iverilog`
- `vvp`
- `yosys`

For Yosys runs, the installed Yosys must support:

- `plugin -i slang`
- `read_slang`
- `abc`

The default Liberty used by mapped synthesis is:

- `lib/gscl45nm/gscl45nm.lib`

If you want to override it on the target server:

```bash
export OSS_LIBERTY=/abs/path/to/library.lib
```

## One-Click Run

Run the full local flow:

```bash
bash run_all_mapped.sh
```

Or set a custom output tag:

```bash
bash run_all_mapped.sh my_run
```

Optional clock overrides:

```bash
JOINT_CLOCKS=2.0 MIGO_CLOCKS=2.0 bash run_all_mapped.sh my_run
```

Outputs land in:

- `report/<tag>/joint_top/`
- `report/<tag>/l0/`
- `report/<tag>/migo/`
- `report/<tag>/yosys/joint_frontend/`
- `report/<tag>/yosys/joint_mapped/`
- `report/<tag>/yosys/migo_frontend/`
- `report/<tag>/yosys/migo_mapped/`

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

Run only MIGO mapped synthesis:

```bash
bash flow/yosys/run_presynth.sh --flow migo --mode mapped --clocks 2.0 --report-root report/yosys --tag migo_mapped
```

Run only Joint mapped synthesis:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/yosys --tag joint_mapped
```

Resume Joint mapped synthesis from a completed frontend run:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode frontend --clocks 2.0 --report-root report/yosys --tag joint_frontend
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/yosys --tag joint_mapped --resume-from-frontend report/yosys/joint_frontend
```

Delete only a failed mapped result and rerun it from an existing frontend checkpoint:

```bash
rm -rf report/<tag>/yosys/joint_mapped
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/<tag>/yosys --tag joint_mapped --resume-from-frontend report/<tag>/yosys/joint_frontend
```

If you want to keep the old failed mapped directory for comparison, use a new mapped tag instead of deleting it:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/<tag>/yosys --tag joint_mapped_retry --resume-from-frontend report/<tag>/yosys/joint_frontend
```

## Notes

- `joint` mapped synthesis is much heavier than `migo` mapped synthesis and may require a higher-memory server.
- The one-click script runs `frontend` first, then `mapped --resume-from-frontend` for both `joint` and `migo`.
- CSV summaries are the only table-format exports kept by the local flow.
- Top validation supports `smoke`, `medium`, and `full` profiles via `TOP_PROFILE`, and `tb_rwkvcnn_top_vec.sv` now reports linear-stage coverage and richer timeout diagnostics.
- Top regression also accepts `TOP_MAX_FRAME_LATENCY` and `TOP_TIMEOUT_CYCLES` for bounded debug runs.
