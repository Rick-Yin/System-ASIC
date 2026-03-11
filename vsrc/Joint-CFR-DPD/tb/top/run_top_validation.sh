#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
REPORT_DIR="${1:-$ROOT_DIR/report/joint_top_validation}"
CORE_REPORT_DIR="$REPORT_DIR/core"
PROFILES_STRING="${TOP_VALIDATION_PROFILES:-smoke medium full}"

if [[ -f "$ROOT_DIR/tools/activate_local_eda.sh" ]]; then
  source "$ROOT_DIR/tools/activate_local_eda.sh"
fi

mkdir -p "$REPORT_DIR"

echo "[TOP-VAL][RUN] linear_engine_rom"
bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/core/run_core_iverilog.sh" "$CORE_REPORT_DIR"

for profile in $PROFILES_STRING; do
  echo "[TOP-VAL][RUN] profile=$profile"
  TOP_PROFILE="$profile" bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh" "$REPORT_DIR/$profile"
done

echo "[TOP-VAL][OK] completed profiles: $PROFILES_STRING"
