#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

start_role="${1:-PRODUCT_OWNER}"

DEFAULTS_DIR="ai/defaults"

# ── Validate defaults directory exists ──
if [[ ! -d "$DEFAULTS_DIR" ]]; then
  echo "Error: $DEFAULTS_DIR not found. Cannot bootstrap without seed files."
  exit 1
fi

# ── Determine prompt file for starting role ──
prompt_file_for_role() {
  case "$1" in
    PRODUCT_OWNER)               echo "ai/prompts/00-product-owner.md" ;;
    SENIOR_JUDGMENTAL_ENGINEER)   echo "ai/prompts/01-senior-judgmental-engineer.md" ;;
    ARCHITECT)                   echo "ai/prompts/02-architect.md" ;;
    PLANNER)                     echo "ai/prompts/03-planner.md" ;;
    DEV)                         echo "ai/prompts/04-dev.md" ;;
    VALIDATOR)                   echo "ai/prompts/05-validator.md" ;;
    REVIEWER)                    echo "ai/prompts/06-reviewer.md" ;;
    *) echo "ERROR: unknown role: $1" >&2; exit 1 ;;
  esac
}

prompt_file="$(prompt_file_for_role "$start_role")"

# ── Ensure required directories exist ──
dirs=(
  ai
  ai/prompts
  ai/templates
  ai/iterations
  ai/logs
  apps
  infra
  context/repo
  context/old
)
for d in "${dirs[@]}"; do
  mkdir -p "$d"
done

# ── Copy defaults: mirror ai/defaults/ into ai/, skip existing files ──
echo "Copying defaults from $DEFAULTS_DIR ..."
while IFS= read -r src; do
  # Strip the "ai/defaults/" prefix to get the relative path
  rel="${src#${DEFAULTS_DIR}/}"
  dest="ai/${rel}"

  # Ensure destination directory exists
  mkdir -p "$(dirname "$dest")"

  if [[ ! -f "$dest" ]]; then
    cp "$src" "$dest"
    echo "  created $dest"
  else
    echo "  exists  $dest (kept)"
  fi
done < <(find "$DEFAULTS_DIR" -type f | sort)

# ── Generate dynamic state files (depend on starting role) ──
if [[ ! -f "ai/active_agent.txt" ]]; then
  printf '%s\n' "$start_role" > "ai/active_agent.txt"
  echo "  created ai/active_agent.txt"
else
  echo "  exists  ai/active_agent.txt (kept)"
fi

if [[ ! -f "ai/next_agent.yaml" ]]; then
  cat > "ai/next_agent.yaml" <<EOF
next_role: ${start_role}
prompt_file: ${prompt_file}
read:
  - ai/goal.yaml
  - ai/judgment.yaml
  - ai/constitution.yaml
  - ai/backlog.yaml
  - ai/active_item.yaml
  - ai/decision-lock.yaml
  - ai/active_agent.txt
allowed_edits:
  - ai/requirements.md
  - ai/decision-lock.yaml
  - ai/iterations/ITER-0001.md
  - ai/active_agent.txt
  - ai/next_agent.yaml
  - ai/next_agent.md
stop_conditions:
  - WAITING FOR BATON when active agent mismatch
  - WAITING FOR USER when clarification is required
success_criteria:
  - requirements updated
  - baton handed to next role
handoff_on_success:
  print_exact: HANDOFF TO SENIOR_JUDGMENTAL_ENGINEER
EOF
  echo "  created ai/next_agent.yaml"
else
  echo "  exists  ai/next_agent.yaml (kept)"
fi

if [[ ! -f "ai/next_agent.md" ]]; then
  cat > "ai/next_agent.md" <<EOF
# Next Agent

- Current role: \`${start_role}\`
- Prompt: \`${prompt_file}\`
- Execution command for Codex sessions: **Follow \`ai/next_agent.yaml\` exactly.**
- If role mismatch with \`ai/active_agent.txt\`, print: \`WAITING FOR BATON\`
EOF
  echo "  created ai/next_agent.md"
else
  echo "  exists  ai/next_agent.md (kept)"
fi

echo ""
echo "Bootstrap complete."
echo "  Active role : ${start_role}"
echo "  Prompt file : ${prompt_file}"
echo "  Baton state : ai/active_agent.txt"
echo "  Next agent  : ai/next_agent.yaml"
echo ""
echo "To validate:  ./scripts/check-baton.sh"
echo "To run Codex: Follow ai/next_agent.yaml exactly."
