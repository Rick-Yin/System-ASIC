# RWKVCNN RTL

## Regenerate ROM/package

```powershell
python psrc/tools/gen_rwkv_sv_rom.py
```

This regenerates:
- `vsrc/Joint-CFR-DPD/include/rwkvcnn_pkg.sv`
- `vsrc/Joint-CFR-DPD/rom/rwkv_tensor_map.sv`
- `vsrc/Joint-CFR-DPD/rom/rwkv_rom_bank.sv`

## Top module

- Top: `vsrc/Joint-CFR-DPD/top/rwkvcnn_top.sv`
- Interface: valid/ready stream with packed 32-bit lanes per vector element
- Data path: integer RWKVCNN path (`input_proj -> 2x(att+ffn) -> output_proj`)

## Top vector regression

```bash
bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh
```

This flow will:
- Use `iverilog + vvp` only (no verilator fallback)
- Generate packed top vectors from `RWKVCNN_Quan.forward_int`:
  - `report/joint_top/vectors/input_packed.vec`
  - `report/joint_top/vectors/golden_output_packed.vec`
- Run `tb_rwkvcnn_top_vec.sv` self-check on `rwkvcnn_top`
- Dump RTL outputs to:
  - `report/joint_top/logs/rtl_output_packed.vec`
- Report BER/MAE CSV to `report/joint_top/rtl_ber_eval.csv`

Profiles:

```bash
TOP_PROFILE=smoke bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_smoke
TOP_PROFILE=medium bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_medium
TOP_PROFILE=full bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_full
```

Run the new validation bundle:

```bash
bash vsrc/Joint-CFR-DPD/tb/top/run_top_validation.sh report/joint_top_validation
```

This runs:
- `linear_engine_rom` directed unit regression
- `div_rne_su` directed unit regression
- `rwkvcnn_top` smoke / medium / full vector regressions
- stage coverage and richer timeout/state diagnostics inside `tb_rwkvcnn_top_vec.sv`

Useful overrides:

```bash
TOP_PROFILE=smoke TOP_MAX_FRAME_LATENCY=2000 TOP_TIMEOUT_CYCLES=20000 bash vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh report/joint_top_debug
```

## L0 operator regression

```bash
bash vsrc/Joint-CFR-DPD/tb/l0_ops/run_l0_iverilog.sh
```

## Local Yosys pre-synthesis

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0
```

This generates frontend checkpoints and trend reports under `report/yosys/`.

## One-click local run

```bash
bash run_all_frontend.sh
```

This writes all local regression outputs plus Yosys frontend checkpoints under `report/<tag>/`.

## External DC/PT

- Signoff synthesis/timing analysis is run in external `dc + pt` flow.
- Functional simulation is not rerun in that flow (no VCS path in this repo).

## Notes

- `hardsigmoid` uses integer approximation `clamp(x/6 + 1/2, 0, 1)`.
- LUT / WKV metadata come from `manifest.json` exported values.
