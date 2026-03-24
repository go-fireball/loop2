#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

start_role="${1:-PRODUCT_OWNER}"
DEFAULTS_DIR="ai/defaults"

if [[ ! -d "$DEFAULTS_DIR" ]]; then
  echo "Error: $DEFAULTS_DIR not found. Cannot bootstrap without seed files."
  exit 1
fi

valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN"
found=0
for role in $valid_roles; do
  [[ "$role" == "$start_role" ]] && found=1
 done
if [[ $found -eq 0 ]]; then
  echo "Error: unknown role: $start_role"
  exit 1
fi

dirs=(ai ai/prompts ai/templates ai/iterations ai/logs apps infra context/repo context/old)
for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

echo "Copying defaults from $DEFAULTS_DIR ..."
shopt -s globstar
for src in "$DEFAULTS_DIR"/**; do
  [[ -f "$src" ]] || continue
  rel="${src#${DEFAULTS_DIR}/}"
  dest="ai/${rel}"
  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    echo "  created $dest"
  else
    echo "  exists  $dest (kept)"
  fi
done

if [[ ! -f ai/active_agent.txt ]]; then
  printf '%s\n' "$start_role" > ai/active_agent.txt
  echo "  created ai/active_agent.txt"
else
  echo "  exists  ai/active_agent.txt (kept)"
fi

if [[ ! -f ai/next_agent.yaml ]]; then
  ./scripts/generate-next-agent.sh "$start_role" --notes "Initial bootstrap baton state"
  echo "  created ai/next_agent.yaml"
else
  echo "  exists  ai/next_agent.yaml (kept)"
fi

if [[ ! -f ai/next_agent.md ]]; then
  cat > ai/next_agent.md <<EOF2
# Next Agent

This file is optional narrative context only.
Execution routing is determined by:
- ai/active_agent.txt (current role)
- scripts/run-baton.sh static role->prompt mapping
EOF2
  echo "  created ai/next_agent.md"
else
  echo "  exists  ai/next_agent.md (kept)"
fi

echo ""
echo "Bootstrap complete."
echo "  Active role : $start_role"
echo "  Baton state : ai/active_agent.txt"
echo "  Next agent  : ai/next_agent.yaml"
echo ""
echo "To validate: ./scripts/check-baton.sh"
