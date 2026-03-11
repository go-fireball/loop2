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

# ── Role prompt files ──
# Each role gets a concise operational prompt for fresh-session AI execution.

write_if_missing "ai/prompts/00-product-owner.md" '# ROLE: PRODUCT_OWNER

## 1) Baton check (mandatory first step)
- Read `ai/active_agent.txt`.
- If value is not exactly `PRODUCT_OWNER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/requirements.md`
- `ai/active_item.yaml`
- `ai/backlog.yaml`
- `ai/decision-lock.yaml`
- `ai/constitution.yaml`
- `ai/judgment.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/requirements.md`
- `ai/decision-lock.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional mirror)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Refine user-facing requirements and clarify scope for the active item.
- Capture unresolved requirement ambiguity in `ai/decision-lock.yaml`.
- Do not design architecture or implementation details.
- If ambiguity blocks safe progress, output exactly `WAITING FOR USER` and stop after updating decision lock.

## 5) End-of-turn required steps
- Append one line to `ai/iterations/ITER-0001.md`:
  `Decision: <what changed> | Why: <one sentence>`
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh SENIOR_JUDGMENTAL_ENGINEER --notes "summary of what changed | key items to review | any risks or open questions"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role (what you did, what to focus on, any concerns).
- Set `ai/active_agent.txt` to `SENIOR_JUDGMENTAL_ENGINEER`.
- Print exact message:
`HANDOFF TO SENIOR_JUDGMENTAL_ENGINEER`
- Stop.'

write_if_missing "ai/prompts/01-senior-judgmental-engineer.md" '# ROLE: SENIOR_JUDGMENTAL_ENGINEER

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `SENIOR_JUDGMENTAL_ENGINEER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/requirements.md`
- `ai/simplification.md`
- `ai/judgment.yaml`
- `ai/active_item.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/simplification.md`
- `ai/review.md` (only if adding judgment warnings)
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Apply practical engineering judgment to constrain overdesign.
- Add explicit guardrails, tradeoff notes, and simplification instructions.
- Ensure judgments in `ai/judgment.yaml` are reflected.
- Escalate only for major tradeoffs; otherwise keep flow moving.

## 5) End-of-turn required steps
- Append decision log line in `ai/iterations/ITER-0001.md`.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh ARCHITECT --notes "judgment summary | guardrails added | risks flagged"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `ARCHITECT`.
- Print exact message:
`HANDOFF TO ARCHITECT`
- Stop.'

write_if_missing "ai/prompts/02-architect.md" '# ROLE: ARCHITECT

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `ARCHITECT`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/requirements.md`
- `ai/active_item.yaml`
- `ai/judgment.yaml`
- `ai/simplification.md`
- `ai/decision-lock.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `context/repo/` design notes
- `ai/review.md` (architecture decisions only)
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Define approach, boundaries, key files, and tradeoffs for current item.
- Keep design proportional; avoid framework-heavy patterns.
- If architecture exception is required, update decision lock and output exactly `WAITING FOR USER`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh PLANNER --notes "architecture approach | key boundaries | tradeoffs made"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `PLANNER`.
- Print exact message:
`HANDOFF TO PLANNER`
- Stop.'

write_if_missing "ai/prompts/03-planner.md" '# ROLE: PLANNER

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `PLANNER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/backlog.yaml`
- `ai/active_item.yaml`
- `ai/decision-lock.yaml`
- `ai/constitution.yaml`
- `ai/review.md`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/backlog.yaml`
- `ai/active_item.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Select/refine next item and keep backlog statuses accurate.
- Split oversized items into smaller deliverables.
- Set `owner_role` on active item for execution baton.
- If blocked by requirement ambiguity, route to PRODUCT_OWNER and optionally WAITING FOR USER.

## 5) End-of-turn required steps
- Append iteration log line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh DEV --notes "active item details | implementation plan | files to create or modify"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `DEV`.
- Print exact message:
`HANDOFF TO DEV`
- Stop.'

write_if_missing "ai/prompts/04-dev.md" '# ROLE: DEV

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `DEV`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/active_item.yaml`
- `ai/requirements.md`
- `ai/judgment.yaml`
- `ai/simplification.md`
- `ai/constitution.yaml`
- `ai/next_agent.md`
- Relevant files in `apps/`, `infra/`, `context/repo/`

## 3) Allowed edits (only)
- `apps/**`
- `infra/**`
- related tests/docs for active item
- `ai/review.md` (implementation notes)
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Implement only active item scope.
- Preserve behavior unless requirements explicitly allow change.
- Add/update tests proportionally.
- Record deviations and risks in `ai/review.md`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh VALIDATOR --notes "what was implemented | files changed | tests added | known risks"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `VALIDATOR`.
- Print exact message:
`HANDOFF TO VALIDATOR`
- Stop.'

write_if_missing "ai/prompts/05-validator.md" '# ROLE: VALIDATOR

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `VALIDATOR`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/active_item.yaml`
- `ai/review.md`
- `ai/constitution.yaml`
- `ai/next_agent.md`
- changed files under `apps/` and `infra/`
- test output / verification artifacts

## 3) Allowed edits (only)
- `ai/review.md` (validation results)
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Validate correctness, acceptance criteria, and regressions.
- Call out missing tests or parity risks.
- If validation blocked by missing user decision, output exactly `WAITING FOR USER`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh REVIEWER --notes "validation results | pass/fail summary | issues found"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `REVIEWER`.
- Print exact message:
`HANDOFF TO REVIEWER`
- Stop.'

write_if_missing "ai/prompts/06-reviewer.md" '# ROLE: REVIEWER

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `REVIEWER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/active_item.yaml`
- `ai/backlog.yaml`
- `ai/review.md`
- `ai/decision-lock.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/review.md`
- `ai/backlog.yaml`
- `ai/active_item.yaml`
- `ai/decision-lock.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Decide one of: DONE, REVISE, ESCALATE.
- DONE: mark item done and hand to PLANNER for next item.
- REVISE: route baton to role that must fix concrete gaps.
- ESCALATE: only for allowed human decision categories, then output exactly `WAITING FOR USER`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh <NEXT_ROLE> --notes "review decision | gaps to fix (if REVISE) | what was accepted (if DONE)"`
  (PLANNER for DONE, specific role for REVISE)
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to that role.
- Print exact handoff message matching chosen role:
`HANDOFF TO <ROLE>`
- Stop.'

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

write_if_missing "ai/goal.yaml" "# Edit this file to define your project goal before running the baton loop.
project_goal: <describe what you want to build>
success_criteria:
  - <testable outcome 1>
  - <testable outcome 2>
context_notes:
  - <any additional context, preferences, or background the AI should know>
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

write_if_missing "ai/backlog.yaml" "items: []
# Example format — PRODUCT_OWNER creates real items from ai/goal.yaml:
#  - id: ITEM-0001
#    title: Build user authentication
#    goal: Allow users to sign in with email and password
#    type: feature
#    status: todo
#    priority: high
#    dependencies: []
#    notes:
#      - Python 3 only, no external dependencies"

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

<!-- PRODUCT_OWNER: replace this with requirements derived from ai/goal.yaml -->
<describe the product objective from the project goal>

## In Scope

- <scope item derived from goal>

## Out of Scope

- Governance loop internals (already bootstrapped)

## Constraints

- <constraints from ai/goal.yaml>

## Acceptance Criteria

- <testable condition from goal success_criteria>

## Open Questions

- <only unresolved questions that require user clarification>"

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

write_if_missing "ai/templates/next-agent-template.yaml" 'next_role: <ROLE>
prompt_file: ai/prompts/<prompt-file>.md
read:
  - ai/goal.yaml
  - ai/judgment.yaml
  - ai/constitution.yaml
  - ai/backlog.yaml
  - ai/active_item.yaml
  - ai/decision-lock.yaml
  - ai/active_agent.txt
  - ai/next_agent.md
allowed_edits:
  - <list of files this role may edit>
stop_conditions:
  - WAITING FOR BATON when active agent mismatch
  - WAITING FOR USER when clarification is required
success_criteria:
  - <what must be true for handoff>
handoff_on_success:
  print_exact: HANDOFF TO <NEXT_ROLE>'

write_if_missing "ai/templates/backlog-item-template.yaml" 'id: ITEM-XXXX
title: <short title>
goal: <single-sentence outcome>
type: feature   # migration | feature | bugfix | refactor | docs
status: todo    # todo | in_progress | blocked | done
priority: high  # high | medium | low
dependencies: []
notes: []'

write_if_missing "ai/templates/active-item-template.yaml" 'id: null
title: null
goal: null
status: idle
owner_role: null
related_files: []
acceptance_criteria: []
open_questions: []
done_definition: []'

write_if_missing "ai/templates/decision-lock-template.yaml" 'confirmed_by_user: false
blocked_on_user: false
last_user_decision: null
open_questions: []
approved_exceptions: []'

write_if_missing "ai/templates/one-pager-requirements-template.md" '# Requirements (One Pager)

## Objective
<what outcome is needed>

## In Scope
- <scope item>

## Out of Scope
- <non-goal>

## Constraints
- <technical/business constraints>

## Acceptance Criteria
- <testable condition>

## Open Questions
- <only unresolved questions that require user clarification>'

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
