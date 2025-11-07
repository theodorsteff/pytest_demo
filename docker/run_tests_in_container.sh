#!/usr/bin/env bash
set -euo pipefail

# Small wrapper to run pytest inside the container. Accepts extra pytest args.
cd /workspace

# Use a temporary directory in the container for test results
TEMP_RESULTS_DIR=/tmp/test-results
FINAL_RESULTS_DIR=/workspace/test-results

mkdir -p "$TEMP_RESULTS_DIR"

echo "Running tests inside container (FIREFOX_BINARY=${FIREFOX_BINARY:-/usr/bin/firefox})"

# Default pytest args: verbose and JUnit xml output for Jenkins
DEFAULT_ARGS=( -v --junitxml="$TEMP_RESULTS_DIR/junit-results.xml" )

if [ "$#" -eq 0 ]; then
  pytest "${DEFAULT_ARGS[@]}"
else
  pytest "${DEFAULT_ARGS[@]}" "$@"
fi

# After tests complete, try to copy results to the mounted volume
# but don't fail if we can't write there
if mkdir -p "$FINAL_RESULTS_DIR" 2>/dev/null; then
  cp -f "$TEMP_RESULTS_DIR"/* "$FINAL_RESULTS_DIR/" 2>/dev/null || true
  echo "Tests finished. Results are in $FINAL_RESULTS_DIR"
else
  echo "Tests finished. Could not write results to $FINAL_RESULTS_DIR (permission denied)"
  echo "Results are available in $TEMP_RESULTS_DIR"
fi
