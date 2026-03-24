#!/usr/bin/env bash
set -euo pipefail
#
# Usage: ./scripts/generate-next-agent.sh <ROLE> [--notes "context"] [--return-to "ROLE"]
#
# Generates ai/next_agent.yaml with minimal baton metadata only.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ROLE=""
NOTES=""
RETURN_TO=""

valid_roles="PRODUCT_OWNER SENIOR_JUDGMENTAL_ENGINEER ARCHITECT PLANNER DEV VALIDATOR REVIEWER HUMAN"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notes) NOTES="$2"; shift 2 ;;
    --return-to) RETURN_TO="$2"; shift 2 ;;
    --help|-h)
      echo "Usage: $0 <ROLE> [--notes \"context for next role\"] [--return-to \"ROLE\"]" >&2
      echo "Roles: $valid_roles" >&2
      exit 0
      ;;
    *)
      if [[ -z "$ROLE" ]]; then
        ROLE="$1"
        shift
      else
        echo "Error: unexpected argument '$1'" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$ROLE" ]]; then
  echo "Usage: $0 <ROLE> [--notes \"context for next role\"] [--return-to \"ROLE\"]" >&2
  echo "Roles: $valid_roles" >&2
  exit 1
fi

found=0
for role in $valid_roles; do
  if [[ "$ROLE" == "$role" ]]; then
    found=1
    break
  fi
done
if [[ $found -eq 0 ]]; then
  echo "Error: unknown role '$ROLE'" >&2
  echo "Valid roles: $valid_roles" >&2
  exit 1
fi

if [[ -n "$RETURN_TO" ]]; then
  found=0
  for role in $valid_roles; do
    if [[ "$RETURN_TO" == "$role" ]]; then
      found=1
      break
    fi
  done
  if [[ $found -eq 0 || "$RETURN_TO" == "HUMAN" ]]; then
    echo "Error: --return-to must be a non-HUMAN valid role" >&2
    exit 1
  fi
fi

{
  echo "next_role: $ROLE"
  if [[ -n "$NOTES" ]]; then
    echo "handoff_notes: |"
    while IFS= read -r line; do
      echo "  $line"
    done <<< "$NOTES"
  fi
  if [[ "$ROLE" == "HUMAN" && -n "$RETURN_TO" ]]; then
    echo "return_to: $RETURN_TO"
  fi
} > ai/next_agent.yaml

echo "Generated ai/next_agent.yaml with next_role=$ROLE"
