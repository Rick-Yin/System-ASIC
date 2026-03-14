#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash syn_flow/common/run_dc.sh <design> [clock_ns]
EOF
}

quote_cmd() {
  printf '%q ' "$@"
}

run_with_optional_bsub() {
  local log_file="$1"
  shift

  local cmd_str
  cmd_str="$(quote_cmd "$@")"

  if [[ -n "${BSUB_PREFIX// }" ]]; then
    eval "$BSUB_PREFIX $cmd_str" 2>&1 | tee "$log_file"
  else
    eval "$cmd_str" 2>&1 | tee "$log_file"
  fi
}

if [[ $# -lt 1 || $# -gt 2 ]]; then
  usage
  exit 2
fi

DESIGN="$1"
CLOCK_NS="${2:-2.0}"

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT_DIR="$(cd "$FLOW_DIR/.." && pwd)"
DESIGN_DIR="$FLOW_DIR/designs/$DESIGN"
CONFIG_FILE="$DESIGN_DIR/config.tcl"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[DC][ERR] missing design config: $CONFIG_FILE"
  exit 2
fi

RUN_ROOT="$FLOW_DIR/runs/$DESIGN"
mkdir -p "$RUN_ROOT"/{dc,logs,mapped,power,reports}

: "${BSUB_PREFIX:=bsub -Is -XF}"
: "${DC_SHELL_BIN:=/tools/synopsys/syn/R-2020.09-SP3a/bin/dc_shell}"
: "${TARGET_LIB:=/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db}"
: "${LINK_LIB:=$TARGET_LIB}"
: "${SEARCH_PATHS:=}"
: "${MAX_CORES:=1}"
: "${PYTHON_BIN:=python3}"

export REPO_ROOT="$ROOT_DIR"
export DESIGN_CONFIG="$CONFIG_FILE"
export RUN_ROOT
export CLOCK_NS
export TARGET_LIB
export LINK_LIB
export SEARCH_PATHS
export MAX_CORES

LOG_FILE="$RUN_ROOT/logs/dc_shell.log"
DC_TCL="$FLOW_DIR/common/dc_main.tcl"

echo "[DC] design=$DESIGN"
echo "[DC] clock_ns=$CLOCK_NS"
echo "[DC] run_root=$RUN_ROOT"

(
  cd "$RUN_ROOT/dc"
  run_with_optional_bsub "$LOG_FILE" "$DC_SHELL_BIN" -f "$DC_TCL"
)

"$PYTHON_BIN" "$ROOT_DIR/psrc/export_syn_reports.py" \
  --mode dc \
  --repo-root "$ROOT_DIR" \
  --run-root "$RUN_ROOT" \
  --design "$DESIGN" \
  --clock-ns "$CLOCK_NS" \
  --config "$CONFIG_FILE"

echo "[DC][OK] finished: $RUN_ROOT"
