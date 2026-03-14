#!/usr/bin/env bash
set -euo pipefail

FLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOCK_NS="${1:-2.0}"

exec "$FLOW_DIR/common/run_dc.sh" migo "$CLOCK_NS"
