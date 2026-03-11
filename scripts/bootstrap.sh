#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

start_role="${1:-PRODUCT_OWNER}"

cat > ai/active_agent.txt <<EOT
${start_role}
EOT

cat > ai/next_agent.yaml <<EOT
current_role: ${start_role}
prompt_file: ai/prompts/00-product-owner.md
instruction: Follow this role prompt exactly. Respect baton ownership and allowed edits.
active_item_source: ai/active_item.yaml
handoff_rules:
  on_complete: SENIOR_JUDGMENTAL_ENGINEER
  on_user_clarification_needed: WAITING_FOR_USER
EOT

if [[ ! -f ai/iterations/ITER-0001.md ]]; then
  mkdir -p ai/iterations
  cat > ai/iterations/ITER-0001.md <<EOT
# ITER-0001 Decision Log
EOT
fi

if [[ ! -f ai/logs/baton.log ]]; then
  mkdir -p ai/logs
  cat > ai/logs/baton.log <<EOT
# Baton run log
EOT
fi

echo "Bootstrap complete. Active role: ${start_role}"
