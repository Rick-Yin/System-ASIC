#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
TB_DIR="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top"
BUILD_DIR="$TB_DIR/build"
LOG_DIR="$TB_DIR/logs"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

python3 "$ROOT_DIR/psrc/gen_golden_from_rwkv_quan.py"

SIM_OUT="$BUILD_DIR/tb_rwkvcnn_top_vec.out"
LOG_FILE="$LOG_DIR/tb_rwkvcnn_top_vec.log"
IVERILOG_COMPILE_LOG="$LOG_DIR/iverilog_compile.log"

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

if ! vvp "$SIM_OUT" | tee "$LOG_FILE"; then
  echo "[TOP][FAIL] simulation exited with error"
  exit 1
fi

if ! grep -q "\[TOP\]\[PASS\]" "$LOG_FILE"; then
  echo "[TOP][FAIL] top vector self-check failed"
  exit 1
fi

python3 "$ROOT_DIR/psrc/rtl_ber_eval.py" | tee "$LOG_DIR/rtl_ber_eval.log"

echo "[TOP][OK] top vector regression passed"
