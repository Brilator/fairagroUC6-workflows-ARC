#!/usr/bin/env bash
# Run the demo CWL workflow.
# FROST credentials are read directly from config.yml (gitignored).
# Copy config-example.yml to config.yml and fill in your real credentials.
#
# Usage:
#   ./run-demo.sh
#
# Prerequisites:
#   - config.yml with your FROST credentials (gitignored)
#   - s4n installed and on PATH
#   - Docker running

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.yml"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: config.yml not found." >&2
  echo "       Copy config-example.yml to config.yml and fill in your FROST credentials." >&2
  exit 1
fi

cd "$SCRIPT_DIR"
s4n execute local ./workflows/demo/demo.cwl config.yml
