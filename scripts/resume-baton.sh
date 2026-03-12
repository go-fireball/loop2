#!/usr/bin/env bash
set -euo pipefail
#
# Usage: ./scripts/resume-baton.sh [--force] [ROLE]
#
# Hands the baton back from HUMAN to the next AI role.
# Reads return_to_role from ai/next_agent.yaml unless overridden by argument.
# Call this after answering questions in ai/user-questions.yaml.
#
# Pass --force to skip the unanswered-question check.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

FORCE=0

# Verify active agent is HUMAN
current="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "")"
if [[ "$current" != "HUMAN" ]]; then
  echo "Error: active agent is '$current', not HUMAN. Nothing to resume."
  exit 1
fi

# Determine return role
return_to=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    *) return_to="$1"; shift ;;
  esac
done

# Fall back to return_to_role from next_agent.yaml
if [[ -z "$return_to" && -f ai/next_agent.yaml ]]; then
  return_to="$(grep '^return_to_role:' ai/next_agent.yaml | sed 's/^return_to_role:[[:space:]]*//' | tr -d '[:space:]')"
fi

if [[ -z "$return_to" ]]; then
  echo "Error: no return_to_role found in ai/next_agent.yaml."
  echo "Usage: $0 <ROLE>"
  echo "Roles: PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER"
  exit 1
fi

# Validate the role
valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER"
found=0
for role in $valid_roles; do
  if [[ "$role" == "$return_to" ]]; then
    found=1
    break
  fi
done
if [[ $found -eq 0 ]]; then
  echo "Error: invalid role '$return_to'."
  echo "Valid roles: $valid_roles"
  exit 1
fi

# Check for unanswered questions
if [[ -f ai/user-questions.yaml ]]; then
  unanswered=$(grep -cE 'answer: null$|answer: ""$' ai/user-questions.yaml || true)
  if [[ "$unanswered" -gt 0 && $FORCE -eq 0 ]]; then
    echo "Warning: $unanswered question(s) still have no answer in ai/user-questions.yaml."
    echo ""
    grep -B1 -E 'answer: null$|answer: ""$' ai/user-questions.yaml | grep -v '^--$' || true
    echo ""
    echo "To resume anyway:  $0 --force"
    exit 1
  fi
  sed -i 's/^status: waiting$/status: answered/' ai/user-questions.yaml
fi

# Generate next agent config and hand baton
./scripts/generate-next-agent.sh "$return_to" --notes "Human answered questions | resuming baton"

# Set active agent
printf '%s\n' "$return_to" > ai/active_agent.txt

echo ""
echo "Baton resumed."
echo "  Active agent: $return_to"
echo "  Run: ./scripts/run-baton.sh --executor <executor> to continue."
