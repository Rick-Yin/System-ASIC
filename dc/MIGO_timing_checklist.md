# MIGO-filter Timing Bottleneck Checklist

Use this after `source dc/run_migo_dc.tcl`.

## 1) First-pass diagnosis

1. Open `dc/reports/migo/timing_max_20.rpt` and find repeated logic cones.
2. Check if worst paths repeatedly traverse:
   - `x_symm` pre-adder chain
   - constant multiply terms (`*3, *5, *7, *11, *26, *49, *57`)
   - final accumulation + rounding shift
3. Confirm whether most violations are in max-delay (setup) rather than min-delay.

## 2) Report files to inspect

- `dc/reports/migo/qor.rpt`
- `dc/reports/migo/area_hier.rpt`
- `dc/reports/migo/timing_max_20.rpt`
- `dc/reports/migo/constraint_violators.rpt`

## 3) Typical structural fixes (priority order)

1. Insert pipeline registers between pre-add, constant-mul, and final add-tree stages.
2. Rebalance add tree depth (avoid long serial accumulation).
3. Convert constant multipliers into shift-add trees with balanced stages.
4. Keep valid/data pipeline alignment explicit when adding stages.
5. Re-run synthesis at the same 2.0ns constraint and compare WNS/TNS deltas.

## 4) Compare against Joint-CFR-DPD baseline

Run:

```powershell
python psrc/dc_split_qor_summary.py --reports-root dc/reports
```

Use this to decide whether MIGO requires architectural pipelining before system-level integration.
