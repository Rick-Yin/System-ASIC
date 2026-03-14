#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TB_DIR="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/l0_ops"
REPORT_DIR="${1:-$ROOT_DIR/report/func/l0}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"
VECTOR_DIR="$REPORT_DIR/vectors"

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$VECTOR_DIR"

python3 "$ROOT_DIR/psrc/gen_l0_vectors.py" --out-dir "$VECTOR_DIR"

ops=(
  "sat_signed32"
  "rshift_rne64"
  "div_rne64"
  "requant_pow2_signed"
  "hardsigmoid_int_default"
  "wkv_lut_lookup"
)

failed=0
for op in "${ops[@]}"; do
  tb_name="tb_l0_${op}"
  tb_file="$TB_DIR/${tb_name}.sv"
  sim_out="$BUILD_DIR/${tb_name}.out"
  log_file="$LOG_DIR/${tb_name}.log"
  vector_file="$VECTOR_DIR/${op}.vec"

  echo "[L0][RUN] $tb_name"
  iverilog -g2012 -o "$sim_out" \
    "$ROOT_DIR/vsrc/Joint-CFR-DPD/common/quant_utils_pkg.sv" \
    "$TB_DIR/l0_case_pkg.sv" \
    "$tb_file"

  if ! vvp "$sim_out" +VECTOR_FILE="$vector_file" | tee "$log_file"; then
    failed=1
    continue
  fi

  if ! grep -q "\[L0\]\[PASS\]" "$log_file"; then
    failed=1
  fi
done

python3 "$ROOT_DIR/psrc/l0_table_gen.py" \
  --log-dir "$LOG_DIR" \
  --out-csv "$REPORT_DIR/l0_equivalence_table.csv" \
  --out-cov-csv "$REPORT_DIR/l0_equivalence_coverage.csv"

if [[ "$failed" -ne 0 ]]; then
  echo "[L0][FAIL] one or more operator tests failed"
  exit 1
fi

echo "[L0][OK] all operator tests passed"
