#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/sundaram/loop2.git"
BRANCH="main"
START_ROLE="${1:-PRODUCT_OWNER}"

echo "Initializing baton loop in $(pwd) ..."

# ── Clone repo to a temp directory ──
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

git clone --depth 1 --branch "$BRANCH" "$REPO" "$tmp/repo" 2>/dev/null || {
  echo "Error: failed to clone $REPO"
  echo "Check the repo URL and your network connection."
  exit 1
}

# ── Copy scripts/ and ai/defaults/ into current directory ──
if [[ -d "scripts" ]]; then
  echo "  scripts/ already exists — skipping (remove it first to get fresh copies)"
else
  cp -r "$tmp/repo/scripts" .
  echo "  copied scripts/"
fi

mkdir -p ai
if [[ -d "ai/defaults" ]]; then
  echo "  ai/defaults/ already exists — skipping"
else
  cp -r "$tmp/repo/ai/defaults" ai/defaults
  echo "  copied ai/defaults/"
fi

# ── Run bootstrap ──
echo ""
chmod +x scripts/bootstrap.sh
exec ./scripts/bootstrap.sh "$START_ROLE"
