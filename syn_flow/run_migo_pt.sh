#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 0 ]]; then
  echo "Usage: bash syn_flow/run_migo_pt.sh"
  exit 2
fi

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FLOW_DIR/.." && pwd)"

export TOP_MODULE="MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4"
export TB_FILE="$FLOW_DIR/designs/migo/tb/tb_migo_saif.sv"
export TB_TOP="tb_migo_saif"
export OUTPUT_FILE="$FLOW_DIR/runs/migo/power/migo_output.vec"

exec "$FLOW_DIR/common/run_pt.sh" migo
