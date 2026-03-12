# Yosys Frontend Flow

This flow is for local `yosys` frontend trend exploration and checkpoint generation, not signoff.

## Requirements

- `yosys` with `slang` frontend plugin (`plugin -i slang`, `read_slang`)
- `python3`

If `slang` is unavailable, the script can fall back to `sv2v` when present in `PATH` or under `tools/sv2v/sv2v-Linux/sv2v`.

## Run

Recommended env:

```bash
source ~/tools/oss-cad-suite/environment
```

`joint` frontend:

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0
```

`migo` frontend:

```bash
bash flow/yosys/run_presynth.sh --flow migo --clocks 2.0
```

Custom report root and tag:

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0 --report-root report/yosys --tag joint_frontend
```

## Outputs

- All generated artifacts go under:
  - `report/yosys/<tag>/`
- Per clock:
  - `report/yosys/<tag>/clk_*ns/run.ys`
  - `report/yosys/<tag>/clk_*ns/yosys.log`
  - `report/yosys/<tag>/clk_*ns/stat.rpt`
  - `report/yosys/<tag>/clk_*ns/checkpoint.il`
  - `report/yosys/<tag>/clk_*ns/*_syn.json`
- Summary:
  - `report/yosys/<tag>/qor_summary.csv`

Summary CSV columns include:

- `total_cells`
- `$mul`, `$div`, `$mux*` counts (`$mux* = $mux + $pmux + $bmux + $bwmux`)
- `total_area` is kept for CSV compatibility and is typically `n/a` in frontend runs

## Cleanup

To remove generated Yosys outputs together with local regression byproducts:

```bash
bash clean_generated.sh
```
