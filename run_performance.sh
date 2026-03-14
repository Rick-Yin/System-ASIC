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
artifact_python="$repo_root/.venv/bin/python3"
artifact_script="$repo_root/psrc/generate_performance_artifacts.py"

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
escape_matlab_single_quotes() {
    printf "%s" "$1" | sed "s/'/''/g"
}

matlab_cmd=""
declare -a result_files=()

if [[ "$mode" == "smoke" ]]; then
    echo "Running smoke test: case=$case_id, MCS=5, SNR={-5,15}"
    matlab_cmd="setenv('SYSTEM_ASIC_MCS_VALUES','5'); setenv('SYSTEM_ASIC_SNR_RANGE','-5,15'); setenv('SYSTEM_ASIC_CASE_IDS','$(escape_matlab_single_quotes "$case_id")'); setenv('SYSTEM_ASIC_GENERATE_PAPER_ARTIFACTS','0'); setenv('SYSTEM_ASIC_REPORT_ROOT','$(escape_matlab_single_quotes "$report_root")'); main"
    result_files+=("$repo_root/data/BER-SNR/ber_compare_MCS_5_seed_0.mat")
else
    echo "Running full performance flow: MCS={5,9,13}"
    matlab_cmd="setenv('SYSTEM_ASIC_MCS_VALUES','5,9,13'); setenv('SYSTEM_ASIC_REPORT_ROOT','$(escape_matlab_single_quotes "$report_root")'); setenv('SYSTEM_ASIC_CASE_IDS',''); setenv('SYSTEM_ASIC_SNR_RANGE',''); setenv('SYSTEM_ASIC_GENERATE_PAPER_ARTIFACTS','0'); main"
    result_files+=(
        "$repo_root/data/BER-SNR/ber_compare_MCS_5_seed_0.mat"
        "$repo_root/data/BER-SNR/ber_compare_MCS_9_seed_0.mat"
        "$repo_root/data/BER-SNR/ber_compare_MCS_13_seed_0.mat"
    )
fi

"$matlab_exe" -sd "$matlab_sd" -batch "$matlab_cmd"

if [[ ! -x "$artifact_python" ]]; then
    echo "Artifact generator python not found: $artifact_python" >&2
    exit 127
fi

artifact_args=()
for result_file in "${result_files[@]}"; do
    artifact_args+=(--result "$result_file")
done

"$artifact_python" "$artifact_script" --report-root "$report_root" --key-snr-points "-5,15" "${artifact_args[@]}"

echo "Performance artifacts generated under: $report_root"
