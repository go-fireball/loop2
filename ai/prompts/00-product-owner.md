# ROLE: PRODUCT_OWNER

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
- Write `ai/next_agent.yaml` for `SENIOR_JUDGMENTAL_ENGINEER`.
- Optionally mirror handoff in `ai/next_agent.md`.
- Set `ai/active_agent.txt` to `SENIOR_JUDGMENTAL_ENGINEER`.
- Print exact message:
`HANDOFF TO SENIOR_JUDGMENTAL_ENGINEER`
- Stop.
