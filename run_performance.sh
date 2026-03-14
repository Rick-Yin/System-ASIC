#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
msrc_dir="$repo_root/msrc"

matlab_exe=""
if [[ -x /mnt/d/Software/Matlab/bin/matlab.exe ]]; then
    matlab_exe="/mnt/d/Software/Matlab/bin/matlab.exe"
elif command -v matlab >/dev/null 2>&1; then
    matlab_exe="$(command -v matlab)"
else
    echo "MATLAB executable not found. Expected /mnt/d/Software/Matlab/bin/matlab.exe or matlab in PATH." >&2
    exit 127
fi

mode="full"
case_id="migo_joint_cfr_dpd"
report_root="$repo_root/report/exp"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --smoke)
            mode="smoke"
            shift
            ;;
        --full)
            mode="full"
            shift
            ;;
        --case)
            case_id="${2:?missing value for --case}"
            shift 2
            ;;
        --report-root)
            report_root="${2:?missing value for --report-root}"
            shift 2
            ;;
        -h|--help)
            cat <<'EOF'
Usage: run_performance.sh [--full] [--smoke] [--case CASE_ID] [--report-root DIR]

Defaults:
  --full                     Run the full MCS=5/9/13 performance flow.
  --smoke                    Run a single-case smoke test.
  --case migo_joint_cfr_dpd  Smoke-test case id. Ignored in full mode.
  --report-root DIR          Artifact root for generated figures/tables.
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

matlab_sd="$(wslpath -w "$msrc_dir")"

if [[ "$mode" == "smoke" ]]; then
    export SYSTEM_ASIC_MCS_VALUES=5
    export SYSTEM_ASIC_SNR_RANGE='-5,15'
    export SYSTEM_ASIC_CASE_IDS="$case_id"
    export SYSTEM_ASIC_GENERATE_PAPER_ARTIFACTS=0
    export SYSTEM_ASIC_REPORT_ROOT="$repo_root/report/exp_smoke"
    echo "Running smoke test: case=$case_id, MCS=5, SNR={-5,15}"
else
    unset SYSTEM_ASIC_CASE_IDS || true
    unset SYSTEM_ASIC_SNR_RANGE || true
    unset SYSTEM_ASIC_GENERATE_PAPER_ARTIFACTS || true
    export SYSTEM_ASIC_MCS_VALUES='5,9,13'
    export SYSTEM_ASIC_REPORT_ROOT="$report_root"
    echo "Running full performance flow: MCS={5,9,13}"
fi

"$matlab_exe" -sd "$matlab_sd" -batch "main"
