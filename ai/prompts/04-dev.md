# ROLE: DEV

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `DEV`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/active_item.yaml`
- `ai/requirements.md`
- `ai/judgment.yaml`
- `ai/simplification.md`
- Relevant files in `apps/`, `infra/`, `context/repo/`

## 3) Allowed edits (only)
- `apps/**`
- `infra/**`
- related tests/docs for active item
- `ai/review.md` (implementation notes)
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Implement only active item scope.
- Preserve behavior unless requirements explicitly allow change.
- Add/update tests proportionally.
- Record deviations and risks in `ai/review.md`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Route baton to `VALIDATOR`.
- Set `ai/active_agent.txt` to `VALIDATOR`.
- Print exact message:
`HANDOFF TO VALIDATOR`
- Stop.
