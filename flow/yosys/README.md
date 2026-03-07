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

`joint` (default mode is `frontend`, good for structure/bottleneck analysis):

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0
```

`migo` (default mode is `mapped`, good for area/cell trend):

```bash
bash flow/yosys/run_presynth.sh --flow migo --clocks 2.0,2.5,3.0
```

Explicit mode selection:

```bash
bash flow/yosys/run_presynth.sh --flow joint --mode frontend --clocks 2.0
```

```bash
bash flow/yosys/run_presynth.sh --flow migo --mode mapped --clocks 2.0,2.5,3.0
```

Custom Liberty for mapped mode:

```bash
bash flow/yosys/run_presynth.sh --flow migo --mode mapped --liberty /abs/path/to/library.lib
```

## Outputs

- Netlists/JSON:
  - `flow/yosys/out/<tag>/clk_*ns/`
- Reports:
  - `flow/yosys/reports/<tag>/clk_*ns/yosys.log`
  - `flow/yosys/reports/<tag>/clk_*ns/stat.rpt`
  - `flow/yosys/reports/<tag>/qor_summary.csv`
  - `flow/yosys/reports/<tag>/qor_summary.md`

Summary columns include:

- `total_cells`, `total_area` (mapped mode mainly)
- `$mul`, `$div`, `$mux*` counts (`$mux* = $mux + $pmux + $bmux + $bwmux`, useful in frontend mode)
