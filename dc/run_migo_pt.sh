#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash dc/run_migo_pt.sh <tag>"
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TAG="$1"

export TOP_MODULE="MIGO_method_migo_n_65_q_bit_8_wp_pi_0_2_width_pi_0_02_alpha_p_0_1_alpha_s_0_01_lam1_0_01_lam2_0_1_e_topk_1_e_d_max_2_e_e_max_0"
export TB_FILE="$ROOT_DIR/dc/designs/migo/tb/tb_migo_saif.sv"
export TB_TOP="tb_migo_saif"
export OUTPUT_FILE="$ROOT_DIR/dc/runs/migo/$RUN_TAG/power/migo_output.vec"

exec "$ROOT_DIR/dc/common/run_pt.sh" migo "$RUN_TAG"
