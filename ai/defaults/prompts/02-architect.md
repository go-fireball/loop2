# ROLE: ARCHITECT

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
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `context/repo/` design notes
- `ai/review.md` (architecture decisions only)
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.md` (optional)
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Define approach, boundaries, key files, and tradeoffs for current item.
- Keep design proportional; avoid framework-heavy patterns.
- If architecture exception is required:
  - Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: ARCHITECT`.
  - Update `ai/decision-lock.yaml` with the exception request.
  - Optionally write `ai/next_agent.md` with exception context.
  - Do NOT modify `ai/active_agent.txt` or `ai/next_agent.yaml`; runner owns baton transitions.
  - Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration decision line.
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Print exact message:
`FINISHED: HANDING TO PLANNER`
- Stop.
