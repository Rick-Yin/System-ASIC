#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash run_pt.sh [all|migo|joint_cfr]

Examples:
  bash run_pt.sh
  bash run_pt.sh all
  bash run_pt.sh migo
  bash run_pt.sh joint_cfr
EOF
}

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/syn_flow" && pwd)"
TARGET="${1:-all}"

run_one() {
  local design="$1"
  local script=""

  case "$design" in
    migo)
      script="$FLOW_DIR/run_migo_pt.sh"
      ;;
    joint_cfr)
      script="$FLOW_DIR/run_joint_pt.sh"
      ;;
    *)
      echo "[RUN-PT][ERR] unsupported design: $design"
      exit 2
      ;;
  esac

  echo "[RUN-PT] design=$design"
  bash "$script"
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

echo "[RUN-PT][OK] complete"
