#!/usr/bin/env bash
set -euo pipefail

TB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$TB_DIR/../../../.." && pwd)"
REPORT_DIR="${1:-$ROOT_DIR/report/func/migo}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"
VECTOR_DIR="$REPORT_DIR/vectors"
FILELIST="$ROOT_DIR/flow/filelists/migo.f"
MIGO_FRAMES="${MIGO_FRAMES:-512}"
MIGO_SEED="${MIGO_SEED:-1}"

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$VECTOR_DIR"

SIM_OUT="$BUILD_DIR/tb_migo_saif.out"
INPUT_VEC="$VECTOR_DIR/input_samples.vec"
GOLDEN_VEC="$VECTOR_DIR/golden_output.vec"
OUTPUT_VEC="$BUILD_DIR/migo_output.vec"
COMPILE_LOG="$LOG_DIR/iverilog_compile.log"
SIM_LOG="$LOG_DIR/tb_migo_saif.log"
EVAL_LOG="$LOG_DIR/migo_vec_eval.log"

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "[MIGO][FAIL] iverilog/vvp not found in PATH"
  exit 1
fi

python3 "$ROOT_DIR/psrc/gen_migo_vectors.py" \
  --out-dir "$VECTOR_DIR" \
  --frames "$MIGO_FRAMES" \
  --seed "$MIGO_SEED" >"$LOG_DIR/gen_migo_vectors.log"

if ! (
  cd "$ROOT_DIR"
  iverilog -g2012 -s tb_migo_saif -o "$SIM_OUT" -f "$FILELIST" "$TB_DIR/tb_migo_saif.sv"
) >"$COMPILE_LOG" 2>&1; then
  echo "[MIGO][FAIL] iverilog compile failed (log: $COMPILE_LOG)"
  tail -n 80 "$COMPILE_LOG" || true
  exit 1
fi

if ! vvp "$SIM_OUT" \
  +INPUT_FILE="$INPUT_VEC" \
  +GOLDEN_FILE="$GOLDEN_VEC" \
  +OUTPUT_FILE="$OUTPUT_VEC" | tee "$SIM_LOG"; then
  echo "[MIGO][FAIL] simulation exited with error"
  exit 1
fi

if ! grep -q "\[MIGO\]\[PASS\]" "$SIM_LOG"; then
  echo "[MIGO][FAIL] self-check failed"
  exit 1
fi

python3 "$ROOT_DIR/psrc/migo_vec_eval.py" \
  --ref "$GOLDEN_VEC" \
  --rtl "$OUTPUT_VEC" \
  --bits 9 \
  --output-csv "$REPORT_DIR/rtl_vec_eval.csv" \
  --require-exact | tee "$EVAL_LOG"

echo "[MIGO][OK] iverilog regression passed"
echo "[MIGO][OK] output_vec=$OUTPUT_VEC"
