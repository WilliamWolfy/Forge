#!/usr/bin/env bash
# ============================================================
# translate.sh — Basic translation helper (Forge template)
# ============================================================

set -euo pipefail

# Base directory (where language files are stored)
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANG_DIR="$BASE_DIR/../lang"

# ------------------------------------------------------------
# translate <key> <lang>
#   → Echo translation if found
#   → Return 0 on success, 1 on failure
# ------------------------------------------------------------
translate() {
  local key="$1"
  local lang="$2"

  [[ -z "$key" || -z "$lang" ]] && return 2  # mauvaise utilisation

  # Bypass si la langue demandée est "default"
  if [[ "$lang" == "default" ]]; then
    echo "$key"
    return 0
  fi

  local file="$LANG_DIR/$lang.json"
  [[ -f "$file" ]] || return 1  # langue non trouvée

  local value
  value="$(jq -r --arg k "$key" '.[$k] // empty' "$file" 2>/dev/null || true)"

  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  return 1  # clé introuvable
}
