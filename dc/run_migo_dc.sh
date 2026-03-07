#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLOCK_NS="${1:-2.0}"
RUN_TAG="${2:-}"

exec "$ROOT_DIR/dc/common/run_dc.sh" migo "$CLOCK_NS" "$RUN_TAG"
