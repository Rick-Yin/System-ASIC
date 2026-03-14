#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash run_dc.sh [all|migo|joint_cfr] [clock_ns]

Examples:
  bash run_dc.sh
  bash run_dc.sh all 2.0
  bash run_dc.sh migo 1.5
  bash run_dc.sh joint_cfr 2.0
EOF
}

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/syn_flow" && pwd)"
TARGET="${1:-all}"
CLOCK_NS="${2:-2.0}"

run_one() {
  local design="$1"
  local script=""

  case "$design" in
    migo)
      script="$FLOW_DIR/run_migo_dc.sh"
      ;;
    joint_cfr)
      script="$FLOW_DIR/run_joint_dc.sh"
      ;;
    *)
      echo "[RUN-DC][ERR] unsupported design: $design"
      exit 2
      ;;
  esac

  echo "[RUN-DC] design=$design clock_ns=$CLOCK_NS"
  bash "$script" "$CLOCK_NS"
}

case "$TARGET" in
  all)
    run_one migo
    run_one joint_cfr
    ;;
  migo|joint_cfr)
    run_one "$TARGET"
    ;;
  -h|--help|help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

echo "[RUN-DC][OK] complete"
