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
OUTPUT_DIR="$SCRIPT_DIR/outputs"
RUN_START_STAMP="$(mktemp)"

format_duration() {
  local total_seconds="$1"
  local hours=$((total_seconds / 3600))
  local minutes=$(((total_seconds % 3600) / 60))
  local seconds=$((total_seconds % 60))
  printf "%02dh:%02dm:%02ds" "$hours" "$minutes" "$seconds"
}

# Ensure temporary file is removed even if the script exits early.
trap 'rm -f "$RUN_START_STAMP"' EXIT

# Mark run start time so we can move only files produced/updated by this run.
touch "$RUN_START_STAMP"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: config.yml not found." >&2
  echo "       Copy config-example.yml to config.yml and fill in your FROST credentials." >&2
  exit 1
fi

cd "$SCRIPT_DIR"
WORKFLOW_START_TS="$(date +%s)"
s4n execute local ./workflows/demo/demo.cwl config.yml
WORKFLOW_END_TS="$(date +%s)"
WORKFLOW_ELAPSED_SECONDS=$((WORKFLOW_END_TS - WORKFLOW_START_TS))

echo "Workflow runtime: $(format_duration "$WORKFLOW_ELAPSED_SECONDS")"

mkdir -p "$OUTPUT_DIR"

# Collect root-level files touched by this run and move them into outputs/.
while IFS= read -r file_path; do
  file_name="$(basename "$file_path")"

  case "$file_name" in
    config.yml|config-example.yml|README.md|run-demo.sh|organize_outputs.sh|workflow.toml)
      continue
      ;;
  esac

  mv "$file_path" "$OUTPUT_DIR/"
  echo "Moved $file_name to outputs/"
done < <(
  find "$SCRIPT_DIR" -maxdepth 1 -type f ! -name ".*" -newer "$RUN_START_STAMP" -print
)

# Always relocate DSSAT simulation artifacts, even when mtime doesn't change.
for pattern in "*.WHX" "*.SOL" "*.WTH" "*.CLI" "*.WND"; do
  for file_path in "$SCRIPT_DIR"/$pattern; do
    [[ -e "$file_path" ]] || continue
    file_name="$(basename "$file_path")"

    mv "$file_path" "$OUTPUT_DIR/"
    echo "Moved $file_name to outputs/"
  done
done
