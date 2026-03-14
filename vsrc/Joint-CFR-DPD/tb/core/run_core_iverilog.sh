#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
if [[ -f "$ROOT_DIR/tools/activate_local_eda.sh" ]]; then
  source "$ROOT_DIR/tools/activate_local_eda.sh"
fi

TB_DIR="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/core"
REPORT_DIR="${1:-$ROOT_DIR/report/func/core}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"

mkdir -p "$BUILD_DIR" "$LOG_DIR"

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "[LINROM][FAIL] iverilog/vvp not found in PATH"
  exit 1
fi

tests=(
  "tb_linear_engine_rom|LINROM|$ROOT_DIR/vsrc/Joint-CFR-DPD/common/quant_utils_pkg.sv $ROOT_DIR/vsrc/Joint-CFR-DPD/core/linear_engine_rom.sv $TB_DIR/tb_linear_engine_rom.sv"
  "tb_div_rne_su|DIVSU|$ROOT_DIR/vsrc/Joint-CFR-DPD/common/quant_utils_pkg.sv $ROOT_DIR/vsrc/Joint-CFR-DPD/common/div_rne_su.sv $TB_DIR/tb_div_rne_su.sv"
)

for test_spec in "${tests[@]}"; do
  IFS='|' read -r test_name pass_tag srcs <<<"$test_spec"
  sim_out="$BUILD_DIR/${test_name}.out"
  log_file="$LOG_DIR/${test_name}.log"
  compile_log="$LOG_DIR/${test_name}_compile.log"

  if ! iverilog -g2012 -o "$sim_out" $srcs >"$compile_log" 2>&1; then
    echo "[$pass_tag][FAIL] iverilog compile failed (log: $compile_log)"
    tail -n 80 "$compile_log" || true
    exit 1
  fi

  if ! vvp "$sim_out" | tee "$log_file"; then
    echo "[$pass_tag][FAIL] simulation exited with error"
    exit 1
  fi

  if ! grep -q "\\[$pass_tag\\]\\[PASS\\]" "$log_file"; then
    echo "[$pass_tag][FAIL] self-check failed"
    exit 1
  fi
done

echo "[CORE][OK] directed core regressions passed"
