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
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Validate correctness, acceptance criteria, and regressions.
- Call out missing tests or parity risks.
- If validation blocked by missing user decision:
  1. Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: VALIDATOR`.
  2. Generate next_agent.yaml for HUMAN:
     `./scripts/generate-next-agent.sh HUMAN --return-to VALIDATOR --notes "validation blocked on missing user decision"`
  3. Write `ai/next_agent.md` explaining what decision is needed.
  4. Set `ai/active_agent.txt` to `HUMAN`.
  5. Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh REVIEWER --notes "validation results | pass/fail summary | issues found"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `REVIEWER`.
- Print exact message:
`HANDOFF TO REVIEWER`
- Stop.
