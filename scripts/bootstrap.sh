#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

start_role="${1:-PRODUCT_OWNER}"

# ── Ensure required directories exist ──
dirs=(
  ai
  ai/prompts
  ai/templates
  ai/iterations
  ai/logs
  apps
  infra
  context/repo
  context/old
)
for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# ── Helper: write file only if it does not already exist ──
write_if_missing() {
  local file="$1"
  local content="$2"
  if [[ ! -f "$file" ]]; then
    printf '%s\n' "$content" > "$file"
    echo "  created $file"
  else
    echo "  exists  $file (kept)"
  fi
}

# ── Determine prompt file for starting role ──
prompt_file_for_role() {
  case "$1" in
    PRODUCT_OWNER)               echo "ai/prompts/00-product-owner.md" ;;
    SENIOR_JUDGMENTAL_ENGINEER)   echo "ai/prompts/01-senior-judgmental-engineer.md" ;;
    ARCHITECT)                   echo "ai/prompts/02-architect.md" ;;
    PLANNER)                     echo "ai/prompts/03-planner.md" ;;
    DEV)                         echo "ai/prompts/04-dev.md" ;;
    VALIDATOR)                   echo "ai/prompts/05-validator.md" ;;
    REVIEWER)                    echo "ai/prompts/06-reviewer.md" ;;
    *) echo "ERROR: unknown role: $1" >&2; exit 1 ;;
  esac
}

prompt_file="$(prompt_file_for_role "$start_role")"

# ── Initialize state files if missing ──

write_if_missing "ai/active_agent.txt" "$start_role"

write_if_missing "ai/next_agent.yaml" "next_role: ${start_role}
prompt_file: ${prompt_file}
read:
  - ai/goal.yaml
  - ai/judgment.yaml
  - ai/constitution.yaml
  - ai/backlog.yaml
  - ai/active_item.yaml
  - ai/decision-lock.yaml
  - ai/active_agent.txt
allowed_edits:
  - ai/requirements.md
  - ai/decision-lock.yaml
  - ai/iterations/ITER-0001.md
  - ai/active_agent.txt
  - ai/next_agent.yaml
  - ai/next_agent.md
stop_conditions:
  - WAITING FOR BATON when active agent mismatch
  - WAITING FOR USER when clarification is required
success_criteria:
  - requirements updated
  - baton handed to next role
handoff_on_success:
  print_exact: HANDOFF TO SENIOR_JUDGMENTAL_ENGINEER"

write_if_missing "ai/next_agent.md" "# Next Agent

- Current role: \`${start_role}\`
- Prompt: \`${prompt_file}\`
- Execution command for Codex sessions: **Follow \`ai/next_agent.yaml\` exactly.**
- If role mismatch with \`ai/active_agent.txt\`, print: \`WAITING FOR BATON\`"

write_if_missing "ai/goal.yaml" "project_goal: Stand up a governed, role-based AI delivery loop repository
success_criteria:
  - All core governance files exist under ai/
  - Every role has a strict operational prompt with baton and file ownership checks
  - Codex can run each turn by following ai/next_agent.yaml
  - Optional baton runner can automate multi-step execution safely
context_notes:
  - Codex-first execution model
  - State lives in files, not chat memory
  - Human-in-the-loop only for high-level decisions
constraints:
  - No autonomous background runtime
  - No heavy phase orchestration engine
  - No unnecessary microservices or clever abstractions"

write_if_missing "ai/judgment.yaml" "backend_default: aspnet_core
frontend_default: react_nextjs
frontend_alternative: nuxt_if_explicitly_requested
database_default: postgresql
architecture_default: modular_monolith
coding_style: functional_testable_pragmatic
preserve_business_behavior: true
avoid_unnecessary_microservices: true
avoid_clever_abstractions: true
cloud_default: aws
iac_default: cdk
container_default: fargate
static_assets_default: s3_cloudfront
auth_default: cognito
python_only_for_data_workloads: true
nosql_only_when_justified: true
relational_bias: true
human_for_high_level_decisions_only: true"

write_if_missing "ai/constitution.yaml" "core_rules:
  - state lives in files, not chat memory
  - baton ownership is authoritative
  - roles must not edit outside allowed files
baton_rules:
  - if active agent mismatch, print exactly WAITING FOR BATON
  - baton must be handed off explicitly
edit_rules:
  - only edit allowed files listed in the current role prompt
stop_rules:
  - if human clarification is needed, print exactly WAITING FOR USER
  - always append an iteration log entry before handoff"

write_if_missing "ai/backlog.yaml" "items:
  - id: ITEM-0001
    title: Scaffold governed baton loop repository
    goal: Establish the full ai/, scripts/, and governance baseline for immediate use
    type: feature
    status: todo
    priority: high
    dependencies: []
    notes: []"

write_if_missing "ai/active_item.yaml" "id: null
title: null
goal: null
status: idle
owner_role: null
related_files: []
acceptance_criteria: []
open_questions: []
done_definition: []"

write_if_missing "ai/decision-lock.yaml" "confirmed_by_user: false
blocked_on_user: false
last_user_decision: null
open_questions: []
approved_exceptions: []"

write_if_missing "ai/requirements.md" "# Requirements (One Pager)

## Objective

Create a lightweight, governed AI software delivery loop that is role-based,
baton-driven, and file-state-driven.

## In Scope

- Migration and modernization work
- Bug fixes
- Feature delivery
- Refactoring
- Documentation-driven engineering tasks

## Operating Model

Sequence through roles:
1. PRODUCT_OWNER
2. SENIOR_JUDGMENTAL_ENGINEER
3. ARCHITECT
4. PLANNER
5. DEV
6. VALIDATOR
7. REVIEWER

Baton authority is \`ai/active_agent.txt\`.
Role instructions are sourced via \`ai/next_agent.yaml\`.
Each role reads required files, edits only allowed files, then hands off explicitly.

## Human-In-The-Loop Boundaries

Ask the user only for:
1. Goal clarification
2. Requirement ambiguity
3. Architecture exceptions
4. Parity exceptions
5. Major tradeoffs

## Constraints

- No phase-heavy engine
- No autonomous background runtime
- No unnecessary microservices
- No clever abstractions disconnected from item scope

## Success Criteria

- Deterministic baton handoff
- Fresh-session friendly execution
- Judgment-guided delivery with low overhead"

write_if_missing "ai/review.md" "# Review Notes

Use this file for reviewer outcomes:

- **DONE**: item accepted and loop returns to PLANNER for next item.
- **REVISE**: route back to specific role with explicit gap list.
- **ESCALATE**: WAITING FOR USER only for approved escalation categories."

write_if_missing "ai/simplification.md" "# Simplification Guidance

1. Prefer straightforward modular monolith structures.
2. Keep interfaces small and explicit.
3. Add abstractions only when repeated pain is proven.
4. Preserve existing business behavior unless requirements say otherwise.
5. Bias toward maintainability over novelty."

write_if_missing "ai/iterations/ITER-0001.md" "# ITER-0001 Decision Log

| Timestamp | Role | Decision | Why |
|-----------|------|----------|-----|"

write_if_missing "ai/logs/baton.log" "# Baton run log
# Timestamped entries from scripts/run-baton.sh are appended here."

echo ""
echo "Bootstrap complete."
echo "  Active role : ${start_role}"
echo "  Prompt file : ${prompt_file}"
echo "  Baton state : ai/active_agent.txt"
echo "  Next agent  : ai/next_agent.yaml"
echo ""
echo "To validate:  ./scripts/check-baton.sh"
echo "To run Codex: Follow ai/next_agent.yaml exactly."
