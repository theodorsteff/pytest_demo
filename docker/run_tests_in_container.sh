#!/usr/bin/env bash
set -euo pipefail

# Small wrapper to run pytest inside the container. Accepts extra pytest args.
cd /workspace

TEST_RESULTS_DIR=/workspace/test-results
mkdir -p "$TEST_RESULTS_DIR"

echo "Running tests inside container (FIREFOX_BINARY=${FIREFOX_BINARY:-/usr/bin/firefox})"

# Default pytest args: verbose and JUnit xml output for Jenkins
DEFAULT_ARGS=( -v --junitxml="$TEST_RESULTS_DIR/junit-results.xml" )

if [ "$#" -eq 0 ]; then
  pytest "${DEFAULT_ARGS[@]}"
else
  pytest "${DEFAULT_ARGS[@]}" "$@"
fi

echo "Tests finished. Results are in $TEST_RESULTS_DIR"
