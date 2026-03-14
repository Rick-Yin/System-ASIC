#!/usr/bin/env bash
set -euo pipefail

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOCK_NS="${1:-2.0}"

exec bash "$FLOW_DIR/common/run_dc.sh" joint_cfr "$CLOCK_NS"
