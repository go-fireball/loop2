# ROLE: PLANNER

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
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/review.md`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/backlog.yaml`
- `ai/active_item.yaml`
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Select/refine next item and keep backlog statuses accurate.
- Split oversized items into smaller deliverables.
- Set `owner_role` on active item for execution baton.
- If blocked by requirement ambiguity:
  1. Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: PLANNER`.
  2. Generate next_agent.yaml for HUMAN:
     `./scripts/generate-next-agent.sh HUMAN --return-to PLANNER --notes "requirement ambiguity blocks planning"`
  3. Write `ai/next_agent.md` explaining the ambiguity.
  4. Set `ai/active_agent.txt` to `HUMAN`.
  5. Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration log line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh DEV --notes "active item details | implementation plan | files to create or modify"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `DEV`.
- Print exact message:
`HANDOFF TO DEV`
- Stop.
