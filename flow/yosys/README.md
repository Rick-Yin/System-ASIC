# Yosys Pre-Synthesis Flow

This flow is for local `yosys` trend exploration (clock/area/cell-count sweeps), not signoff.

## Requirements

- `yosys` with `slang` frontend plugin (`plugin -i slang`, `read_slang`)
- `python3`
- Liberty `.lib` (required for `mapped` mode)

Default Liberty in this repo:

- `lib/gscl45nm/gscl45nm.lib`

## Run

Recommended env:

```bash
source ~/tools/oss-cad-suite/environment
```

`joint` mapped:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0
```

`migo` mapped:

```bash
bash flow/yosys/run_presynth.sh --flow migo --mode mapped --clocks 2.0
```

Explicit mode selection:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/yosys
```

Custom Liberty for mapped mode:

```bash
bash flow/yosys/run_presynth.sh --flow migo --mode mapped --clocks 2.0 --liberty /abs/path/to/library.lib
```

Resume mapped from an existing frontend run root:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode frontend --clocks 2.0 --report-root report/yosys --tag joint_frontend
bash flow/yosys/run_presynth.sh --flow joint --mode mapped --clocks 2.0 --report-root report/yosys --tag joint_mapped --resume-from-frontend report/yosys/joint_frontend
```

## Outputs

- All generated artifacts go under:
  - `report/yosys/<tag>/`
- Per clock:
  - `report/yosys/<tag>/clk_*ns/run.ys`
  - `report/yosys/<tag>/clk_*ns/yosys.log`
  - `report/yosys/<tag>/clk_*ns/stat.rpt`
  - `report/yosys/<tag>/clk_*ns/checkpoint.il` (`frontend` mode; reusable by `mapped --resume-from-frontend`)
  - `report/yosys/<tag>/clk_*ns/*_syn.v`
  - `report/yosys/<tag>/clk_*ns/*_syn.json`
- Summary:
  - `report/yosys/<tag>/qor_summary.csv`

Summary CSV columns include:

- `total_cells`, `total_area` (mapped mode mainly)
- `$mul`, `$div`, `$mux*` counts (`$mux* = $mux + $pmux + $bmux + $bwmux`, useful in frontend mode)

## Cleanup

To remove generated Yosys outputs together with local regression byproducts:

```bash
bash clean_generated.sh
```
