#!/usr/bin/env bash
set -euo pipefail
#
# Usage: ./scripts/resume-baton.sh [--force]
#
# Marks HUMAN answers ready. Runner remains the only baton transition owner.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    *) echo "Usage: $0 [--force]"; exit 1 ;;
  esac
done

current="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "")"
if [[ "$current" != "HUMAN" ]]; then
  echo "Error: active agent is '$current', not HUMAN. Nothing to resume."
  exit 1
fi

return_to="$(grep '^return_to:' ai/next_agent.yaml 2>/dev/null | sed 's/^return_to:[[:space:]]*//' | tr -d '[:space:]')"
if [[ -z "$return_to" || "$return_to" == "HUMAN" ]]; then
  echo "Error: ai/next_agent.yaml must include a non-HUMAN return_to while HUMAN holds the baton."
  exit 1
fi

if [[ -f ai/user-questions.yaml ]]; then
  unanswered=$(grep -cE 'answer: null$|answer: ""$' ai/user-questions.yaml || true)
  if [[ "$unanswered" -gt 0 && $FORCE -eq 0 ]]; then
    echo "Warning: $unanswered question(s) still have no answer in ai/user-questions.yaml."
    echo "To mark ready anyway: $0 --force"
    exit 1
  fi
  sed -i 's/^status: waiting$/status: answered/' ai/user-questions.yaml
fi

echo "Marked HUMAN answers ready."
echo "Runner will resume baton on next run to: $return_to"
echo "Run: ./scripts/run-baton.sh --executor <codex|claude|copilot>"
