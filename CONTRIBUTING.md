# Contributing

## Ground rules
- Respect baton ownership in `ai/active_agent.txt`.
- Follow role prompt constraints in `ai/prompts/`.
- Keep state changes in files under `ai/`.
- Avoid adding phase engines or heavy orchestration abstractions.

## Local workflow
1. `./scripts/check-baton.sh`
2. Execute current role by following `ai/next_agent.yaml`.
3. Append iteration decision line.
4. Update baton handoff files.

## Quality
- Keep solutions pragmatic and inspectable.
- Add tests proportionate to change scope.
- Escalate only for approved human-decision categories.
