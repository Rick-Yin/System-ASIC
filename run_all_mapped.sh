#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TAG="${1:-all_mapped_$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_ROOT="$ROOT_DIR/report/$RUN_TAG"
YOSYS_RUN_ROOT="$RUN_ROOT/yosys"

JOINT_CLOCKS="${JOINT_CLOCKS:-2.0}"
MIGO_CLOCKS="${MIGO_CLOCKS:-2.0}"

mkdir -p "$RUN_ROOT"

echo "[ALL] run_root=$RUN_ROOT"
echo "[ALL] joint_clocks=$JOINT_CLOCKS"
echo "[ALL] migo_clocks=$MIGO_CLOCKS"

echo "[ALL] Joint top regression"
bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh" "$RUN_ROOT/joint_top"

echo "[ALL] Joint L0 regression"
bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/l0_ops/run_l0_iverilog.sh" "$RUN_ROOT/l0"

echo "[ALL] MIGO regression"
bash "$ROOT_DIR/dc/designs/migo/tb/run_migo_iverilog.sh" "$RUN_ROOT/migo"

echo "[ALL] Joint frontend Yosys"
bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow joint \
  --mode frontend \
  --clocks "$JOINT_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag joint_frontend

echo "[ALL] Joint mapped Yosys (resume)"
bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow joint \
  --mode mapped \
  --clocks "$JOINT_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag joint_mapped \
  --resume-from-frontend "$YOSYS_RUN_ROOT/joint_frontend"

echo "[ALL] MIGO frontend Yosys"
bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow migo \
  --mode frontend \
  --clocks "$MIGO_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag migo_frontend

echo "[ALL] MIGO mapped Yosys (resume)"
bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow migo \
  --mode mapped \
  --clocks "$MIGO_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag migo_mapped \
  --resume-from-frontend "$YOSYS_RUN_ROOT/migo_frontend"

echo "[ALL][OK] complete"
echo "[ALL][OK] outputs under $RUN_ROOT"
