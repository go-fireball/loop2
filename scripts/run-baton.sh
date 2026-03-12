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
GIT_ENABLED=1

PROMPT="Follow ai/next_agent.yaml exactly."

usage() {
  cat <<'USAGE'
Usage: run-baton.sh [OPTIONS]

Options:
  --executor <codex|claude|copilot>   AI executor to use (required)
  --model <model>                     Model override (default depends on executor)
  --max-steps <n>                     Maximum baton steps (default: 10)
  --no-full-auto                      Stop after one handoff
  --no-git                            Disable branch-per-iteration git commits
  --dry-run                           Print the command that would run, then exit
  --help                              Show this help

Default models per executor:
  codex    → gpt-5.4
  claude   → claude-sonnet-4-6
  copilot  → claude-sonnet-4-6

Branch-per-iteration:
  Each run creates a git branch (iter/<ITEM-ID> or iter/<timestamp>) and
  auto-commits after every baton step. Disable with --no-git.

Examples:
  ./scripts/run-baton.sh --executor claude
  ./scripts/run-baton.sh --executor claude --model claude-opus-4-6
  ./scripts/run-baton.sh --executor codex --model o3 --max-steps 5
  ./scripts/run-baton.sh --executor copilot --dry-run
  ./scripts/run-baton.sh --executor claude --no-git
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
    --no-git)     GIT_ENABLED=0; shift ;;
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
      echo "exec"
      echo "--model"
      echo "$MODEL"
      if [[ $FULL_AUTO -eq 1 ]]; then
        echo "--full-auto"
      fi
      echo "$PROMPT"
      ;;
    claude)
      echo "claude"
      echo "--model"
      echo "$MODEL"
      echo "--dangerously-skip-permissions"
      echo "-p"
      echo "$PROMPT"
      ;;
    copilot)
      echo "copilot"
      echo "-p"
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
    copilot) cli="copilot" ;;
  esac
  if ! command -v "$cli" >/dev/null 2>&1; then
    echo "$cli CLI not found; install it before using --executor $EXECUTOR."
    exit 1
  fi
}

# ── Branch-per-iteration ──
# Creates a branch for this iteration and auto-commits after each step.
ITER_BRANCH=""
SOURCE_BRANCH=""

setup_iter_branch() {
  if [[ $GIT_ENABLED -eq 0 ]]; then
    return
  fi

  # Ensure we're in a git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Warning: not a git repo; disabling branch-per-iteration."
    GIT_ENABLED=0
    return
  fi

  # Fail if working tree is dirty — don't mix user changes with iteration commits
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "Warning: uncommitted changes detected; disabling branch-per-iteration."
    echo "Commit or stash your changes first to enable git tracking."
    GIT_ENABLED=0
    return
  fi

  SOURCE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

  # Derive branch name from active item ID, fall back to timestamp
  local item_id
  item_id="$(grep '^id:' ai/active_item.yaml 2>/dev/null | head -1 | sed 's/^id:[[:space:]]*//')"
  if [[ -z "$item_id" || "$item_id" == "null" ]]; then
    item_id="run-$(date -u +%Y%m%d-%H%M%S)"
  fi

  ITER_BRANCH="iter/${item_id}"

  # If branch already exists, append a counter
  if git rev-parse --verify "$ITER_BRANCH" >/dev/null 2>&1; then
    local counter=2
    while git rev-parse --verify "${ITER_BRANCH}-${counter}" >/dev/null 2>&1; do
      ((counter++))
    done
    ITER_BRANCH="${ITER_BRANCH}-${counter}"
  fi

  git checkout -b "$ITER_BRANCH"
  echo "Created iteration branch: $ITER_BRANCH (from $SOURCE_BRANCH)"
}

# Commit all changes after a baton step
commit_step() {
  local step_num="$1"
  local role="$2"

  if [[ $GIT_ENABLED -eq 0 ]]; then
    return
  fi

  # Only commit if there are changes
  if git diff --quiet && git diff --cached --quiet && [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
    return
  fi

  git add -A
  git commit -m "$(cat <<EOF
baton step $step_num: $role

Executor: $EXECUTOR | Model: $MODEL
Branch: $ITER_BRANCH
EOF
  )"
}

# ── Initial baton validation ──
if ! ./scripts/check-baton.sh; then
  echo "Baton state is invalid; cannot start."
  exit 1
fi

# ── Refuse to start when active agent is HUMAN ──
current_agent="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "")"
if [[ "$current_agent" == "HUMAN" ]]; then
  echo ""
  echo "Baton is held by HUMAN — waiting for your input."
  echo ""
  echo "  1. Answer questions in:  ai/user-questions.yaml"
  echo "  2. Then run:             ./scripts/resume-baton.sh"
  echo ""
  if [[ -f ai/user-questions.yaml ]]; then
    echo "Current questions:"
    cat ai/user-questions.yaml
  fi
  exit 0
fi

# ── Set up iteration branch after validation passes ──
setup_iter_branch

for ((step=1; step<=MAX_STEPS; step++)); do
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  current_role="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "UNKNOWN")"

  echo "[$ts] STEP $step START role=$current_role executor=$EXECUTOR model=$MODEL" | tee -a ai/logs/baton.log

  # ── Pre-step validation ──
  if ! ./scripts/check-baton.sh >/dev/null 2>&1; then
    echo "[$ts] STEP $step END role=$current_role result=INVALID_STATE" | tee -a ai/logs/baton.log
    exit 1
  fi

  # ── Build the command ──
  mapfile -t cmd < <(build_exec_cmd)

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: would invoke: ${cmd[*]}"
    exit 0
  fi

  check_cli

  step_log="$(mktemp)"
  set +e
  script -q -c "$(printf '%q ' "${cmd[@]}")" "$step_log"
  rc=$?
  set -e

  # Save full output to per-step log file (for debugging)
  step_log_file="ai/logs/step-$(printf '%03d' "$step")-${current_role}.log"
  cp "$step_log" "$step_log_file"

  end_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if [[ $rc -ne 0 ]]; then
    echo "[$end_ts] STEP $step END role=$current_role result=FAILED exit_code=$rc" | tee -a ai/logs/baton.log
    commit_step "$step" "$current_role (failed)"
    rm -f "$step_log"
    exit 1
  fi

  # Detect baton state from ai/active_agent.txt (the authoritative source).
  # Do NOT grep log output for signal strings — logs contain file contents
  # (e.g. constitution.yaml, prompt files) that include those strings verbatim,
  # causing false positives.
  new_agent="$(tr -d '[:space:]' < ai/active_agent.txt 2>/dev/null || echo "")"

  if [[ "$new_agent" == "HUMAN" ]]; then
    echo "[$end_ts] STEP $step END role=$current_role result=WAITING_FOR_USER" | tee -a ai/logs/baton.log
    commit_step "$step" "$current_role (waiting for user)"
    rm -f "$step_log"
    echo ""
    echo "Agent requested human input."
    if [[ -f ai/user-questions.yaml ]]; then
      echo "Questions in: ai/user-questions.yaml"
      echo ""
      cat ai/user-questions.yaml
    fi
    echo ""
    echo "After answering, run: ./scripts/resume-baton.sh"
    exit 0
  fi

  if [[ "$new_agent" != "$current_role" && -n "$new_agent" ]]; then
    echo "[$end_ts] STEP $step END role=$current_role result=HANDOFF to=$new_agent" | tee -a ai/logs/baton.log
    commit_step "$step" "$current_role"
    rm -f "$step_log"
    [[ $FULL_AUTO -eq 1 ]] || { echo "Stopped due to --no-full-auto after one handoff."; exit 0; }
    continue
  fi

  echo "[$end_ts] STEP $step END role=$current_role result=UNEXPECTED (active_agent unchanged: $new_agent)" | tee -a ai/logs/baton.log
  commit_step "$step" "$current_role (unexpected)"
  rm -f "$step_log"
  exit 1
done

echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] REACHED_MAX_STEPS ($MAX_STEPS)" | tee -a ai/logs/baton.log
commit_step "final" "max-steps-reached"
