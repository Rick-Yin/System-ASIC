#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TB_DIR="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top"
REPORT_DIR="${1:-$ROOT_DIR/report/joint_top}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"
VECTOR_DIR="$REPORT_DIR/vectors"

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$VECTOR_DIR"

python3 "$ROOT_DIR/psrc/gen_golden_from_rwkv_quan.py" --out-dir "$VECTOR_DIR"

SIM_OUT="$BUILD_DIR/tb_rwkvcnn_top_vec.out"
LOG_FILE="$LOG_DIR/tb_rwkvcnn_top_vec.log"
IVERILOG_COMPILE_LOG="$LOG_DIR/iverilog_compile.log"
INPUT_VEC_FILE="$VECTOR_DIR/input_packed.vec"
GOLDEN_VEC_FILE="$VECTOR_DIR/golden_output_packed.vec"
OUTPUT_VEC_FILE="$LOG_DIR/rtl_output_packed.vec"

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "[TOP][FAIL] iverilog/vvp not found in PATH"
  exit 1
fi

if ! iverilog -g2012 -o "$SIM_OUT" \
  -f "$ROOT_DIR/flow/filelists/joint.f" \
  "$TB_DIR/tb_rwkvcnn_top_vec.sv" >"$IVERILOG_COMPILE_LOG" 2>&1; then
  echo "[TOP][FAIL] iverilog compile failed (log: $IVERILOG_COMPILE_LOG)"
  tail -n 80 "$IVERILOG_COMPILE_LOG" || true
  exit 1
fi

if ! vvp "$SIM_OUT" \
  +INPUT_VEC_FILE="$INPUT_VEC_FILE" \
  +GOLDEN_VEC_FILE="$GOLDEN_VEC_FILE" \
  +OUTPUT_VEC_FILE="$OUTPUT_VEC_FILE" | tee "$LOG_FILE"; then
  echo "[TOP][FAIL] simulation exited with error"
  exit 1
fi

if ! grep -q "\[TOP\]\[PASS\]" "$LOG_FILE"; then
  echo "[TOP][FAIL] top vector self-check failed"
  exit 1
fi

python3 "$ROOT_DIR/psrc/rtl_ber_eval.py" \
  --ref "$GOLDEN_VEC_FILE" \
  --rtl "$OUTPUT_VEC_FILE" \
  --output-csv "$REPORT_DIR/rtl_ber_eval.csv" | tee "$LOG_DIR/rtl_ber_eval.log"

echo "[TOP][OK] top vector regression passed"
