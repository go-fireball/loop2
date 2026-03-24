# Baton Simplification

## Goal

Make baton handling deterministic by separating **state** from **behavior**.

- State answers: who runs next?
- Behavior answers: what does that role do?

## Source of truth

- `ai/active_agent.txt`: authoritative current role.
- `scripts/run-baton.sh`: authoritative role→prompt resolution.

`ai/next_agent.yaml` is not used to resolve role prompts or execution behavior.

## File roles

- `ai/active_agent.txt`
  - Single source of truth for current role.
- `ai/next_agent.yaml`
  - Optional, minimal baton metadata:
    - `next_role` (required when file exists)
    - `handoff_notes` (optional)
    - `return_to` (optional, only when `next_role: HUMAN`)
- `ai/next_agent.md`
  - Optional narrative handoff context only.
- `scripts/generate-next-agent.sh`
  - Generates minimal `ai/next_agent.yaml` only.
- `scripts/check-baton.sh`
  - Validates active role and minimal baton schema; does not validate prompt behavior from YAML.
- `scripts/run-baton.sh`
  - Reads active role from `ai/active_agent.txt`, resolves prompt via static mapping, executes, parses strict terminal contract, updates baton.

## Strict handoff contract

Agents must end with exactly one of:

- `FINISHED: HANDING TO <ROLE>`
- `WAITING FOR USER`
- `WAITING FOR BATON`

No alternate phrasing is accepted.

## Baton flow

1. Runner reads current role from `ai/active_agent.txt`.
2. Runner resolves prompt from static role map.
3. Runner executes AI turn.
4. Runner parses terminal contract line:
   - `FINISHED: HANDING TO <ROLE>`
     - update `ai/active_agent.txt` to `<ROLE>`
     - generate minimal `ai/next_agent.yaml` for `<ROLE>`
   - `WAITING FOR USER`
     - set `ai/active_agent.txt` to `HUMAN`
     - generate minimal `ai/next_agent.yaml` with `next_role: HUMAN` and `return_to`
   - `WAITING FOR BATON`
     - stop with no baton transition

## Why mismatch is now impossible

Prompt mismatch used to happen because generated YAML mixed role state and role behavior.

Now:

- execution role = `ai/active_agent.txt`
- prompt file = static map inside runner
- generated YAML never carries prompt/config behavior

So a malformed or stale `ai/next_agent.yaml` cannot reroute prompt selection.
