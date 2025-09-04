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
