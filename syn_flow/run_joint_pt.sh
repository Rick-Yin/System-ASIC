#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: bash syn_flow/run_joint_pt.sh"
  exit 2
fi

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FLOW_DIR/.." && pwd)"

export TOP_MODULE="rwkvcnn_top"
export TB_FILE="$FLOW_DIR/designs/joint_cfr/tb/tb_joint_saif.sv"
export TB_TOP="tb_joint_saif"
export TB_SUPPORT_FILES="$ROOT_DIR/vsrc/Joint-CFR-DPD/include/rwkvcnn_pkg.sv"
export PT_PREPARE_CMD="python3 \"$ROOT_DIR/psrc/gen_golden_from_rwkv_quan.py\""
export INPUT_VEC_FILE="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/vectors/input_packed.vec"
export GOLDEN_VEC_FILE="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/vectors/golden_output_packed.vec"
export OUTPUT_FILE="$FLOW_DIR/runs/joint_cfr/power/joint_gate_output.vec"

exec "$FLOW_DIR/common/run_pt.sh" joint_cfr
