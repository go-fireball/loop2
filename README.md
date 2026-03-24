# loop

A practical, governed, role-based AI software delivery loop for shipping software work through explicit baton handoffs across multiple AI executors (not Codex-only).

## What this repository is

This repo provides a **role-based baton workflow** for migration, bugfix, feature, refactor, and docs work. It is intentionally lightweight:
- no phase-heavy orchestration framework
- no background autonomous runtime
- explicit handoffs via files
- executor-agnostic operation via a shared file contract (`codex`, `claude`, and `copilot`)

## Functionalities at a glance

- **Role-based baton flow**: PRODUCT_OWNER → ... → REVIEWER with deterministic handoffs in `ai/next_agent.yaml`.
- **Human-in-the-loop control**: any role can hand off to `HUMAN`, pause execution, and resume after decisions are captured.
- **Stateful file contract**: delivery state lives in versioned files under `ai/` (not hidden chat memory).
- **Built-in governance**: constitution, judgment, decision lock, and review artifacts constrain delivery quality.
- **Backlog + active item management**: PLANNER drives queue selection and decomposition through structured YAML.
- **CLI automation runner**: stepwise execution, safe stop conditions, optional branch-per-iteration commits.
- **Multi-executor support**: run the same loop with Codex, Claude, or Copilot using one command surface.

## Core model

Relay-race model:
1. Current role is authoritative in `ai/active_agent.txt`.
2. Role instructions are routed by `ai/next_agent.yaml`.
3. Each role follows strict required reads + allowed edits in `ai/prompts/`.
4. End-of-turn handoff updates baton files and logs one decision line.

**State lives in files, not chat memory.**

## Role order

Default order:
1. PRODUCT_OWNER
2. SENIOR_JUDGMENTAL_ENGINEER
3. ARCHITECT
4. PLANNER
5. DEV
6. VALIDATOR
7. REVIEWER

HUMAN is a first-class role in the baton system. Any role that needs human input hands the baton to HUMAN (sets `ai/active_agent.txt` to `HUMAN`), which blocks the runner until the human answers and resumes.

After REVIEWER:
- Done -> PLANNER (next item)
- Revise -> role that must fix gaps
- Escalate -> HUMAN (baton held until human answers and runs `resume-baton.sh`)

## Quick start (new project)

Run this in an empty project directory:

```bash
curl -sO https://raw.githubusercontent.com/go-fireball/loop/main/init.sh
chmod +x init.sh
./init.sh                   # defaults to PRODUCT_OWNER
# or
./init.sh ARCHITECT         # start from a different role
```

This clones the repo temporarily, copies `scripts/` and `ai/defaults/` into your project, and runs bootstrap to populate `ai/` with the seed files.

### Required: customize `ai/goal.yaml` before running the loop

After bootstrap, edit `ai/goal.yaml` and replace the placeholder values. Keep this file at **goal level** (what to build and what success looks like), not implementation design.

Use all sections in the template:
- `project_goal`: one clear outcome statement for the product or change.
- `success_criteria`: concrete, testable must-haves (the acceptance bar).
- `context_notes`: business context, user context, dependencies, and non-technical preferences that help the team make better tradeoffs.
- `constraints`: guardrails that must be respected (keep the existing defaults unless you intentionally override them).

High-quality goal file checklist:
- be specific and measurable (avoid vague goals like "improve UX").
- include hard requirements (security/compliance/performance/SLA expectations if relevant).
- define scope boundaries (what is in vs out for this iteration).
- avoid prescribing architecture, tech stacks, or low-level tasks unless they are hard constraints.

Example (shape only):

```yaml
project_goal: Deliver a production-ready internal task tracker CLI for support engineers
success_criteria:
  - Users can add, list, complete, and delete tasks from the terminal
  - Task data persists between runs in a local JSON file
  - Core flows are covered by automated tests and pass in CI
context_notes:
  - Primary users are support engineers managing incident follow-ups
  - Keep setup lightweight; no external database for v1
constraints:
  - No autonomous background runtime
  - No heavy phase orchestration engine
  - No unnecessary microservices or clever abstractions
```

## Start the loop (existing checkout)

If you already have the repo cloned:

1. Bootstrap state:
   ```bash
   ./scripts/bootstrap.sh PRODUCT_OWNER
   ```
2. Update `ai/goal.yaml` with your real project goal, must-have success criteria, context notes, and any explicit constraints.
3. Run checks:
   ```bash
   ./scripts/check-baton.sh
   ```
4. In a fresh AI session, run the baton instruction:
   ```
   Follow ai/next_agent.yaml exactly.
   ```

## Script reference

The `scripts/` folder includes a few helper commands beyond the main runner:

- `./scripts/bootstrap.sh [ROLE]` — seeds `ai/` from `ai/defaults/` (skip-if-exists) and creates dynamic baton files.
- `./scripts/check-baton.sh` — validates required files, active role, and YAML structure.
- `./scripts/generate-next-agent.sh <ROLE> [--notes ...] [--return-to ...]` — writes `ai/next_agent.yaml` for a handoff; `success_criteria` is filled from role defaults in the script (not inferred from `ai/requirements.md` at runtime).
- `./scripts/resume-baton.sh [--force] [ROLE]` — resumes from `HUMAN` after answering `ai/user-questions.yaml`.
- `./scripts/check-goal.sh` — project-specific acceptance harness for the sample Task Tracker app under `apps/task-tracker/`.
- `./scripts/validate_baton.py` — YAML schema helper used by `check-baton.sh`.

## Optional automation runner

`./scripts/run-baton.sh` repeatedly invokes an AI executor with:
`Follow ai/next_agent.yaml exactly.`

The loop is **not Codex-only**; the same baton process runs across every supported executor.

### Supported executors (same loop contract)

| Executor | CLI required | Default model |
|----------|-------------|---------------|
| `codex` | `codex` | `gpt-5.4` |
| `claude` | `claude` | `claude-sonnet-4-6` |
| `copilot` | `copilot` | `claude-sonnet-4-6` |

### Usage

```bash
# Run with Claude (default model)
./scripts/run-baton.sh --executor claude

# Run with Claude using a specific model
./scripts/run-baton.sh --executor claude --model claude-opus-4-6

# Run with Codex, limit steps
./scripts/run-baton.sh --executor codex --model o3 --max-steps 5

# Dry run to see what would execute
./scripts/run-baton.sh --executor copilot --dry-run
```

### Flags

- `--executor <codex|claude|copilot>` — AI executor to use (required)
- `--model <model>` — model override (default depends on executor)
- `--max-steps <n>` — maximum baton steps (default: 10)
- `--no-full-auto` — stop after one handoff
- `--no-git` — disable branch-per-iteration git commits
- `--dry-run` — print the command that would run, then exit

### Branch-per-iteration

Each run automatically creates a git branch (`iter/<ITEM-ID>`) and commits after every baton step. This gives you:

- Full history of every role's changes per work item
- Safe rollback — `git diff main..iter/ITEM-0001` to review, `git branch -D iter/ITEM-0001` to discard
- Clean main branch — merge only when the iteration is fully reviewed

If the active item has no ID yet, the branch is named `iter/run-<timestamp>`. If the working tree has uncommitted changes, git tracking is automatically disabled with a warning.

Disable with `--no-git` if you prefer manual version control.

### Safe stop conditions

- `WAITING FOR USER` — an agent needs human input. The baton is handed to `HUMAN`, and the runner refuses to restart until the human answers questions in `ai/user-questions.yaml` and runs `./scripts/resume-baton.sh` to hand the baton back.
- `WAITING FOR BATON` — role mismatch (the agent expected a different active role)
- unexpected output
- command failure
- max step count reached

### Human-in-the-loop workflow

When any role hits a blocker that requires human judgment:

1. The agent writes questions to `ai/user-questions.yaml` (the single source of truth for pending questions).
2. The agent sets `ai/active_agent.txt` to `HUMAN` and outputs `WAITING FOR USER`.
3. The runner exits cleanly. Re-running `run-baton.sh` will **not** proceed — it displays the pending questions and tells the operator to answer them.
4. The human edits `ai/user-questions.yaml` to fill in answers.
5. The human runs `./scripts/resume-baton.sh` to hand the baton back to the appropriate AI role.
6. The resumed agent copies the answered decisions into `ai/decision-lock.yaml` under `approved_decisions` for the audit trail.

## Judgments and governance

- Technical defaults and constraints live in `ai/judgment.yaml`.
- Core governance rules live in `ai/constitution.yaml`.
- Decision exceptions, user confirmations, and approved decisions live in `ai/decision-lock.yaml`.
- Pending questions for the human operator live in `ai/user-questions.yaml`.

These files constrain architecture and implementation to reduce overdesign and maintain consistent delivery quality.

`ai/next_agent.yaml` is generated state. Do not hand-edit its structural fields (`next_role`, `prompt_file`, `read`, `allowed_edits`, `stop_conditions`, `success_criteria`); regenerate it with `./scripts/generate-next-agent.sh <ROLE>`. Put narrative handoff details in `ai/next_agent.md` and/or `--notes`.

## Backlog and active item

- `ai/backlog.yaml`: queue of work items and statuses.
- `ai/active_item.yaml`: single active baton target.

PLANNER owns selection/splitting; DEV/VALIDATOR/REVIEWER execute and verify.

## Fresh-session hygiene

To reduce context bleed:
- use a fresh AI session per turn when possible
- always start with `Follow ai/next_agent.yaml exactly.`
- rely on files under `ai/` as the process backbone

## Extensibility

The runner supports Codex, Claude, and Copilot as executors via `--executor`. All executors follow the same loop contract (`ai/active_agent.txt`, `ai/next_agent.yaml`, prompts, and logs), so you can switch CLIs without changing the process. To add a new executor, extend the `build_exec_cmd` and `check_cli` functions in `scripts/run-baton.sh`.

## Project structure

```
ai/defaults/          # Seed files — the single source of truth for bootstrap
  prompts/            # Role prompt files (00-product-owner.md, etc.)
  templates/          # YAML/MD templates for backlog items, decisions, etc.
  iterations/         # Initial iteration log
  logs/               # Initial baton log
  *.yaml / *.md       # State file defaults (goal, judgment, constitution, etc.)
scripts/              # Bootstrap, baton runner, resume, checks, and helpers
init.sh               # One-liner setup for new projects
```

`bootstrap.sh` copies `ai/defaults/*` into `ai/` (skip-if-exists), then generates the three dynamic files (`active_agent.txt`, `next_agent.yaml`, `next_agent.md`) based on the starting role.
