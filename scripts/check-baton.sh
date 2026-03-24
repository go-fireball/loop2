#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

errors=0
valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN"

# ── 1. Check required files exist ──
required_files=(
  "ai/active_agent.txt"
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

# ── 3. Validate core YAML structure using Python helper ──
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
)

if ! command -v python3 >/dev/null 2>&1; then
  echo "  WARN: python3 not found, skipping YAML structure validation"
else
  for yf in "${yaml_files[@]}"; do
    if [[ ! -f "$yf" ]]; then
      continue
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

# ── 4. Validate minimal next_agent.yaml (if present) ──
echo ""
echo "=== next_agent.yaml (optional minimal baton) ==="

if [[ -f ai/next_agent.yaml ]]; then
  if command -v python3 >/dev/null 2>&1; then
    result="$(python3 "$ROOT/scripts/validate_baton.py" ai/next_agent.yaml 2>&1)" || true
  else
    result="WARN: python3 not found, skipping next_agent schema validation"
  fi
  if echo "$result" | grep -q "^FAIL"; then
    echo "  $result"
    errors=$((errors + 1))
  else
    echo "  $result"
  fi

  next_role="$(grep '^next_role:' ai/next_agent.yaml | head -1 | sed 's/^next_role:[[:space:]]*//' | tr -d '[:space:]')"
  if [[ -z "$next_role" ]]; then
    echo "  FAIL: ai/next_agent.yaml missing next_role"
    errors=$((errors + 1))
  else
    found=0
    for role in $valid_roles; do
      if [[ "$next_role" == "$role" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -eq 0 ]]; then
      echo "  FAIL: ai/next_agent.yaml next_role '$next_role' is invalid"
      errors=$((errors + 1))
    else
      echo "  OK:   next_role is $next_role"
    fi
  fi

  return_to="$(grep '^return_to:' ai/next_agent.yaml | head -1 | sed 's/^return_to:[[:space:]]*//' | tr -d '[:space:]')"
  if [[ -n "$return_to" ]]; then
    if [[ "$next_role" != "HUMAN" ]]; then
      echo "  FAIL: return_to is only allowed when next_role is HUMAN"
      errors=$((errors + 1))
    else
      found=0
      for role in $valid_roles; do
        if [[ "$return_to" == "$role" ]]; then
          found=1
          break
        fi
      done
      if [[ $found -eq 0 || "$return_to" == "HUMAN" ]]; then
        echo "  FAIL: return_to '$return_to' must be a non-HUMAN valid role"
        errors=$((errors + 1))
      else
        echo "  OK:   return_to is $return_to"
      fi
    fi
  fi
else
  echo "  OK:   ai/next_agent.yaml not present (runner can proceed from active_agent only)"
fi

# ── Summary ──
echo ""
if [[ $errors -ne 0 ]]; then
  echo "Baton check FAILED ($errors error(s))"
  exit 1
fi

echo "Baton check OK"
