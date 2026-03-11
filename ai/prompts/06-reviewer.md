# ROLE: REVIEWER

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `REVIEWER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/active_item.yaml`
- `ai/backlog.yaml`
- `ai/review.md`
- `ai/decision-lock.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/review.md`
- `ai/backlog.yaml`
- `ai/active_item.yaml`
- `ai/decision-lock.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Decide one of: DONE, REVISE, ESCALATE.
- DONE: mark item done and hand to PLANNER for next item.
- REVISE: route baton to role that must fix concrete gaps.
- ESCALATE: only for allowed human decision categories, then output exactly `WAITING FOR USER`.

## 5) End-of-turn required steps
- Append iteration decision line.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh <NEXT_ROLE> --notes "review decision | gaps to fix (if REVISE) | what was accepted (if DONE)"`
  (PLANNER for DONE, specific role for REVISE)
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to that role.
- Print exact handoff message matching chosen role:
`HANDOFF TO <ROLE>`
- Stop.
