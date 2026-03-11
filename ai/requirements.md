# Requirements (One Pager)

## Objective
Create a lightweight, governed AI software delivery loop that is role-based, baton-driven, and file-state-driven.

## In Scope
- Migration/modernization work
- Bug fixes
- Feature delivery
- Refactoring
- Documentation-driven engineering tasks

## Operating Model
- Sequence through: PRODUCT_OWNER -> SENIOR_JUDGMENTAL_ENGINEER -> ARCHITECT -> PLANNER -> DEV -> VALIDATOR -> REVIEWER
- Baton authority is `ai/active_agent.txt`
- Role instructions are sourced via `ai/next_agent.yaml`
- Each role reads required files, edits only allowed files, then hands off explicitly

## Human-In-The-Loop Boundaries
Ask the user only for:
1. Goal clarification
2. Requirement ambiguity
3. Architecture exceptions
4. Parity exceptions
5. Major tradeoffs

## Hard Constraints
- No phase-heavy engine
- No autonomous background runtime
- No unnecessary microservices
- No clever abstractions disconnected from item scope

## Success Criteria
- Deterministic baton handoff
- Fresh-session friendly execution
- Judgment-guided delivery with low overhead
