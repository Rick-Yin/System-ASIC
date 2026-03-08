#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TB_DIR="$ROOT_DIR/dc/designs/migo/tb"
REPORT_DIR="${1:-$ROOT_DIR/report/migo}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"
FILELIST="$ROOT_DIR/flow/filelists/migo.f"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

SIM_OUT="$BUILD_DIR/tb_migo_saif.out"
OUTPUT_VEC="$BUILD_DIR/migo_output.vec"
COMPILE_LOG="$LOG_DIR/iverilog_compile.log"
SIM_LOG="$LOG_DIR/tb_migo_saif.log"

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "[MIGO][FAIL] iverilog/vvp not found in PATH"
  exit 1
fi

if ! (
  cd "$ROOT_DIR"
  iverilog -g2012 -s tb_migo_saif -o "$SIM_OUT" -f "$FILELIST" "$TB_DIR/tb_migo_saif.sv"
) >"$COMPILE_LOG" 2>&1; then
  echo "[MIGO][FAIL] iverilog compile failed (log: $COMPILE_LOG)"
  tail -n 80 "$COMPILE_LOG" || true
  exit 1
fi

if ! vvp "$SIM_OUT" +OUTPUT_FILE="$OUTPUT_VEC" | tee "$SIM_LOG"; then
  echo "[MIGO][FAIL] simulation exited with error"
  exit 1
fi

if ! grep -q "\[MIGO\]\[PASS\]" "$SIM_LOG"; then
  echo "[MIGO][FAIL] self-check failed"
  exit 1
fi

echo "[MIGO][OK] iverilog regression passed"
echo "[MIGO][OK] output_vec=$OUTPUT_VEC"
