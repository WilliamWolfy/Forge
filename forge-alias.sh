#!/usr/bin/env bash
# ============================================================
# forge-alias.sh — install alias for Forge project
# ============================================================

set -euo pipefail

# --- Default project name ---
PROJECT_NAME="${1:-forge}"

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_BIN="$BASE_DIR/$PROJECT_NAME/forge.sh"

if [[ ! -f "$PROJECT_BIN" ]]; then
  echo "❌ Project binary not found: $PROJECT_BIN"
  exit 1
fi

echo "🔧 Running Forge alias setup for project: $PROJECT_NAME"

# --- Detect platform (from core/system.sh if exists) ---
detect_platform_fallback() {
  case "$(uname -s)" in
    Linux*)   echo "Linux" ;;
    Darwin*)  echo "macOS" ;;
    CYGWIN*|MINGW*|MSYS*) echo "Windows" ;;
    *)        echo "Unknown" ;;
  esac
}

if [[ -f "$BASE_DIR/$PROJECT_NAME/core/system.sh" ]]; then
  source "$BASE_DIR/$PROJECT_NAME/core/system.sh"
  PLATFORM="$(detect_platform)"
else
  PLATFORM="$(detect_platform_fallback)"
fi
echo "📦 Detected platform: $PLATFORM"

# --- Purge old alias for this project ---
purge_alias() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -i -E "/^[[:space:]]*alias[[:space:]]+$PROJECT_NAME=/d" "$file" || true
}
purge_alias "$HOME/.bashrc"
purge_alias "$HOME/.bash_aliases"
purge_alias "$HOME/.zshrc"

# --- Try global install ---
install_global() {
  local target="/usr/local/bin/$PROJECT_NAME"
  if command -v sudo >/dev/null 2>&1; then
    if sudo install -m 0755 "$PROJECT_BIN" "$target" 2>/dev/null; then
      echo "✅ Installed globally → run: $PROJECT_NAME"
      return 0
    fi
  fi
  return 1
}

if install_global; then
  echo "🚀 Done."
  exit 0
else
  echo "⚠️  Global install not available. Using local wrapper."
fi

# --- Local wrapper install ---
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

WRAPPER="$LOCAL_BIN/$PROJECT_NAME"
cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash
exec "$PROJECT_BIN" "\$@"
EOF
chmod +x "$WRAPPER"
echo "✅ Local wrapper created at: $WRAPPER"

# --- Ensure PATH includes ~/.local/bin ---
SHELL_RC="$HOME/.bashrc"
[[ -n "${ZSH_VERSION:-}" ]] && SHELL_RC="$HOME/.zshrc"

ensure_path_snippet='
# >>> Forge PATH >>>
case ":$PATH:" in
  *:"$HOME/.local/bin":*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# <<< Forge PATH <<<
'
if ! grep -q '<<< Forge PATH <<<' "$SHELL_RC" 2>/dev/null; then
  printf "\n%s\n" "$ensure_path_snippet" >> "$SHELL_RC"
  echo "✅ PATH update appended to $SHELL_RC"
fi

echo "🔄 Restart your shell or run: source \"$SHELL_RC\""
echo "🚀 Alias setup complete! → Try running: $PROJECT_NAME help"
