# ROLE: PRODUCT_OWNER

## 1) Baton check (mandatory first step)
- Read `ai/active_agent.txt`.
- If value is not exactly `PRODUCT_OWNER`, output exactly:
`WAITING FOR BATON`
- Stop.

## 2) Required reads
- `ai/goal.yaml`
- `ai/requirements.md`
- `ai/active_item.yaml`
- `ai/backlog.yaml`
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/constitution.yaml`
- `ai/judgment.yaml`
- `ai/next_agent.md`

## 3) Allowed edits (only)
- `ai/requirements.md`
- `ai/decision-lock.yaml`
- `ai/user-questions.yaml`
- `ai/next_agent.yaml`
- `ai/next_agent.md` (optional mirror)
- `ai/active_agent.txt`
- `ai/iterations/ITER-0001.md`

## 4) Required actions
- Refine user-facing requirements and clarify scope for the active item.
- If `ai/user-questions.yaml` has `status: answered`, copy decisions to `ai/decision-lock.yaml` under `approved_decisions` and reset `ai/user-questions.yaml` to `status: none`.
- Do not design architecture or implementation details.
- If ambiguity blocks safe progress:
  1. Write questions to `ai/user-questions.yaml` with `status: waiting` and `return_to_role: PRODUCT_OWNER`.
  2. Generate next_agent.yaml for HUMAN:
     `./scripts/generate-next-agent.sh HUMAN --return-to PRODUCT_OWNER --notes "questions for user | what is blocked"`
  3. Write `ai/next_agent.md` explaining what questions need answers.
  4. Set `ai/active_agent.txt` to `HUMAN`.
  5. Output exactly `WAITING FOR USER` and stop.

## 5) End-of-turn required steps
- Append one line to `ai/iterations/ITER-0001.md`:
  `Decision: <what changed> | Why: <one sentence>`
- Generate next_agent.yaml with handoff context:
  `./scripts/generate-next-agent.sh SENIOR_JUDGMENTAL_ENGINEER --notes "summary of what changed | key items to review | any risks"`
- Write `ai/next_agent.md` with detailed handoff notes for the next role (what you did, what to focus on, any concerns).
- Set `ai/active_agent.txt` to `SENIOR_JUDGMENTAL_ENGINEER`.
- Print exact message:
`HANDOFF TO SENIOR_JUDGMENTAL_ENGINEER`
- Stop.
