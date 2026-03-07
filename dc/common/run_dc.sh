#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash dc/common/run_dc.sh <design> [clock_ns] [tag]
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

if [[ $# -lt 1 || $# -gt 3 ]]; then
  usage
  exit 2
fi

DESIGN="$1"
CLOCK_NS="${2:-2.0}"
RUN_TAG="${3:-}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESIGN_DIR="$ROOT_DIR/dc/designs/$DESIGN"
CONFIG_FILE="$DESIGN_DIR/config.tcl"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "[DC][ERR] missing design config: $CONFIG_FILE"
  exit 2
fi

clock_tag="${CLOCK_NS//./p}"
if [[ -z "$RUN_TAG" ]]; then
  RUN_TAG="${DESIGN}_clk${clock_tag}_$(date -u +%Y%m%dT%H%M%SZ)"
fi

RUN_ROOT="$ROOT_DIR/dc/runs/$DESIGN/$RUN_TAG"
mkdir -p "$RUN_ROOT"/{dc,logs,mapped,power,reports}

: "${BSUB_PREFIX:=bsub -Is -XF}"
: "${DC_SHELL_BIN:=/tools/synopsys/syn/R-2020.09-SP3a/bin/dc_shell}"
: "${TARGET_LIB:=/dx_s702/vol_s702a0_dev/tsmc22ull/sylincom/STDCELL/tcbn22ullbwp7t35p140_110b/TSMCHOME/digital/Front_End/timing_power_noise/CCS/tcbn22ullbwp7t35p140_110b/tcbn22ullbwp7t35p140ssg0p72vm40c_ccs.db}"
: "${LINK_LIB:=$TARGET_LIB}"
: "${SEARCH_PATHS:=}"
: "${MAX_CORES:=1}"

export REPO_ROOT="$ROOT_DIR"
export DESIGN_CONFIG="$CONFIG_FILE"
export RUN_ROOT
export CLOCK_NS
export TARGET_LIB
export LINK_LIB
export SEARCH_PATHS
export MAX_CORES

LOG_FILE="$RUN_ROOT/logs/dc_shell.log"
DC_TCL="$ROOT_DIR/dc/common/dc_main.tcl"

echo "[DC] design=$DESIGN"
echo "[DC] clock_ns=$CLOCK_NS"
echo "[DC] run_root=$RUN_ROOT"

(
  cd "$RUN_ROOT/dc"
  run_with_optional_bsub "$LOG_FILE" "$DC_SHELL_BIN" -f "$DC_TCL"
)

echo "[DC][OK] finished: $RUN_ROOT"
