#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  "ai/active_agent.txt"
  "ai/next_agent.yaml"
  "ai/goal.yaml"
  "ai/judgment.yaml"
  "ai/constitution.yaml"
  "ai/backlog.yaml"
  "ai/active_item.yaml"
  "ai/decision-lock.yaml"
  "ai/requirements.md"
  "ai/iterations/ITER-0001.md"
)

missing=0
for file in "${required[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "MISSING: $file"
    missing=1
  fi
done

if [[ ! -s ai/active_agent.txt ]]; then
  echo "MISSING: ai/active_agent.txt is empty"
  missing=1
fi

if [[ $missing -ne 0 ]]; then
  echo "Baton check FAILED"
  exit 1
fi

echo "Baton check OK"
