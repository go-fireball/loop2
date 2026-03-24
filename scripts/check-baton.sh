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

# ── 4. Validate next_agent.yaml next_role matches active_agent.txt ──
echo ""
echo "=== Baton sync (active_agent.txt vs next_agent.yaml) ==="

if [[ -s ai/active_agent.txt && -f ai/next_agent.yaml ]]; then
  active="$(tr -d '[:space:]' < ai/active_agent.txt)"
  next_role="$(grep '^next_role:' ai/next_agent.yaml | head -1 | sed 's/^next_role:[[:space:]]*//' | tr -d '[:space:]')"
  if [[ -z "$next_role" ]]; then
    echo "  FAIL: next_agent.yaml missing 'next_role' field"
    errors=$((errors + 1))
  elif [[ "$active" != "$next_role" ]]; then
    echo "  FAIL: active_agent.txt='$active' does not match next_agent.yaml next_role='$next_role'"
    echo "        Fix: run ./scripts/generate-next-agent.sh $active"
    errors=$((errors + 1))
  else
    echo "  OK:   active_agent '$active' matches next_agent.yaml next_role"
  fi
fi

# ── 5. Validate next_agent prompt_file matches role ──
echo ""
echo "=== next_agent prompt_file consistency ==="

if [[ -f ai/next_agent.yaml ]]; then
  next_role="$(grep '^next_role:' ai/next_agent.yaml | head -1 | sed 's/^next_role:[[:space:]]*//' | tr -d '[:space:]')"
  prompt_file="$(grep '^prompt_file:' ai/next_agent.yaml | head -1 | sed 's/^prompt_file:[[:space:]]*//' | tr -d '[:space:]')"

  expected_prompt=""
  case "$next_role" in
    PRODUCT_OWNER) expected_prompt="ai/prompts/00-product-owner.md" ;;
    SENIOR_JUDGMENTAL_ENGINEER) expected_prompt="ai/prompts/01-senior-judgmental-engineer.md" ;;
    ARCHITECT) expected_prompt="ai/prompts/02-architect.md" ;;
    PLANNER) expected_prompt="ai/prompts/03-planner.md" ;;
    DEV) expected_prompt="ai/prompts/04-dev.md" ;;
    VALIDATOR) expected_prompt="ai/prompts/05-validator.md" ;;
    REVIEWER) expected_prompt="ai/prompts/06-reviewer.md" ;;
    HUMAN) expected_prompt="N/A" ;;
  esac

  if [[ -z "$next_role" ]]; then
    echo "  FAIL: next_agent.yaml missing 'next_role' field"
    errors=$((errors + 1))
  elif [[ -z "$prompt_file" ]]; then
    echo "  FAIL: next_agent.yaml missing 'prompt_file' field"
    errors=$((errors + 1))
  elif [[ -n "$expected_prompt" && "$prompt_file" != "$expected_prompt" ]]; then
    echo "  FAIL: next_agent.yaml role/prompt mismatch for '$next_role'"
    echo "        expected prompt_file: $expected_prompt"
    echo "        actual prompt_file:   $prompt_file"
    echo "        Fix: run ./scripts/generate-next-agent.sh $next_role"
    errors=$((errors + 1))
  else
    echo "  OK:   next_role '$next_role' matches prompt_file"
  fi
fi

# ── Summary ──
echo ""
if [[ $errors -ne 0 ]]; then
  echo "Baton check FAILED ($errors error(s))"
  exit 1
fi

echo "Baton check OK"
