#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/go-fireball/loop.git"
START_ROLE="${1:-PRODUCT_OWNER}"
TMPDIR="$(mktemp -d)"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Cloning loop repo into temp directory ..."
git clone --depth 1 "$REPO_URL" "$TMPDIR/loop" 2>/dev/null

echo "Copying scripts/ ..."
mkdir -p scripts
cp -r "$TMPDIR/loop/scripts/"* scripts/
chmod +x scripts/*.sh

echo "Copying ai/defaults/ ..."
mkdir -p ai/defaults
cp -r "$TMPDIR/loop/ai/defaults/"* ai/defaults/

echo "Running bootstrap with role: ${START_ROLE} ..."
bash scripts/bootstrap.sh "$START_ROLE"
