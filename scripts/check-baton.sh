#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0

# ── 1. Check required files exist ──
required_files=(
  "ai/active_agent.txt"
  "ai/next_agent.yaml"
  "ai/goal.yaml"
  "ai/judgment.yaml"
  "ai/constitution.yaml"
  "ai/backlog.yaml"
  "ai/active_item.yaml"
  "ai/decision-lock.yaml"
  "ai/user-questions.yaml"
  "ai/requirements.md"
  "ai/iterations/ITER-0001.md"
)

echo "=== File existence ==="
for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "  FAIL: missing $file"
    errors=$((errors + 1))
  else
    echo "  OK:   $file"
  fi
done

# ── 2. Validate active agent ──
echo ""
echo "=== Active agent ==="

if [[ ! -s ai/active_agent.txt ]]; then
  echo "  FAIL: ai/active_agent.txt is empty"
  errors=$((errors + 1))
else
  agent="$(tr -d '[:space:]' < ai/active_agent.txt)"
  valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN"
  found=0
  for role in $valid_roles; do
    if [[ "$agent" == "$role" ]]; then
      found=1
      break
    fi
  done
  if [[ $found -eq 0 ]]; then
    echo "  FAIL: invalid active agent '$agent'"
    echo "        must be one of: $valid_roles"
    errors=$((errors + 1))
  else
    echo "  OK:   active agent is $agent"
  fi
fi

# ── 3. Validate YAML structure using Python helper ──
echo ""
echo "=== YAML validation ==="

yaml_files=(
  "ai/goal.yaml"
  "ai/judgment.yaml"
  "ai/constitution.yaml"
  "ai/backlog.yaml"
  "ai/active_item.yaml"
  "ai/decision-lock.yaml"
  "ai/user-questions.yaml"
  "ai/next_agent.yaml"
)

# Check if Python 3 is available
if ! command -v python3 >/dev/null 2>&1; then
  echo "  WARN: python3 not found, skipping YAML structure validation"
else
  for yf in "${yaml_files[@]}"; do
    if [[ ! -f "$yf" ]]; then
      continue  # already reported above
    fi
    result="$(python3 "$ROOT/scripts/validate_baton.py" "$yf" 2>&1)" || true
    if echo "$result" | grep -q "^FAIL"; then
      echo "  $result"
      errors=$((errors + 1))
    else
      echo "  $result"
    fi
  done
fi

# ── Summary ──
echo ""
if [[ $errors -ne 0 ]]; then
  echo "Baton check FAILED ($errors error(s))"
  exit 1
fi

echo "Baton check OK"
