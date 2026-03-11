#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MAX_STEPS=10
MODEL="gpt-5-codex"
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

./scripts/check-baton.sh

for ((step=1; step<=MAX_STEPS; step++)); do
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "[$ts] Step $step" | tee -a ai/logs/baton.log

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: would invoke codex --model $MODEL \"Follow ai/next_agent.yaml exactly.\"" | tee -a ai/logs/baton.log
    exit 0
  fi

  if ! command -v codex >/dev/null 2>&1; then
    echo "codex CLI not found; stopping." | tee -a ai/logs/baton.log
    exit 1
  fi

  set +e
  output="$(codex --model "$MODEL" "Follow ai/next_agent.yaml exactly." 2>&1)"
  rc=$?
  set -e

  echo "$output" >> ai/logs/baton.log

  if [[ $rc -ne 0 ]]; then
    echo "Codex command failed; stopping." | tee -a ai/logs/baton.log
    exit 1
  fi

  if grep -q "WAITING FOR USER" <<<"$output"; then
    echo "Stopped: WAITING FOR USER" | tee -a ai/logs/baton.log
    exit 0
  fi

  if grep -q "WAITING FOR BATON" <<<"$output"; then
    echo "Stopped: WAITING FOR BATON" | tee -a ai/logs/baton.log
    exit 0
  fi

  if grep -q "HANDOFF TO " <<<"$output"; then
    [[ $FULL_AUTO -eq 1 ]] || { echo "Stopped due to --no-full-auto after one handoff." | tee -a ai/logs/baton.log; exit 0; }
    continue
  fi

  echo "Unexpected output; stopping safely." | tee -a ai/logs/baton.log
  exit 1
done

echo "Reached max steps (${MAX_STEPS}); stopping safely." | tee -a ai/logs/baton.log
