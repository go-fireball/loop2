#!/usr/bin/env python3
"""Validate baton YAML files for structure and required keys."""

import sys
import yaml

REQUIRED_KEYS = {
    "ai/goal.yaml": ["project_goal", "success_criteria"],
    "ai/judgment.yaml": ["backend_default", "architecture_default"],
    "ai/constitution.yaml": ["core_rules", "baton_rules"],
    "ai/backlog.yaml": ["items"],
    "ai/active_item.yaml": ["id", "status"],
    "ai/decision-lock.yaml": ["confirmed_by_user", "blocked_on_user"],
    "ai/next_agent.yaml": ["next_role", "prompt_file"],
}


def validate(filepath):
    # Normalize path for key lookup
    for suffix in REQUIRED_KEYS:
        if filepath.endswith(suffix):
            key = suffix
            break
    else:
        print(f"OK:   {filepath} (no schema to check)")
        return True

    try:
        with open(filepath, "r") as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"FAIL: {filepath} - invalid YAML: {e}")
        return False

    if data is None:
        print(f"FAIL: {filepath} - file is empty or null")
        return False

    if not isinstance(data, dict):
        print(f"FAIL: {filepath} - expected a YAML mapping, got {type(data).__name__}")
        return False

    missing = [k for k in REQUIRED_KEYS[key] if k not in data]
    if missing:
        print(f"FAIL: {filepath} - missing required keys: {', '.join(missing)}")
        return False

    print(f"OK:   {filepath}")
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: validate_baton.py <yaml-file> [<yaml-file> ...]")
        sys.exit(1)

    all_ok = True
    for path in sys.argv[1:]:
        if not validate(path):
            all_ok = False

    sys.exit(0 if all_ok else 1)
