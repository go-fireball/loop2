#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# ── Defaults ──
MAX_STEPS=10
EXECUTOR=""
MODEL=""
DRY_RUN=0
FULL_AUTO=1

PROMPT="Follow ai/next_agent.yaml exactly."

usage() {
  cat <<'USAGE'
Usage: run-baton.sh [OPTIONS]

Options:
  --executor <codex|claude|copilot>   AI executor to use (required)
  --model <model>                     Model override (default depends on executor)
  --max-steps <n>                     Maximum baton steps (default: 10)
  --no-full-auto                      Stop after one handoff
  --dry-run                           Print the command that would run, then exit
  --help                              Show this help

Default models per executor:
  codex    → gpt-5.4
  claude   → claude-sonnet-4-6
  copilot  → claude-sonnet-4-6

Examples:
  ./scripts/run-baton.sh --executor claude
  ./scripts/run-baton.sh --executor claude --model claude-opus-4-6
  ./scripts/run-baton.sh --executor codex --model o3 --max-steps 5
  ./scripts/run-baton.sh --executor copilot --dry-run
USAGE
  exit 0
}

# ── Parse flags ──
while [[ $# -gt 0 ]]; do
  case "$1" in
    --executor)   EXECUTOR="$2"; shift 2 ;;
    --model)      MODEL="$2"; shift 2 ;;
    --max-steps)  MAX_STEPS="$2"; shift 2 ;;
    --no-full-auto) FULL_AUTO=0; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --help)       usage ;;
    *) echo "Unknown flag: $1"; echo "Run with --help for usage."; exit 1 ;;
  esac
done

# ── Validate executor ──
if [[ -z "$EXECUTOR" ]]; then
  echo "Error: --executor is required. Choose one of: codex, claude, copilot"
  echo "Run with --help for usage."
  exit 1
fi

case "$EXECUTOR" in
  codex|claude|copilot) ;;
  *) echo "Error: unknown executor '$EXECUTOR'. Choose one of: codex, claude, copilot"; exit 1 ;;
esac

# ── Resolve default model per executor if not overridden ──
if [[ -z "$MODEL" ]]; then
  case "$EXECUTOR" in
    codex)   MODEL="gpt-5.4" ;;
    claude)  MODEL="claude-sonnet-4-6" ;;
    copilot) MODEL="claude-sonnet-4-6" ;;
  esac
fi

# ── Build executor command ──
# Each executor has its own CLI invocation pattern.
# The function prints the command array elements, one per line.
build_exec_cmd() {
  case "$EXECUTOR" in
    codex)
      echo "codex"
      echo "--model"
      echo "$MODEL"
      echo "-q"
      if [[ $FULL_AUTO -eq 1 ]]; then
        echo "--full-auto"
      fi
      echo "$PROMPT"
      ;;
    claude)
      echo "claude"
      echo "--model"
      echo "$MODEL"
      echo "-p"
      echo "$PROMPT"
      ;;
    copilot)
      echo "gh"
      echo "copilot"
      echo "suggest"
      echo "-t"
      echo "shell"
      echo "$PROMPT"
      ;;
  esac
}

# ── Check CLI is installed ──
check_cli() {
  local cli
  case "$EXECUTOR" in
    codex)   cli="codex" ;;
    claude)  cli="claude" ;;
    copilot) cli="gh" ;;
  esac
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "$cli CLI not found; install it before using --executor $EXECUTOR." | tee -a ai/logs/baton.log
    exit 1
  fi
}

# ── Initial baton validation ──
if ! ./scripts/check-baton.sh; then
  echo "Baton state is invalid; cannot start." | tee -a ai/logs/baton.log
  exit 1
fi

for ((step=1; step<=MAX_STEPS; step++)); do
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "[$ts] Step $step [$EXECUTOR model=$MODEL]" | tee -a ai/logs/baton.log

  # ── Pre-step validation ──
  if ! ./scripts/check-baton.sh >/dev/null 2>&1; then
    echo "[$ts] Baton state invalid before step $step; stopping." | tee -a ai/logs/baton.log
    exit 1
  fi

  # ── Build the command ──
  mapfile -t cmd < <(build_exec_cmd)

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: would invoke: ${cmd[*]}" | tee -a ai/logs/baton.log
    exit 0
  fi

  check_cli

  step_log="$(mktemp)"
  set +e
  script -q -c "$(printf '%q ' "${cmd[@]}")" "$step_log"
  rc=$?
  set -e

  cat "$step_log" >> ai/logs/baton.log

  if [[ $rc -ne 0 ]]; then
    echo "$EXECUTOR command failed (exit $rc); stopping." | tee -a ai/logs/baton.log
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
