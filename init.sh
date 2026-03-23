#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/go-fireball/loop.git"
START_ROLE="${1:-PRODUCT_OWNER}"
TMPDIR="$(mktemp -d)"

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Cloning loop repo into temp directory ..."
git clone --depth 1 "$REPO_URL" "$TMPDIR/loop"

echo "Copying scripts/ ..."
mkdir -p scripts
cp -r "$TMPDIR/loop/scripts/"* scripts/
chmod +x scripts/*.sh

echo "Copying ai/defaults/ ..."
mkdir -p ai/defaults
cp -r "$TMPDIR/loop/ai/defaults/"* ai/defaults/

if [[ ! -f "ai/defaults/goal.yaml" ]]; then
  echo "Error: ai/defaults/goal.yaml is missing after copy."
  echo "Init cannot continue without required defaults."
  exit 1
fi

echo "Running bootstrap with role: ${START_ROLE} ..."
bash scripts/bootstrap.sh "$START_ROLE"

required_seed_files=(
  "ai/goal.yaml"
  "ai/judgment.yaml"
  "ai/constitution.yaml"
  "ai/backlog.yaml"
  "ai/active_item.yaml"
)

missing=0
for f in "${required_seed_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "Error: expected seeded file missing: $f"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "Bootstrap did not produce all required seed files."
  exit 1
fi
