#!/usr/bin/env bash
# ============================================================
# forge-bootstrap.sh — Bootstrap script for Forge project
# ============================================================

set -euo pipefail

# --- Defaults ---
PROJECT_NAME="forge"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"

MODE="auto"       # auto | local | remote
UPDATE="false"    # update files
SHOW_HELP="false"

# --- Parse CLI args ---
for arg in "$@"; do
  case "$arg" in
    --local)  MODE="local" ;;
    --remote) MODE="remote" ;;
    --auto)   MODE="auto" ;;
    --update) UPDATE="true" ;;
    -h|--help|help|?) SHOW_HELP="true" ;;
    *) PROJECT_NAME="$arg" ;;
  esac
done

# --- Help message ---
if [[ "$SHOW_HELP" == "true" ]]; then
  cat <<EOF
Forge Bootstrap
===============

Usage:
  ./forge-bootstrap.sh [options] [project-name]

Options:
  --local       Force local bootstrap only
  --remote      Force remote bootstrap only
  --auto        Try remote, fallback to local (default)
  --update      Overwrite existing files
  --help, -h    Show this help

Examples:
  ./forge-bootstrap.sh my-app       # Init project "my-app" (auto mode)
  ./forge-bootstrap.sh --local      # Init current dir in local mode
  ./forge-bootstrap.sh --update     # Refresh files
EOF
  exit 0
fi

# --- Setup project path ---
PROJECT_DIR="$BASE_DIR/$PROJECT_NAME"
mkdir -p "$PROJECT_DIR/core" "$PROJECT_DIR/lang" "$PROJECT_DIR/modules" "$PROJECT_DIR/templates"

# --- Remote repo (placeholder) ---
REMOTE_BASE="https://example.com/$PROJECT_NAME"
TEMPLATE_DIR="$BASE_DIR/templates"

echo "🔧 Bootstrapping project: $PROJECT_NAME ..."
echo "📦 Mode: $MODE | Update: $UPDATE"

# --- Fetch file helper ---
fetch_file() {
  local relpath="$1"
  local target="$PROJECT_DIR/$relpath"
  local template="$TEMPLATE_DIR/$relpath"

  if [[ -f "$target" && "$UPDATE" != "true" ]]; then
    echo "ℹ️  Skipping existing: $relpath"
    return
  fi

  # --- 1) Try remote if enabled ---
  if [[ "$MODE" == "remote" || "$MODE" == "auto" ]]; then
    if curl -fsSL "$REMOTE_BASE/$relpath" -o "$target"; then
      echo "✅ Fetched remote: $relpath"
      return
    else
      [[ "$MODE" == "remote" ]] && {
        echo "❌ Remote fetch failed for $relpath"
        return
      }
      echo "⚠️  Remote fetch failed → checking local template"
    fi
  fi

  # --- 2) Try local template if exists ---
  if [[ -f "$template" ]]; then
    mkdir -p "$(dirname "$target")"
    cp "$template" "$target"
    echo "✅ Copied template: $relpath"
    return
  fi

  # --- 3) Fallback hardcoded minimal ---
  case "$relpath" in
    README.md)
      echo "# $PROJECT_NAME" > "$target"
      ;;
    forge.sh)
      cat > "$target" <<'EOF'
#!/usr/bin/env bash
# ============================================================
# forge.sh — main entry point
# ============================================================

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$BASE_DIR/core/system.sh"

case "${1:-}" in
  init)
    echo "🚀 Initializing project: ${2:-my-app}"
    ;;
  help|--help|-h|?)
    echo "Usage: forge <command> [args]"
    echo "Commands:"
    echo "  init <name>   Initialize new project"
    echo "  help          Show this help"
    echo "  version       Show version"
    ;;
  version|--version|-v)
    echo "Forge version 0.1.0"
    ;;
  *)
    echo "❌ Unknown command: ${1:-}"
    echo "ℹ️  Run: forge help"
    ;;
esac
EOF
      chmod +x "$target"
      ;;
    core/system.sh)
      cat > "$target" <<'EOF'
# ============================================================
# core/system.sh — System utilities
# ============================================================

# Detect OS platform
detect_platform() {
  case "$(uname -s)" in
    Linux*)   echo "linux" ;;
    Darwin*)  echo "macos" ;;
    CYGWIN*|MINGW*|MSYS*|Windows*) echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}
EOF
      ;;
    lang/en.json)
      echo '{ "hello": "Hello" }' > "$target"
      ;;
    lang/fr.json)
      echo '{ "hello": "Bonjour" }' > "$target"
      ;;
    .gitignore)
      echo -e "node_modules/\n.env\n*.log\n" > "$target"
      ;;
    modules/.keep|templates/.keep)
      echo "" > "$target"
      ;;
    *)
      echo "" > "$target"
      ;;
  esac
  echo "✅ Created fallback: $relpath"
}

# --- Files to ensure ---
FILES=(
  "README.md"
  "forge.sh"
  "core/system.sh"
  "lang/en.json"
  "lang/fr.json"
  ".gitignore"
  "modules/.keep"
  "templates/.keep"
)

for f in "${FILES[@]}"; do
  fetch_file "$f"
done

# --- Detect platform (from system.sh) ---
source "$PROJECT_DIR/core/system.sh"
PLATFORM="$(detect_platform)"
echo "🖥️  Detected platform: $PLATFORM"

# --- Auto run alias setup ---
case "$PLATFORM" in
  linux|macos)
    if [[ -f "$BASE_DIR/forge-alias.sh" ]]; then
      bash "$BASE_DIR/forge-alias.sh" "$PROJECT_NAME"
    else
      echo "⚠️  Skipping alias setup: forge-alias.sh not found"
    fi
    ;;
  windows)
    if [[ -f "$BASE_DIR/forge-alias.ps1" ]]; then
      pwsh -ExecutionPolicy Bypass -File "$BASE_DIR/forge-alias.ps1" "$PROJECT_NAME"
    else
      echo "⚠️  Skipping alias setup: forge-alias.ps1 not found"
    fi
    ;;
  *)
    echo "⚠️  Unknown platform, cannot run alias setup"
    ;;
esac

echo "✅ Bootstrap complete!"
