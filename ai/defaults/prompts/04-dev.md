# ROLE: DEV

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
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`
- Relevant files in `apps/`, `infra/`, `context/repo/`

## 3) Allowed edits (only)
- `apps/**`
- `infra/**`
- related tests/docs for active item
- `ai/review.md` (implementation notes)
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.md` (optional)
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Implement only active item scope.
- Preserve behavior unless requirements explicitly allow change.
- Add/update tests proportionally.
- Record deviations and risks in `ai/review.md`.
- If blocked by a decision only a human can make:
  - Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: DEV`.
  - Optionally write `ai/next_agent.md` with blocker context.
  - Do NOT modify `ai/active_agent.txt` or `ai/next_agent.yaml`; runner owns baton transitions.
  - Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration decision line.
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Print exact message:
`FINISHED: HANDING TO VALIDATOR`
- Stop.
