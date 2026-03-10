#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDA_ROOT="$ROOT_DIR/tools/eda-root"
APT_ROOT="$ROOT_DIR/tools/apt-root"
SV2V_ROOT="$ROOT_DIR/tools/sv2v/sv2v-Linux"

path_prefix=()
ld_prefix=()

if [[ -d "$EDA_ROOT/usr/bin" ]]; then
  path_prefix+=("$EDA_ROOT/usr/bin")
fi

if [[ -d "$APT_ROOT/usr/bin" ]]; then
  path_prefix+=("$APT_ROOT/usr/bin")
fi

if [[ -d "$SV2V_ROOT" ]]; then
  path_prefix+=("$SV2V_ROOT")
fi

if [[ -d "$EDA_ROOT/usr/lib/x86_64-linux-gnu" ]]; then
  ld_prefix+=("$EDA_ROOT/usr/lib/x86_64-linux-gnu")
fi

if [[ -d "$APT_ROOT/usr/lib/x86_64-linux-gnu" ]]; then
  ld_prefix+=("$APT_ROOT/usr/lib/x86_64-linux-gnu")
fi

if [[ "${#path_prefix[@]}" -ne 0 ]]; then
  export PATH="$(IFS=:; echo "${path_prefix[*]}"):$PATH"
fi

if [[ "${#ld_prefix[@]}" -ne 0 ]]; then
  export LD_LIBRARY_PATH="$(IFS=:; echo "${ld_prefix[*]}"):${LD_LIBRARY_PATH:-}"
fi
