#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MAX_STEPS=10
MODEL="gpt-5.4"
DRY_RUN=0
FULL_AUTO=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --max-steps) MAX_STEPS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --no-full-auto) FULL_AUTO=0; shift ;;
    *) echo "Unknown flag: $1"; exit 1 ;;
  esac
done

# ── Initial baton validation ──
if ! ./scripts/check-baton.sh; then
  echo "Baton state is invalid; cannot start." | tee -a ai/logs/baton.log
  exit 1
fi

for ((step=1; step<=MAX_STEPS; step++)); do
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "[$ts] Step $step" | tee -a ai/logs/baton.log

  # ── Pre-step validation ──
  if ! ./scripts/check-baton.sh >/dev/null 2>&1; then
    echo "[$ts] Baton state invalid before step $step; stopping." | tee -a ai/logs/baton.log
    exit 1
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: would invoke codex --model $MODEL \"Follow ai/next_agent.yaml exactly.\"" | tee -a ai/logs/baton.log
    exit 0
  fi

  if ! command -v codex >/dev/null 2>&1; then
    echo "codex CLI not found; stopping." | tee -a ai/logs/baton.log
    exit 1
  fi

  step_log="$(mktemp)"
  set +e
  script -q -c "codex --model \"$MODEL\" \"Follow ai/next_agent.yaml exactly.\"" "$step_log"
  rc=$?
  set -e

  cat "$step_log" >> ai/logs/baton.log

  if [[ $rc -ne 0 ]]; then
    echo "Codex command failed (exit $rc); stopping." | tee -a ai/logs/baton.log
    rm -f "$step_log"
    exit 1
  fi

  if grep -q "WAITING FOR USER" "$step_log"; then
    echo "Stopped: WAITING FOR USER" | tee -a ai/logs/baton.log
    rm -f "$step_log"
    exit 0
  fi

  if grep -q "WAITING FOR BATON" "$step_log"; then
    echo "Stopped: WAITING FOR BATON" | tee -a ai/logs/baton.log
    rm -f "$step_log"
    exit 0
  fi

  if grep -q "HANDOFF TO " "$step_log"; then
    rm -f "$step_log"
    [[ $FULL_AUTO -eq 1 ]] || { echo "Stopped due to --no-full-auto after one handoff." | tee -a ai/logs/baton.log; exit 0; }
    continue
  fi

  echo "Unexpected output; stopping safely." | tee -a ai/logs/baton.log
  rm -f "$step_log"
  exit 1
done

echo "Reached max steps (${MAX_STEPS}); stopping safely." | tee -a ai/logs/baton.log
