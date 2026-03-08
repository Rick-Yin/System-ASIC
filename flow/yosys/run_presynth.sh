#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_LIBERTY="$ROOT_DIR/lib/gscl45nm/gscl45nm.lib"

FLOW="joint"
MODE=""
CLOCKS_CSV="2.0,2.5,3.0"
LIBERTY_PATH="${OSS_LIBERTY:-$DEFAULT_LIBERTY}"
RUN_TAG=""
REPORT_ROOT=""
ALLOW_UNSUPPORTED_YOSYS=0

MIGO_TOP="MIGO_method_migo_n_161_q_bit_8_wp_pi_0_047_width_pi_0_031_alpha_p_0_1_alpha_s_0_1_lam1_1_2_lam2_1_e_topk_4_e_d_max_2_e_e_max_4"

usage() {
  cat <<'EOF'
Usage:
  bash flow/yosys/run_presynth.sh [options]

Options:
  --flow <joint|migo>             Design flow to run (default: joint)
  --mode <frontend|mapped>        Run mode (default: joint->frontend, migo->mapped)
  --clocks <csv>                  Clock sweep in ns, e.g. 2.0,2.5,3.0
  --liberty <path>                Liberty .lib path
  --tag <name>                    Output tag (default: <flow>_<utc timestamp>)
  --report-root <path>            Root directory for generated reports/artifacts
  --allow-unsupported-yosys       Skip SystemVerilog capability probe
  -h, --help                      Show help

Examples:
  bash flow/yosys/run_presynth.sh --flow joint --mode frontend --clocks 2.0
  bash flow/yosys/run_presynth.sh --flow migo --mode mapped --clocks 2.0,2.5,3.0
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --flow)
        FLOW="${2:-}"
        shift 2
        ;;
      --mode)
        MODE="${2:-}"
        shift 2
        ;;
      --clocks)
        CLOCKS_CSV="${2:-}"
        shift 2
        ;;
      --liberty)
        LIBERTY_PATH="${2:-}"
        shift 2
        ;;
      --tag)
        RUN_TAG="${2:-}"
        shift 2
        ;;
      --report-root)
        REPORT_ROOT="${2:-}"
        shift 2
        ;;
      --allow-unsupported-yosys)
        ALLOW_UNSUPPORTED_YOSYS=1
        shift 1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "[OSS][ERR] Unknown option: $1"
        usage
        exit 2
        ;;
    esac
  done
}

probe_yosys_sv_support() {
  local probe_sv
  probe_sv="$(mktemp /tmp/yosys_probe_XXXXXX.sv)"
  cat >"$probe_sv" <<'SV'
package probe_pkg;
  localparam int P = 1;
endpackage

module probe #(parameter int W = 4) (
  input  logic clk,
  output logic [W-1:0] q
);
  import probe_pkg::*;
  always_ff @(posedge clk) q <= '0;
endmodule
SV

  local ok=0
  if yosys -q -p "plugin -i slang; read_slang $probe_sv; hierarchy -top probe; proc; check" >/dev/null 2>&1; then
    ok=1
  fi
  rm -f "$probe_sv"
  [[ "$ok" -eq 1 ]]
}

collect_rtl_files() {
  local filelist="$1"
  sed -E 's/#.*$//' "$filelist" \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

ns_to_ps() {
  local clk_ns="$1"
  python3 - "$clk_ns" <<'PY'
import sys
print(int(round(float(sys.argv[1]) * 1000.0)))
PY
}

normalize_clock_list() {
  local raw="$1"
  local token
  IFS=',' read -r -a _TOKENS <<<"$raw"
  CLOCKS_NS=()
  for token in "${_TOKENS[@]}"; do
    token="$(printf '%s' "$token" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [[ -z "$token" ]] && continue
    if [[ ! "$token" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
      echo "[OSS][ERR] Invalid clock value: $token"
      exit 2
    fi
    CLOCKS_NS+=("$token")
  done
  if [[ "${#CLOCKS_NS[@]}" -eq 0 ]]; then
    echo "[OSS][ERR] No valid clocks found in: $raw"
    exit 2
  fi
}

main() {
  parse_args "$@"

  if ! command -v yosys >/dev/null 2>&1; then
    echo "[OSS][ERR] yosys not found in PATH"
    exit 2
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "[OSS][ERR] python3 not found in PATH"
    exit 2
  fi

  local top_module
  local rtl_filelist
  case "$FLOW" in
    joint)
      top_module="rwkvcnn_top"
      rtl_filelist="$ROOT_DIR/flow/filelists/joint.f"
      if [[ -z "$MODE" ]]; then
        MODE="frontend"
      fi
      ;;
    migo)
      top_module="$MIGO_TOP"
      rtl_filelist="$ROOT_DIR/flow/filelists/migo.f"
      if [[ -z "$MODE" ]]; then
        MODE="mapped"
      fi
      ;;
    *)
      echo "[OSS][ERR] Unsupported flow: $FLOW"
      echo "[OSS][ERR] Use --flow joint or --flow migo"
      exit 2
      ;;
  esac

  if [[ "$MODE" != "frontend" && "$MODE" != "mapped" ]]; then
    echo "[OSS][ERR] Unsupported mode: $MODE"
    echo "[OSS][ERR] Use --mode frontend or --mode mapped"
    exit 2
  fi

  if [[ "$MODE" == "mapped" && ! -f "$LIBERTY_PATH" ]]; then
    echo "[OSS][ERR] Liberty file not found: $LIBERTY_PATH"
    exit 2
  fi

  if [[ ! -f "$rtl_filelist" ]]; then
    echo "[OSS][ERR] Missing filelist: $rtl_filelist"
    exit 2
  fi

  if [[ "$ALLOW_UNSUPPORTED_YOSYS" -eq 0 ]]; then
    if ! probe_yosys_sv_support; then
      echo "[OSS][ERR] Installed yosys cannot parse required SystemVerilog features via slang frontend."
      echo "[OSS][ERR] Ensure plugin load works: 'yosys -p \"plugin -i slang; help read_slang\"'."
      exit 2
    fi
  fi

  normalize_clock_list "$CLOCKS_CSV"

  mapfile -t rtl_rel_files < <(collect_rtl_files "$rtl_filelist")
  if [[ "${#rtl_rel_files[@]}" -eq 0 ]]; then
    echo "[OSS][ERR] Empty filelist: $rtl_filelist"
    exit 2
  fi

  local missing=0
  local rtl_abs_files=()
  local rel abs
  for rel in "${rtl_rel_files[@]}"; do
    abs="$ROOT_DIR/$rel"
    rtl_abs_files+=("$abs")
    if [[ ! -f "$abs" ]]; then
      echo "[OSS][ERR] Missing RTL from filelist: $rel"
      missing=1
    fi
  done
  if [[ "$missing" -ne 0 ]]; then
    exit 2
  fi

  if [[ -z "$RUN_TAG" ]]; then
    RUN_TAG="${FLOW}_${MODE}_$(date -u +%Y%m%dT%H%M%SZ)"
  fi
  if [[ -z "$REPORT_ROOT" ]]; then
    REPORT_ROOT="$ROOT_DIR/report/yosys"
  fi

  local run_root="$REPORT_ROOT/$RUN_TAG"
  mkdir -p "$run_root"

  echo "[OSS] flow=$FLOW top=$top_module"
  echo "[OSS] mode=$MODE"
  if [[ "$MODE" == "mapped" ]]; then
    echo "[OSS] liberty=$LIBERTY_PATH"
  fi
  echo "[OSS] clocks_ns=$CLOCKS_CSV"
  echo "[OSS] report_root=$run_root"

  local fail_count=0
  local clk clk_tag case_root abc_ps
  local ys_file log_file stat_file netlist_file json_file status_file abs_filelist
  for clk in "${CLOCKS_NS[@]}"; do
    clk_tag="$(printf '%s' "$clk" | tr '.' 'p')"
    case_root="$run_root/clk_${clk_tag}ns"
    mkdir -p "$case_root"

    ys_file="$case_root/run.ys"
    log_file="$case_root/yosys.log"
    stat_file="$case_root/stat.rpt"
    netlist_file="$case_root/${top_module}_syn.v"
    json_file="$case_root/${top_module}_syn.json"
    status_file="$case_root/status.txt"
    abs_filelist="$case_root/rtl_abs.f"
    printf "%s\n" "${rtl_abs_files[@]}" >"$abs_filelist"

    {
      echo "plugin -i slang"
      if [[ "$MODE" == "mapped" ]]; then
        echo "read_liberty -lib $LIBERTY_PATH"
      fi
      echo "read_slang -f $abs_filelist"
      echo "hierarchy -check -top $top_module"
      if [[ "$MODE" == "mapped" ]]; then
        echo "proc"
        echo "opt"
        echo "fsm"
        echo "opt"
        echo "memory"
        echo "opt"
        echo "techmap"
        echo "opt"
        abc_ps="$(ns_to_ps "$clk")"
        echo "dfflibmap -liberty $LIBERTY_PATH"
        echo "abc -liberty $LIBERTY_PATH -D $abc_ps"
        echo "clean"
        echo "tee -o $stat_file stat -liberty $LIBERTY_PATH -top $top_module"
        echo "check"
        echo "write_verilog -noattr $netlist_file"
      else
        echo "proc"
        echo "opt"
        echo "clean"
        echo "tee -o $stat_file stat -top $top_module"
        echo "check"
      fi
      echo "write_json $json_file"
    } >"$ys_file"

    if yosys -s "$ys_file" >"$log_file" 2>&1; then
      echo "pass" >"$status_file"
      echo "[OSS][PASS] clk=${clk}ns"
    else
      echo "fail" >"$status_file"
      echo "[OSS][FAIL] clk=${clk}ns (log: $log_file)"
      fail_count=$((fail_count + 1))
    fi
  done

  python3 "$ROOT_DIR/flow/yosys/oss_synth_qor_summary.py" \
    --reports-dir "$run_root" \
    --output-csv "$run_root/qor_summary.csv" \
    --top-module "$top_module" \
    --mode "$MODE"

  if [[ "$fail_count" -ne 0 ]]; then
    echo "[OSS][ERR] $fail_count run(s) failed in mode=$MODE. See reports under: $run_root"
    exit 3
  fi

  echo "[OSS][OK] Sweep finished (mode=$MODE). Summary:"
  echo "  - $run_root/qor_summary.csv"
}

main "$@"
