# ROLE: SENIOR_JUDGMENTAL_ENGINEER

## 1) Baton check
- Read `ai/active_agent.txt`.
- If value is not exactly `SENIOR_JUDGMENTAL_ENGINEER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/requirements.md`
- `ai/simplification.md`
- `ai/judgment.yaml`
- `ai/active_item.yaml`
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/simplification.md`
- `ai/review.md` (only if adding judgment warnings)
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Apply practical engineering judgment to constrain overdesign.
- Add explicit guardrails, tradeoff notes, and simplification instructions.
- Ensure judgments in `ai/judgment.yaml` are reflected.
- Escalate only for major tradeoffs; otherwise keep flow moving.
- If a major tradeoff requires human decision:
  1. Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: SENIOR_JUDGMENTAL_ENGINEER`.
  2. Generate next_agent.yaml for HUMAN:
     `./scripts/generate-next-agent.sh HUMAN --return-to SENIOR_JUDGMENTAL_ENGINEER --notes "tradeoff requiring human decision"`
  3. Write `ai/next_agent.md` explaining the tradeoff.
  4. Set `ai/active_agent.txt` to `HUMAN`.
  5. Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append decision log line in `ai/iterations/ITER-0001.md`.
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh ARCHITECT --notes "judgment summary | guardrails added | risks flagged"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role.
- Set `ai/active_agent.txt` to `ARCHITECT`.
- Print exact message:
`HANDOFF TO ARCHITECT`
- Stop.
