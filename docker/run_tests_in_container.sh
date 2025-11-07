#!/usr/bin/env bash
set -euo pipefail

# Small wrapper to run pytest inside the container. Accepts extra pytest args.
cd /workspace

# Ensure we have an installed pytest (installed in image)
echo "Running tests inside container (FIREFOX_BINARY=${FIREFOX_BINARY:-/usr/bin/firefox})"

# Allow passing extra args to pytest
if [ "$#" -eq 0 ]; then
  pytest -v
else
  pytest -v "$@"
fi
