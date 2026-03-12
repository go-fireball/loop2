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
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Define approach, boundaries, key files, and tradeoffs for current item.
- Keep design proportional; avoid framework-heavy patterns.
- If architecture exception is required:
  1. Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: ARCHITECT`.
  2. Update `ai/decision-lock.yaml` with the exception request.
  3. Generate next_agent.yaml for HUMAN:
     `./scripts/generate-next-agent.sh HUMAN --return-to ARCHITECT --notes "architecture exception required"`
  4. Write `ai/next_agent.md` explaining the exception.
  5. Set `ai/active_agent.txt` to `HUMAN`.
  6. Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh PLANNER --notes "architecture approach | key boundaries | tradeoffs made"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `PLANNER`.
- Print exact message:
`HANDOFF TO PLANNER`
- Stop.
