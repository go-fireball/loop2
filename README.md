# loop

A practical, governed, role-based AI software delivery loop inspired by `go-fireball/loop` v1.0 baton relay concepts, simplified for broad software delivery.

## What this repository is

This repo provides a **Codex-first baton workflow** for migration, bugfix, feature, refactor, and docs work. It is intentionally lightweight:
- no phase-heavy orchestration framework
- no background autonomous runtime
- explicit handoffs via files

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

After REVIEWER:
- Done -> PLANNER (next item)
- Revise -> role that must fix gaps
- Escalate -> stop for human (`WAITING FOR USER`)

## Start the loop

1. Bootstrap state:
   ```bash
   ./scripts/bootstrap.sh PRODUCT_OWNER
   ```
2. Run checks:
   ```bash
   ./scripts/check-baton.sh
   ```
3. In a fresh Codex session, run the baton instruction:
   ```
   Follow ai/next_agent.yaml exactly.
   ```

## Optional automation runner

`./scripts/run-baton.sh` repeatedly invokes Codex with:
`Follow ai/next_agent.yaml exactly.`

Supported flags:
- `--dry-run`
- `--max-steps <n>`
- `--model <model>`
- `--no-full-auto`

Safe stop conditions:
- `WAITING FOR USER`
- `WAITING FOR BATON`
- unexpected output
- command failure
- max step count reached

## Judgments and governance

- Technical defaults and constraints live in `ai/judgment.yaml`.
- Core governance rules live in `ai/constitution.yaml`.
- Decision exceptions and user confirmations live in `ai/decision-lock.yaml`.

These files constrain architecture and implementation to reduce overdesign and maintain consistent delivery quality.

## Backlog and active item

- `ai/backlog.yaml`: queue of work items and statuses.
- `ai/active_item.yaml`: single active baton target.

PLANNER owns selection/splitting; DEV/VALIDATOR/REVIEWER execute and verify.

## Fresh-session hygiene

To reduce context bleed:
- use a fresh Codex session per turn when possible
- always start with `Follow ai/next_agent.yaml exactly.`
- rely on files under `ai/` as the process backbone

## Extensibility

Codex is the initial executor. Future adapters for Claude and Copilot can be added later by extending runner invocation logic while keeping the same file contract (`ai/active_agent.txt`, `ai/next_agent.yaml`, prompts, and logs).
