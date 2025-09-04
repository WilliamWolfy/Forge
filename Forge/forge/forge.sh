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
