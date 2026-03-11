# ROLE: VALIDATOR

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `VALIDATOR`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/active_item.yaml`
- `ai/review.md`
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
- Route baton to `REVIEWER`.
- Set `ai/active_agent.txt` to `REVIEWER`.
- Print exact message:
`HANDOFF TO REVIEWER`
- Stop.
