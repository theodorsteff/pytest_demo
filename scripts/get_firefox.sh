#!/usr/bin/env bash
set -euo pipefail

# Simple helper to download and unpack the latest Firefox (linux x86_64)
# into ./firefox. Idempotent: if ./firefox exists it will be replaced unless
# you pass --keep.

OUTDIR="$(pwd)/firefox"
TMPDIR="$(mktemp -d)"
ARCHIVE="$TMPDIR/firefox.tar.xz"
ARCH=""
KEEP=0

usage() {
  cat <<EOF
Usage: $0 [--keep] [--force] [--arch=<arch>]

Options:
  --keep    If ./firefox already exists, don't overwrite it (skip download).
  --force   Overwrite existing ./firefox if present.
  --arch    Override detected architecture (e.g. linux64, linux-aarch64)
  -h|--help Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --keep) KEEP=1 ;;
    --force) FORCE=1 ;;
    -h|--help) usage; exit 0 ;;
    --arch=*) ARCH="${arg#--arch=}" ;;
    *) echo "Unknown arg: $arg"; usage; exit 2 ;;
  esac
done

if [ -d "$OUTDIR" ]; then
  if [ "$KEEP" -eq 1 ]; then
    echo "${OUTDIR} exists and --keep set; skipping download"
    echo "To use it with tests: export FIREFOX_BINARY=\"$OUTDIR/firefox\""
    exit 0
  fi
  if [ "$FORCE" -ne 1 ]; then
    echo "${OUTDIR} already exists. To overwrite it pass --force, or pass --keep to skip." >&2
    echo "To use the existing copy with tests: export FIREFOX_BINARY=\"$OUTDIR/firefox\""
    exit 0
  fi
  echo "Overwriting existing ${OUTDIR} because --force was passed..."
fi

if [ -z "$ARCH" ]; then
  case "$(uname -m)" in
    x86_64|amd64) ARCH="linux64" ;;
    aarch64|arm64) ARCH="linux-aarch64" ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 2 ;;
  esac
fi

echo "Downloading latest Firefox (arch=$ARCH) ..."
wget -q -O "$ARCHIVE" "https://download.mozilla.org/?product=firefox-latest&os=${ARCH}&lang=en-US"

echo "Unpacking to temporary dir..."
tar -xf "$ARCHIVE" -C "$TMPDIR"

# The archive typically extracts to a folder named 'firefox'
if [ ! -d "$TMPDIR/firefox" ]; then
  echo "Unexpected archive structure, listing $TMPDIR:" >&2
  ls -la "$TMPDIR" >&2
  exit 1
fi

echo "Replacing $OUTDIR ..."
rm -rf "$OUTDIR.tmp" || true
mv "$TMPDIR/firefox" "$OUTDIR.tmp"
rm -rf "$OUTDIR"
mv "$OUTDIR.tmp" "$OUTDIR"

# make sure binaries are executable
chmod +x "$OUTDIR/firefox" || true
chmod +x "$OUTDIR/firefox-bin" || true

echo "Cleanup..."
rm -rf "$TMPDIR"

echo "Done. To use this Firefox for tests run:"
echo "  export FIREFOX_BINARY=\"$OUTDIR/firefox\""

exit 0
