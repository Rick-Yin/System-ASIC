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
  - `vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec`
  - `vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec`
- Run `tb_rwkvcnn_top_vec.sv` self-check on `rwkvcnn_top`
- Dump RTL outputs to:
  - `vsrc/Joint-CFR-DPD/tb/top/logs/rtl_output_packed.vec`
- Report BER/MAE via `psrc/rtl_ber_eval.py`

## L0 operator regression

```bash
bash vsrc/Joint-CFR-DPD/tb/l0_ops/run_l0_iverilog.sh
```

## Local Yosys pre-synthesis

```bash
bash flow/yosys/run_presynth.sh --flow joint --clocks 2.0,2.5,3.0
```

Default mapping library:

- `lib/gscl45nm/gscl45nm.lib`

## External DC/PT

- Signoff synthesis/timing analysis is run in external `dc + pt` flow.
- Functional simulation is not rerun in that flow (no VCS path in this repo).

## Notes

- `hardsigmoid` uses integer approximation `clamp(x/6 + 1/2, 0, 1)`.
- LUT / WKV metadata come from `manifest.json` exported values.
