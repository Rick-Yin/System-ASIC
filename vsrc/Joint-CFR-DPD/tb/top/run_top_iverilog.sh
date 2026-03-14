#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
if [[ -f "$ROOT_DIR/tools/activate_local_eda.sh" ]]; then
  source "$ROOT_DIR/tools/activate_local_eda.sh"
fi

detect_full_profile_frames() {
  local manifest_path="$ROOT_DIR/vsrc/rom/manifest.json"
  local fallback_frames="$1"

  if [[ ! -f "$manifest_path" ]]; then
    echo "$fallback_frames"
    return 0
  fi

  python3 - "$manifest_path" "$fallback_frames" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
fallback_frames = int(sys.argv[2])

try:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
except Exception:
    print(fallback_frames)
    raise SystemExit(0)

source_hint = f"{manifest.get('ckpt_path', '')} {manifest.get('export_root', '')}".upper()

if "HPA" in source_hint:
    print(261)
else:
    print(fallback_frames)
PY
}

TOP_PROFILE="${TOP_PROFILE:-full}"
case "$TOP_PROFILE" in
  smoke)
    default_frames=8
    default_mode=edge
    default_seed=1
    default_trace=1
    default_progress_cycles=5000
    ;;
  medium)
    default_frames=64
    default_mode=random
    default_seed=7
    default_trace=1
    default_progress_cycles=50000
    ;;
  full)
    default_frames="$(detect_full_profile_frames 256)"
    default_mode=random
    default_seed=1
    default_trace=0
    default_progress_cycles=250000
    ;;
  *)
    echo "[TOP][FAIL] unsupported TOP_PROFILE=$TOP_PROFILE"
    exit 1
    ;;
esac

DEFAULT_REPORT_DIR="$ROOT_DIR/report/func/joint_top"
if [[ -z "${1:-}" && "$TOP_PROFILE" != "full" ]]; then
  DEFAULT_REPORT_DIR="$ROOT_DIR/report/func/joint_top_${TOP_PROFILE}"
fi

TB_DIR="$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top"
REPORT_DIR="${1:-$DEFAULT_REPORT_DIR}"
BUILD_DIR="$REPORT_DIR/build"
LOG_DIR="$REPORT_DIR/logs"
VECTOR_DIR="$REPORT_DIR/vectors"

mkdir -p "$BUILD_DIR" "$LOG_DIR" "$VECTOR_DIR"

# Keep RTL package / ROM outputs in sync with the latest exported manifest and bins.
python3 "$ROOT_DIR/psrc/tools/gen_rwkv_sv_rom.py"

TOP_FRAMES="${TOP_FRAMES:-$default_frames}"
TOP_MODE="${TOP_MODE:-$default_mode}"
TOP_SEED="${TOP_SEED:-$default_seed}"
TOP_STATELESS="${TOP_STATELESS:-0}"
TOP_TRACE_PROGRESS="${TOP_TRACE_PROGRESS:-$default_trace}"
TOP_ENABLE_WAVE="${TOP_ENABLE_WAVE:-0}"
TOP_PROGRESS_CYCLES="${TOP_PROGRESS_CYCLES:-$default_progress_cycles}"
TOP_RUN_BER="${TOP_RUN_BER:-1}"

gen_cmd=(
  python3 "$ROOT_DIR/psrc/gen_golden_from_rwkv_quan.py"
  --out-dir "$VECTOR_DIR"
  --frames "$TOP_FRAMES"
  --mode "$TOP_MODE"
  --seed "$TOP_SEED"
)
if [[ "$TOP_STATELESS" == "1" ]]; then
  gen_cmd+=(--stateless)
fi
"${gen_cmd[@]}"

SIM_OUT="$BUILD_DIR/tb_rwkvcnn_top_vec.out"
LOG_FILE="$LOG_DIR/tb_rwkvcnn_top_vec.log"
IVERILOG_COMPILE_LOG="$LOG_DIR/iverilog_compile.log"
INPUT_VEC_FILE="$VECTOR_DIR/input_packed.vec"
GOLDEN_VEC_FILE="$VECTOR_DIR/golden_output_packed.vec"
OUTPUT_VEC_FILE="$LOG_DIR/rtl_output_packed.vec"
DUMP_VCD_FILE="$LOG_DIR/tb_rwkvcnn_top_vec.vcd"

echo "[TOP][CFG] profile=$TOP_PROFILE frames=$TOP_FRAMES mode=$TOP_MODE seed=$TOP_SEED stateless=$TOP_STATELESS trace=$TOP_TRACE_PROGRESS wave=$TOP_ENABLE_WAVE"

if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "[TOP][FAIL] iverilog/vvp not found in PATH"
  exit 1
fi

if ! iverilog -g2012 -o "$SIM_OUT" \
  -f "$ROOT_DIR/flow/filelists/joint.f" \
  "$TB_DIR/tb_rwkvcnn_top_vec.sv" >"$IVERILOG_COMPILE_LOG" 2>&1; then
  echo "[TOP][FAIL] iverilog compile failed (log: $IVERILOG_COMPILE_LOG)"
  tail -n 80 "$IVERILOG_COMPILE_LOG" || true
  exit 1
fi

sim_args=(
  +INPUT_VEC_FILE="$INPUT_VEC_FILE"
  +GOLDEN_VEC_FILE="$GOLDEN_VEC_FILE"
  +OUTPUT_VEC_FILE="$OUTPUT_VEC_FILE"
  +NUM_TEST_FRAMES="$TOP_FRAMES"
  +TRACE_PROGRESS="$TOP_TRACE_PROGRESS"
  +ENABLE_WAVE="$TOP_ENABLE_WAVE"
  +PROGRESS_CYCLES="$TOP_PROGRESS_CYCLES"
  +DUMP_VCD_FILE="$DUMP_VCD_FILE"
)
if [[ -n "${TOP_MAX_FRAME_LATENCY:-}" ]]; then
  sim_args+=(+MAX_FRAME_LATENCY="$TOP_MAX_FRAME_LATENCY")
fi
if [[ -n "${TOP_TIMEOUT_CYCLES:-}" ]]; then
  sim_args+=(+TIMEOUT_CYCLES="$TOP_TIMEOUT_CYCLES")
fi

if ! vvp "$SIM_OUT" "${sim_args[@]}" | tee "$LOG_FILE"; then
  echo "[TOP][FAIL] simulation exited with error"
  exit 1
fi

if ! grep -q "\[TOP\]\[PASS\]" "$LOG_FILE"; then
  echo "[TOP][FAIL] top vector self-check failed"
  exit 1
fi

if [[ "$TOP_RUN_BER" == "1" ]]; then
  python3 "$ROOT_DIR/psrc/rtl_ber_eval.py" \
    --ref "$GOLDEN_VEC_FILE" \
    --rtl "$OUTPUT_VEC_FILE" \
    --output-csv "$REPORT_DIR/rtl_ber_eval.csv" | tee "$LOG_DIR/rtl_ber_eval.log"
fi

echo "[TOP][OK] top vector regression passed"
