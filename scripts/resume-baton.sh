#!/usr/bin/env bash
set -euo pipefail
#
# Usage: ./scripts/resume-baton.sh [--force] [ROLE]
#
# Hands the baton back from HUMAN to the next AI role.
# Reads return_to from ai/next_agent.yaml unless overridden by argument.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FORCE=0
current="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "")"
if [[ "$current" != "HUMAN" ]]; then
  echo "Error: active agent is '$current', not HUMAN. Nothing to resume."
  exit 1
fi

return_to=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    *) return_to="$1"; shift ;;
  esac
done

if [[ -z "$return_to" && -f ai/next_agent.yaml ]]; then
  return_to="$(grep '^return_to:' ai/next_agent.yaml | sed 's/^return_to:[[:space:]]*//' | tr -d '[:space:]')"
fi

if [[ -z "$return_to" ]]; then
  echo "Error: no return_to found in ai/next_agent.yaml."
  echo "Usage: $0 <ROLE>"
  exit 1
fi

valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER"
found=0
for role in $valid_roles; do
  [[ "$role" == "$return_to" ]] && found=1
 done
if [[ $found -eq 0 ]]; then
  echo "Error: invalid role '$return_to'."
  exit 1
fi

if [[ -f ai/user-questions.yaml ]]; then
  unanswered=$(grep -cE 'answer: null$|answer: ""$' ai/user-questions.yaml || true)
  if [[ "$unanswered" -gt 0 && $FORCE -eq 0 ]]; then
    echo "Warning: $unanswered question(s) still have no answer in ai/user-questions.yaml."
    echo "To resume anyway:  $0 --force"
    exit 1
  fi
  sed -i 's/^status: waiting$/status: answered/' ai/user-questions.yaml
fi

./scripts/generate-next-agent.sh "$return_to" --notes "Human answered questions; resuming baton"
printf '%s\n' "$return_to" > ai/active_agent.txt

echo ""
echo "Baton resumed."
echo "  Active agent: $return_to"
