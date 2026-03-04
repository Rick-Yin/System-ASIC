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

## Notes

- `hardsigmoid` uses integer approximation `clamp(x/6 + 1/2, 0, 1)`.
- LUT / WKV metadata come from `manifest.json` exported values.
