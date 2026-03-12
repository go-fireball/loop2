#!/usr/bin/env bash
set -euo pipefail
#
# Usage: ./scripts/generate-next-agent.sh <ROLE> [--notes "context"] [--return-to "ROLE"]
#
# Generates ai/next_agent.yaml with the correct config for the given role.
# Pass --notes to include handoff context (what was done, what to watch for).
# Pass --return-to to specify which role the baton returns to (used with HUMAN).
# Called by each role prompt at handoff time so agents don't hand-write YAML.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ROLE=""
NOTES=""
RETURN_TO=""

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    --return-to) RETURN_TO="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 <ROLE> [--notes \"context for next role\"] [--return-to \"ROLE\"]" >&2
      echo "Roles: PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN" >&2
      exit 0
      ;;
    *)
      if [[ -z "$ROLE" ]]; then
        ROLE="$1"; shift
      else
        echo "Error: unexpected argument '$1'" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 <ROLE> [--notes \"context for next role\"] [--return-to \"ROLE\"]" >&2
  echo "Roles: PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN" >&2
  exit 1
fi

# ── Role configs ──
# Each entry: prompt_file | read_files (comma-sep) | allowed_edits (comma-sep) | success_criteria | next_role
case "$ROLE" in
  PRODUCT_OWNER)
    PROMPT_FILE="ai/prompts/00-product-owner.md"
    READ_FILES=(
      "ai/goal.yaml"
      "ai/requirements.md"
      "ai/active_item.yaml"
      "ai/backlog.yaml"
      "ai/decision-lock.yaml"
      "ai/constitution.yaml"
      "ai/judgment.yaml"
    )
    ALLOWED_EDITS=(
      "ai/requirements.md"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="requirements updated and baton handed to next role"
    NEXT_ROLE="SENIOR_JUDGMENTAL_ENGINEER"
    ;;
  SENIOR_JUDGMENTAL_ENGINEER)
    PROMPT_FILE="ai/prompts/01-senior-judgmental-engineer.md"
    READ_FILES=(
      "ai/requirements.md"
      "ai/simplification.md"
      "ai/judgment.yaml"
      "ai/active_item.yaml"
      "ai/constitution.yaml"
      "ai/decision-lock.yaml"
    )
    ALLOWED_EDITS=(
      "ai/simplification.md"
      "ai/review.md"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="judgment guardrails applied and scope validated"
    NEXT_ROLE="ARCHITECT"
    ;;
  ARCHITECT)
    PROMPT_FILE="ai/prompts/02-architect.md"
    READ_FILES=(
      "ai/requirements.md"
      "ai/active_item.yaml"
      "ai/judgment.yaml"
      "ai/simplification.md"
      "ai/decision-lock.yaml"
    )
    ALLOWED_EDITS=(
      "context/repo/"
      "ai/review.md"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="architecture defined with boundaries and tradeoffs"
    NEXT_ROLE="PLANNER"
    ;;
  PLANNER)
    PROMPT_FILE="ai/prompts/03-planner.md"
    READ_FILES=(
      "ai/backlog.yaml"
      "ai/active_item.yaml"
      "ai/goal.yaml"
      "ai/decision-lock.yaml"
      "ai/review.md"
    )
    ALLOWED_EDITS=(
      "ai/backlog.yaml"
      "ai/active_item.yaml"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="active item selected and implementation-ready"
    NEXT_ROLE="DEV"
    ;;
  DEV)
    PROMPT_FILE="ai/prompts/04-dev.md"
    READ_FILES=(
      "ai/active_item.yaml"
      "ai/requirements.md"
      "ai/judgment.yaml"
      "ai/simplification.md"
      "ai/decision-lock.yaml"
    )
    ALLOWED_EDITS=(
      "apps/"
      "infra/"
      "ai/review.md"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="active item implemented with tests"
    NEXT_ROLE="VALIDATOR"
    ;;
  VALIDATOR)
    PROMPT_FILE="ai/prompts/05-validator.md"
    READ_FILES=(
      "ai/active_item.yaml"
      "ai/review.md"
      "ai/decision-lock.yaml"
    )
    ALLOWED_EDITS=(
      "ai/review.md"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="validation passed with no regressions"
    NEXT_ROLE="REVIEWER"
    ;;
  REVIEWER)
    PROMPT_FILE="ai/prompts/06-reviewer.md"
    READ_FILES=(
      "ai/active_item.yaml"
      "ai/backlog.yaml"
      "ai/review.md"
      "ai/decision-lock.yaml"
      "ai/constitution.yaml"
    )
    ALLOWED_EDITS=(
      "ai/review.md"
      "ai/backlog.yaml"
      "ai/active_item.yaml"
      "ai/decision-lock.yaml"
      "ai/user-questions.yaml"
      "ai/iterations/ITER-0001.md"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="review decision made (DONE/REVISE/ESCALATE)"
    NEXT_ROLE="PLANNER"
    ;;
  HUMAN)
    PROMPT_FILE="N/A"
    READ_FILES=(
      "ai/user-questions.yaml"
      "ai/active_item.yaml"
      "ai/decision-lock.yaml"
    )
    ALLOWED_EDITS=(
      "ai/user-questions.yaml"
      "ai/active_agent.txt"
      "ai/next_agent.yaml"
      "ai/next_agent.md"
    )
    SUCCESS="human answered questions and resumed baton"
    # Default next role; overridden by --return-to
    NEXT_ROLE="PRODUCT_OWNER"
    if [[ -n "$RETURN_TO" ]]; then
      NEXT_ROLE="$RETURN_TO"
    fi
    ;;
  *)
    echo "Error: unknown role '$ROLE'" >&2
    echo "Valid roles: PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN" >&2
    exit 1
    ;;
esac

# ── Common read files prepended to all roles ──
COMMON_READS=(
  "ai/goal.yaml"
  "ai/constitution.yaml"
  "ai/active_agent.txt"
  "ai/next_agent.md"
  "ai/user-questions.yaml"
)

# Merge common reads (deduplicate)
ALL_READS=()
for f in "${READ_FILES[@]}" "${COMMON_READS[@]}"; do
  skip=0
  for existing in "${ALL_READS[@]+"${ALL_READS[@]}"}"; do
    if [[ "$existing" == "$f" ]]; then
      skip=1
      break
    fi
  done
  if [[ $skip -eq 0 ]]; then
    ALL_READS+=("$f")
  fi
done

# ── Write next_agent.yaml ──
{
  echo "next_role: $ROLE"
  echo "prompt_file: $PROMPT_FILE"
  echo "read:"
  for f in "${ALL_READS[@]}"; do
    echo "  - $f"
  done
  echo "allowed_edits:"
  for f in "${ALLOWED_EDITS[@]}"; do
    echo "  - $f"
  done
  echo "stop_conditions:"
  echo "  - WAITING FOR BATON when active agent mismatch"
  echo "  - WAITING FOR USER when clarification is required"
  echo "success_criteria:"
  echo "  - $SUCCESS"
  echo "handoff_on_success:"
  echo "  print_exact: HANDOFF TO $NEXT_ROLE"
  # Include return_to_role for HUMAN handoffs
  if [[ "$ROLE" == "HUMAN" ]]; then
    echo "return_to_role: $NEXT_ROLE"
  fi
  # Append handoff notes if provided
  if [[ -n "$NOTES" ]]; then
    echo "notes:"
    # Split notes on '|' to allow multiple bullet points
    IFS='|' read -ra NOTE_ITEMS <<< "$NOTES"
    for item in "${NOTE_ITEMS[@]}"; do
      trimmed="$(echo "$item" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      if [[ -n "$trimmed" ]]; then
        echo "  - $trimmed"
      fi
    done
  fi
} > ai/next_agent.yaml

echo "Generated ai/next_agent.yaml for $ROLE (next: $NEXT_ROLE)"
