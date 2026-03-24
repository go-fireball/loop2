# ROLE: VALIDATOR

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `VALIDATOR`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/active_item.yaml`
- `ai/review.md`
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`
- changed files under `apps/` and `infra/`
- test output / verification artifacts

## 3) Allowed edits (only)
- `ai/review.md` (validation results)
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.md` (optional)
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Validate correctness, acceptance criteria, and regressions.
- Call out missing tests or parity risks.
- If validation blocked by missing user decision:
  - Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: VALIDATOR`.
  - Optionally write `ai/next_agent.md` with validation blocker context.
  - Do NOT modify `ai/active_agent.txt` or `ai/next_agent.yaml`; runner owns baton transitions.
  - Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration decision line.
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Print exact message:
`FINISHED: HANDING TO REVIEWER`
- Stop.
