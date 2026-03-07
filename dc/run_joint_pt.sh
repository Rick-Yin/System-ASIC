#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash dc/run_joint_pt.sh <tag>"
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TAG="$1"

export TOP_MODULE="rwkvcnn_top"
export TB_FILE="$ROOT_DIR/dc/designs/joint_cfr/tb/tb_joint_saif.sv"
export TB_TOP="tb_joint_saif"
export TB_SUPPORT_FILES="$ROOT_DIR/vsrc/Joint-CFR-DPD/include/rwkvcnn_pkg.sv"
export PT_PREPARE_CMD="python3 \"$ROOT_DIR/psrc/gen_golden_from_rwkv_quan.py\""
export INPUT_VEC_FILE="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec"
export GOLDEN_VEC_FILE="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec"
export OUTPUT_FILE="$ROOT_DIR/dc/runs/joint_cfr/$RUN_TAG/power/joint_gate_output.vec"

exec "$ROOT_DIR/dc/common/run_pt.sh" joint_cfr "$RUN_TAG"
