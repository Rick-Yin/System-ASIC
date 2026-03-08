#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GENERATED_DIRS=(
  "report"
  "flow/yosys/out"
  "flow/yosys/reports"
  "vsrc/Joint-CFR-DPD/tb/top/build"
  "vsrc/Joint-CFR-DPD/tb/top/logs"
  "vsrc/Joint-CFR-DPD/tb/top/vectors"
  "vsrc/Joint-CFR-DPD/tb/l0_ops/build"
  "vsrc/Joint-CFR-DPD/tb/l0_ops/logs"
  "vsrc/Joint-CFR-DPD/tb/l0_ops/vectors"
  "dc/designs/migo/tb/build"
  "dc/designs/migo/tb/logs"
  "psrc/__pycache__"
  "psrc/tools/__pycache__"
)

for rel_dir in "${GENERATED_DIRS[@]}"; do
  abs_dir="$ROOT_DIR/$rel_dir"
  if [[ -e "$abs_dir" ]]; then
    rm -rf "$abs_dir"
    echo "[CLEAN] removed $rel_dir"
  fi
done

echo "[CLEAN] done"
