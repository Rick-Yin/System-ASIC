#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_TAG="${1:-all_mapped_$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_ROOT="$ROOT_DIR/report/$RUN_TAG"
YOSYS_RUN_ROOT="$RUN_ROOT/yosys"
MONITOR_ROOT="$RUN_ROOT/monitor"

JOINT_CLOCKS="${JOINT_CLOCKS:-2.0}"
MIGO_CLOCKS="${MIGO_CLOCKS:-2.0}"
MONITOR_INTERVAL_SEC="${MONITOR_INTERVAL_SEC:-5}"
TIME_BIN="${TIME_BIN:-/usr/bin/time}"

mkdir -p "$RUN_ROOT" "$MONITOR_ROOT"

timestamp_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

resolve_executable() {
  local candidate="$1"
  if [[ "$candidate" == */* ]]; then
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
    fi
    return 0
  fi
  type -P "$candidate" 2>/dev/null || true
}

read_cpu_fields() {
  awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9}' /proc/stat
}

append_pressure_snapshot() {
  local resource="$1"
  local pressure_file="/proc/pressure/$resource"
  if [[ -r "$pressure_file" ]]; then
    sed "s/^/$resource /" "$pressure_file"
  else
    printf '%s unavailable\n' "$resource"
  fi
}

append_root_status() {
  local target_pid="$1"
  local status_file="/proc/$target_pid/status"
  if [[ -r "$status_file" ]]; then
    awk '/^(Name|State|PPid|VmRSS|VmHWM|Threads):/ {print}' "$status_file"
  else
    printf 'pid %s status unavailable\n' "$target_pid"
  fi
}

collect_process_tree() {
  local target_pid="$1"
  if ! command -v ps >/dev/null 2>&1; then
    echo "ps unavailable"
    return 0
  fi

  local tree
  tree="$(
    ps -e -o pid=,ppid=,rss=,%cpu=,stat=,comm= \
      | awk -v root="$target_pid" '
          {
            pid = $1
            ppid[pid] = $2
            line[pid] = $0
          }
          END {
            for (pid in ppid) {
              cur = pid
              while (cur != "" && cur != 0) {
                if (cur == root) {
                  print line[pid]
                  break
                }
                cur = ppid[cur]
              }
            }
          }
        ' \
      | sort -k3,3nr
  )"

  echo "PID PPID RSS_KB %CPU STAT COMMAND"
  if [[ -z "$tree" ]]; then
    printf '(no processes found under pid %s)\n' "$target_pid"
    return 0
  fi

  printf '%s\n' "$tree" | awk 'NR <= 12 {print}'
  printf 'descendant_total_rss_kb: %s\n' "$(printf '%s\n' "$tree" | awk '{sum += $3} END {print sum + 0}')"
}

write_host_snapshot() {
  local outfile="$1"
  local target_pid="${2:-}"
  {
    printf 'timestamp_utc: %s\n' "$(timestamp_utc)"
    printf 'loadavg: %s\n' "$(cat /proc/loadavg)"
    echo "meminfo_kb:"
    awk '
      /^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree|CommitLimit|Committed_AS|Active\(anon\)|Inactive\(anon\)|AnonPages):/ {
        print
      }
    ' /proc/meminfo
    echo "pressure:"
    append_pressure_snapshot cpu
    append_pressure_snapshot memory
    append_pressure_snapshot io
    if [[ -n "$target_pid" ]]; then
      echo "root_status:"
      append_root_status "$target_pid"
      echo "process_tree:"
      collect_process_tree "$target_pid"
    fi
  } >"$outfile"
}

sample_host_state() {
  local target_pid="$1"
  local outfile="$2"
  local interval_sec="$3"
  local prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq prev_steal
  local cur_user cur_nice cur_system cur_idle cur_iowait cur_irq cur_softirq cur_steal

  if ! read -r prev_user prev_nice prev_system prev_idle prev_iowait prev_irq prev_softirq prev_steal < <(read_cpu_fields); then
    return 0
  fi

  while kill -0 "$target_pid" 2>/dev/null; do
    sleep "$interval_sec"
    if ! kill -0 "$target_pid" 2>/dev/null; then
      break
    fi
    if ! read -r cur_user cur_nice cur_system cur_idle cur_iowait cur_irq cur_softirq cur_steal < <(read_cpu_fields); then
      break
    fi

    local delta_user=$((cur_user - prev_user))
    local delta_nice=$((cur_nice - prev_nice))
    local delta_system=$((cur_system - prev_system))
    local delta_idle=$((cur_idle - prev_idle))
    local delta_iowait=$((cur_iowait - prev_iowait))
    local delta_irq=$((cur_irq - prev_irq))
    local delta_softirq=$((cur_softirq - prev_softirq))
    local delta_steal=$((cur_steal - prev_steal))
    local delta_total=$((delta_user + delta_nice + delta_system + delta_idle + delta_iowait + delta_irq + delta_softirq + delta_steal))

    local cpu_user_pct="0.0"
    local cpu_system_pct="0.0"
    local cpu_idle_pct="0.0"
    local cpu_iowait_pct="0.0"
    if (( delta_total > 0 )); then
      cpu_user_pct="$(awk -v v="$((delta_user + delta_nice))" -v t="$delta_total" 'BEGIN {printf "%.1f", (100.0 * v) / t}')"
      cpu_system_pct="$(awk -v v="$((delta_system + delta_irq + delta_softirq))" -v t="$delta_total" 'BEGIN {printf "%.1f", (100.0 * v) / t}')"
      cpu_idle_pct="$(awk -v v="$delta_idle" -v t="$delta_total" 'BEGIN {printf "%.1f", (100.0 * v) / t}')"
      cpu_iowait_pct="$(awk -v v="$delta_iowait" -v t="$delta_total" 'BEGIN {printf "%.1f", (100.0 * v) / t}')"
    fi

    {
      printf '===== %s =====\n' "$(timestamp_utc)"
      printf 'loadavg: %s\n' "$(cat /proc/loadavg)"
      printf 'cpu_pct: user=%s system=%s idle=%s iowait=%s\n' "$cpu_user_pct" "$cpu_system_pct" "$cpu_idle_pct" "$cpu_iowait_pct"
      echo "meminfo_kb:"
      awk '
        /^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree|CommitLimit|Committed_AS|Active\(anon\)|Inactive\(anon\)|AnonPages):/ {
          print
        }
      ' /proc/meminfo
      echo "pressure:"
      append_pressure_snapshot cpu
      append_pressure_snapshot memory
      append_pressure_snapshot io
      echo "root_status:"
      append_root_status "$target_pid"
      echo "process_tree:"
      collect_process_tree "$target_pid"
      echo
    } >>"$outfile"

    prev_user="$cur_user"
    prev_nice="$cur_nice"
    prev_system="$cur_system"
    prev_idle="$cur_idle"
    prev_iowait="$cur_iowait"
    prev_irq="$cur_irq"
    prev_softirq="$cur_softirq"
    prev_steal="$cur_steal"
  done
}

capture_dmesg_tail() {
  local outfile="$1"
  if command -v dmesg >/dev/null 2>&1 && dmesg --ctime 2>/dev/null | tail -n 200 >"$outfile"; then
    return 0
  fi
  echo "dmesg unavailable or access denied" >"$outfile"
}

if [[ ! -x "$TIME_BIN" ]]; then
  resolved_time_bin="$(resolve_executable "$TIME_BIN")"
  if [[ -n "$resolved_time_bin" ]]; then
    TIME_BIN="$resolved_time_bin"
  else
    resolved_time_bin="$(resolve_executable gtime)"
    if [[ -n "$resolved_time_bin" ]]; then
      TIME_BIN="$resolved_time_bin"
    fi
  fi
fi

extract_time_value() {
  local key="$1"
  local time_log="$2"
  if [[ ! -f "$time_log" ]]; then
    return 0
  fi
  awk -F': *' -v key="$key" '$1 == key {print $2}' "$time_log" | tail -n 1
}

extract_time_signal() {
  local time_log="$1"
  if [[ ! -f "$time_log" ]]; then
    return 0
  fi
  awk '/^Command terminated by signal / {print $NF}' "$time_log" | tail -n 1
}

detect_oom_hint() {
  local stage_status="$1"
  local time_log="$2"
  local dmesg_log="$3"

  if [[ -f "$dmesg_log" ]] && grep -Eiq 'out of memory|oom-killer|oom_reaper|Killed process [0-9]+' "$dmesg_log"; then
    echo "yes:dmesg"
    return 0
  fi
  if [[ "$stage_status" -eq 137 ]]; then
    echo "possible:sigkill"
    return 0
  fi
  if [[ -f "$time_log" ]] && grep -Eq '^Command terminated by signal 9$' "$time_log"; then
    echo "possible:sigkill"
    return 0
  fi
  echo "no"
}

write_monitor_environment() {
  local outfile="$MONITOR_ROOT/environment.log"
  {
    printf 'timestamp_utc: %s\n' "$(timestamp_utc)"
    printf 'root_dir: %s\n' "$ROOT_DIR"
    printf 'run_root: %s\n' "$RUN_ROOT"
    printf 'monitor_root: %s\n' "$MONITOR_ROOT"
    printf 'joint_clocks: %s\n' "$JOINT_CLOCKS"
    printf 'migo_clocks: %s\n' "$MIGO_CLOCKS"
    printf 'monitor_interval_sec: %s\n' "$MONITOR_INTERVAL_SEC"
    printf 'time_bin: %s\n' "$TIME_BIN"
    if [[ -x "$TIME_BIN" ]]; then
      printf 'time_enabled: yes\n'
    else
      printf 'time_enabled: no\n'
    fi
    echo "meminfo_kb:"
    awk '
      /^(MemTotal|MemFree|MemAvailable|SwapTotal|SwapFree|CommitLimit|Committed_AS):/ {
        print
      }
    ' /proc/meminfo
    echo "pressure:"
    append_pressure_snapshot cpu
    append_pressure_snapshot memory
    append_pressure_snapshot io
    echo "ulimit:"
    ulimit -a
    for cgroup_file in \
      /sys/fs/cgroup/memory.current \
      /sys/fs/cgroup/memory.max \
      /sys/fs/cgroup/memory.high \
      /sys/fs/cgroup/memory.swap.max \
      /sys/fs/cgroup/memory.events \
      /sys/fs/cgroup/cpu.max \
      /sys/fs/cgroup/cpu.weight; do
      if [[ -r "$cgroup_file" ]]; then
        printf '[%s]\n' "$cgroup_file"
        cat "$cgroup_file"
      fi
    done
  } >"$outfile"
}

run_stage() {
  local stage_id="$1"
  local stage_label="$2"
  shift 2

  local stage_dir="$MONITOR_ROOT/$stage_id"
  local command_log="$stage_dir/command.log"
  local host_initial_log="$stage_dir/host_initial.log"
  local host_samples_log="$stage_dir/host_samples.log"
  local host_final_log="$stage_dir/host_final.log"
  local time_log="$stage_dir/time_v.log"
  local dmesg_before_log="$stage_dir/dmesg_before.log"
  local dmesg_after_log="$stage_dir/dmesg_after.log"
  local summary_log="$stage_dir/summary.log"
  local started_at
  local finished_at
  local cmd_pid
  local sample_pid
  local stage_status
  local peak_rss_kb
  local time_signal
  local wait_signal=""
  local oom_hint

  mkdir -p "$stage_dir"

  {
    printf 'stage_id: %s\n' "$stage_id"
    printf 'stage_label: %s\n' "$stage_label"
    printf 'cwd: %s\n' "$ROOT_DIR"
    printf 'command:'
    printf ' %q' "$@"
    printf '\n'
  } >"$command_log"
  : >"$host_samples_log"

  capture_dmesg_tail "$dmesg_before_log"
  started_at="$(timestamp_utc)"

  echo "[ALL] $stage_label"
  echo "[ALL] stage=$stage_id monitor_dir=$stage_dir"

  if [[ -x "$TIME_BIN" ]]; then
    "$TIME_BIN" -v -o "$time_log" "$@" &
  else
    echo "[ALL][WARN] GNU time unavailable, peak RSS capture disabled for stage=$stage_id"
    "$@" &
  fi
  cmd_pid=$!

  write_host_snapshot "$host_initial_log" "$cmd_pid"
  sample_host_state "$cmd_pid" "$host_samples_log" "$MONITOR_INTERVAL_SEC" &
  sample_pid=$!

  set +e
  wait "$cmd_pid"
  stage_status=$?
  set -e

  kill "$sample_pid" 2>/dev/null || true
  wait "$sample_pid" 2>/dev/null || true

  write_host_snapshot "$host_final_log"
  capture_dmesg_tail "$dmesg_after_log"
  finished_at="$(timestamp_utc)"

  peak_rss_kb="$(extract_time_value 'Maximum resident set size (kbytes)' "$time_log")"
  peak_rss_kb="${peak_rss_kb:-unavailable}"
  time_signal="$(extract_time_signal "$time_log")"
  if (( stage_status > 128 )); then
    wait_signal="$((stage_status - 128))"
  fi
  oom_hint="$(detect_oom_hint "$stage_status" "$time_log" "$dmesg_after_log")"

  {
    printf 'stage_id: %s\n' "$stage_id"
    printf 'stage_label: %s\n' "$stage_label"
    printf 'started_at_utc: %s\n' "$started_at"
    printf 'finished_at_utc: %s\n' "$finished_at"
    printf 'exit_status: %s\n' "$stage_status"
    if [[ -n "$wait_signal" ]]; then
      printf 'wait_signal: %s\n' "$wait_signal"
    fi
    if [[ -n "$time_signal" ]]; then
      printf 'time_signal: %s\n' "$time_signal"
    fi
    printf 'oom_hint: %s\n' "$oom_hint"
    printf 'peak_rss_kb: %s\n' "$peak_rss_kb"
    printf 'elapsed: %s\n' "$(extract_time_value 'Elapsed (wall clock) time (h:mm:ss or m:ss)' "$time_log")"
    printf 'user_time_sec: %s\n' "$(extract_time_value 'User time (seconds)' "$time_log")"
    printf 'system_time_sec: %s\n' "$(extract_time_value 'System time (seconds)' "$time_log")"
    printf 'percent_cpu: %s\n' "$(extract_time_value 'Percent of CPU this job got' "$time_log")"
    printf 'major_page_faults: %s\n' "$(extract_time_value 'Major (requiring I/O) page faults' "$time_log")"
    printf 'minor_page_faults: %s\n' "$(extract_time_value 'Minor (reclaiming a frame) page faults' "$time_log")"
    printf 'command_log: %s\n' "$command_log"
    printf 'host_initial_log: %s\n' "$host_initial_log"
    printf 'host_samples_log: %s\n' "$host_samples_log"
    printf 'host_final_log: %s\n' "$host_final_log"
    printf 'time_log: %s\n' "$time_log"
    printf 'dmesg_before_log: %s\n' "$dmesg_before_log"
    printf 'dmesg_after_log: %s\n' "$dmesg_after_log"
  } >"$summary_log"

  if [[ "$stage_status" -eq 0 ]]; then
    echo "[ALL][OK] stage=$stage_id peak_rss_kb=$peak_rss_kb monitor_dir=$stage_dir"
    return 0
  fi

  echo "[ALL][ERR] stage=$stage_id exit_status=$stage_status peak_rss_kb=$peak_rss_kb oom_hint=$oom_hint"
  if [[ -n "$wait_signal" ]]; then
    echo "[ALL][ERR] wait_signal=$wait_signal"
  fi
  if [[ -n "$time_signal" ]]; then
    echo "[ALL][ERR] time_signal=$time_signal"
  fi
  echo "[ALL][ERR] summary_log=$summary_log"
  return "$stage_status"
}

echo "[ALL] run_root=$RUN_ROOT"
echo "[ALL] joint_clocks=$JOINT_CLOCKS"
echo "[ALL] migo_clocks=$MIGO_CLOCKS"
echo "[ALL] monitor_root=$MONITOR_ROOT"
echo "[ALL] monitor_interval_sec=$MONITOR_INTERVAL_SEC"
if [[ -x "$TIME_BIN" ]]; then
  echo "[ALL] time_bin=$TIME_BIN"
else
  echo "[ALL][WARN] GNU time not found; set TIME_BIN=/path/to/time to enable peak RSS capture"
fi
write_monitor_environment

run_stage "joint_top" "Joint top regression" \
  bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/top/run_top_iverilog.sh" "$RUN_ROOT/joint_top"

run_stage "joint_l0" "Joint L0 regression" \
  bash "$ROOT_DIR/vsrc/Joint-CFR-DPD/tb/l0_ops/run_l0_iverilog.sh" "$RUN_ROOT/l0"

run_stage "migo_tb" "MIGO regression" \
  bash "$ROOT_DIR/dc/designs/migo/tb/run_migo_iverilog.sh" "$RUN_ROOT/migo"

run_stage "joint_frontend" "Joint frontend Yosys" \
  bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow joint \
  --mode frontend \
  --clocks "$JOINT_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag joint_frontend

run_stage "joint_mapped" "Joint mapped Yosys (resume)" \
  bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow joint \
  --mode mapped \
  --clocks "$JOINT_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag joint_mapped \
  --resume-from-frontend "$YOSYS_RUN_ROOT/joint_frontend"

run_stage "migo_frontend" "MIGO frontend Yosys" \
  bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow migo \
  --mode frontend \
  --clocks "$MIGO_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag migo_frontend

run_stage "migo_mapped" "MIGO mapped Yosys (resume)" \
  bash "$ROOT_DIR/flow/yosys/run_presynth.sh" \
  --flow migo \
  --mode mapped \
  --clocks "$MIGO_CLOCKS" \
  --report-root "$YOSYS_RUN_ROOT" \
  --tag migo_mapped \
  --resume-from-frontend "$YOSYS_RUN_ROOT/migo_frontend"

echo "[ALL][OK] complete"
echo "[ALL][OK] outputs under $RUN_ROOT"
