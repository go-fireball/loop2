#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

pass=0
fail=0
total=0

check() {
  total=$((total + 1))
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✓ $desc"
    pass=$((pass + 1))
  else
    echo "  ✗ $desc"
    fail=$((fail + 1))
  fi
}

echo "═══════════════════════════════════════════"
echo "  GOAL: Task Tracker CLI App"
echo "═══════════════════════════════════════════"
echo ""

# ── Phase 1: Governance ──
echo "── Phase 1: Governance (baton loop health) ──"
check "Baton check passes" bash scripts/check-baton.sh

# ── Phase 2: App structure ──
echo ""
echo "── Phase 2: App structure ──"
check "apps/task-tracker/ directory exists" test -d apps/task-tracker
check "apps/task-tracker/main.py exists" test -f apps/task-tracker/main.py

# ── Phase 3: CLI commands work ──
echo ""
echo "── Phase 3: CLI commands ──"

# Use a temp file for testing
export TASK_TRACKER_FILE="$(mktemp)"
trap "rm -f $TASK_TRACKER_FILE" EXIT

check "add command exits 0" python3 apps/task-tracker/main.py add "Test task one"
check "add second task exits 0" python3 apps/task-tracker/main.py add "Test task two"
check "list command exits 0" python3 apps/task-tracker/main.py list
check "list shows added tasks" bash -c "python3 apps/task-tracker/main.py list 2>&1 | grep -q 'Test task one'"
check "done command exits 0" python3 apps/task-tracker/main.py done 1
check "list shows completed task" bash -c "python3 apps/task-tracker/main.py list 2>&1 | grep -q '✓\|done\|complete\|DONE'"
check "delete command exits 0" python3 apps/task-tracker/main.py delete 2
check "tasks persist to JSON file" python3 -c "import json; json.load(open('$TASK_TRACKER_FILE'))"

# ── Phase 4: Tests ──
echo ""
echo "── Phase 4: Unit tests ──"
check "tests directory exists" test -d apps/task-tracker/tests
check "tests pass" python3 -m pytest apps/task-tracker/tests/ -q

# ── Summary ──
echo ""
echo "═══════════════════════════════════════════"
if [[ $fail -eq 0 ]]; then
  echo "  ALL CHECKS PASSED ($pass/$total)"
else
  echo "  $pass/$total passed, $fail FAILED"
fi
echo "═══════════════════════════════════════════"

exit $fail
