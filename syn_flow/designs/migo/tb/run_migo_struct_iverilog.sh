#!/usr/bin/env bash
set -euo pipefail

TB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TB_DIR/../../../.." && pwd)"
REPORT_DIR="${1:-$ROOT_DIR/report/func/migo}"
STRUCT_DIR="$REPORT_DIR/structure"
BUILD_DIR="$STRUCT_DIR/build"
LOG_DIR="$STRUCT_DIR/logs"
VECTOR_DIR="$STRUCT_DIR/vectors"
SUMMARY_CSV="$REPORT_DIR/migo_structure_validation.csv"
MIGO_STRUCT_SEED="${MIGO_STRUCT_SEED:-11}"
MIGO_STRUCT_CONST_CASES="${MIGO_STRUCT_CONST_CASES:-256}"

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$VECTOR_DIR"

python3 "$ROOT_DIR/psrc/gen_migo_struct_vectors.py" \
  --out-dir "$VECTOR_DIR" \
  --const-cases "$MIGO_STRUCT_CONST_CASES" \
  --seed "$MIGO_STRUCT_SEED" >"$LOG_DIR/gen_migo_struct_vectors.log"

run_test() {
  local tb_name="$1"
  local vec_file="$2"
  local sim_out="$BUILD_DIR/${tb_name}.out"
  local compile_log="$LOG_DIR/${tb_name}_compile.log"
  local sim_log="$LOG_DIR/${tb_name}.log"

  if ! (
    cd "$ROOT_DIR"
    iverilog -g2012 -s "$tb_name" -o "$sim_out" \
      -f "$ROOT_DIR/flow/filelists/migo.f" \
      "$TB_DIR/${tb_name}.sv"
  ) >"$compile_log" 2>&1; then
    echo "[MIGO-STRUCT][FAIL] iverilog compile failed (log: $compile_log)"
    tail -n 80 "$compile_log" || true
    exit 1
  fi

  if ! vvp "$sim_out" +VECTOR_FILE="$vec_file" | tee "$sim_log"; then
    echo "[MIGO-STRUCT][FAIL] simulation exited with error ($tb_name)"
    exit 1
  fi

  if ! grep -q "\[MIGO-STRUCT\]\[PASS\]" "$sim_log"; then
    echo "[MIGO-STRUCT][FAIL] self-check failed ($tb_name)"
    exit 1
  fi
}

run_test "tb_migo_const_coeff_mac" "$VECTOR_DIR/const_coeff_mac.vec"
run_test "tb_migo_round_shift" "$VECTOR_DIR/round_shift.vec"

python3 "$ROOT_DIR/psrc/migo_structure_table_gen.py" \
  --log-dir "$LOG_DIR" \
  --output-csv "$SUMMARY_CSV"

echo "[MIGO-STRUCT][OK] summary=$SUMMARY_CSV"
