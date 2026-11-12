#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Ivory & Steel — Native macOS App Launcher & Runner
# ==============================================================================
# Builds (optional fast/debug/release) and launches Ivory & Steel on macOS.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${MACOS_DIR}/build"
APP_NAME="IvoryAndSteel"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"

# Terminal Colors & Styles
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

# Default Configuration
NO_BUILD=false
FAST_MODE=true
BUILD_CONFIG="release"
KILL_EXISTING=true

print_usage() {
    echo -e "${BOLD}${CYAN}Ivory & Steel — Native macOS App Runner${RESET}"
    echo ""
    echo -e "${BOLD}USAGE:${RESET}"
    echo "  ./macos/scripts/run.sh [OPTIONS]"
    echo "  npm run macos"
    echo ""
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo "  -f, --fast          Fast compile & launch without generating DMG/ZIP (Default)"
    echo "  -n, --no-build      Skip compilation entirely; launch existing .app bundle directly"
    echo "  -d, --debug         Build in debug mode with full symbols before launching"
    echo "  -r, --release       Build full production release with DMG & ZIP before launching"
    echo "  -k, --kill          Terminate any running Ivory & Steel instance before launch (Default)"
    echo "      --no-kill       Do not terminate existing running instances"
    echo "  -h, --help          Show this helpful prompt and guide"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "  ./macos/scripts/run.sh             # Fast build and launch (Recommended)"
    echo "  ./macos/scripts/run.sh -n          # Instant launch existing build (zero wait)"
    echo "  ./macos/scripts/run.sh -d          # Compile debug build and launch"
    echo "  ./macos/scripts/run.sh -r          # Full release packaging + launch"
    echo ""
    echo -e "${BOLD}NPM SHORTCUTS:${RESET}"
    echo "  npm run macos          # Fast build and launch"
    echo "  npm run macos:fast     # Alias for fast compile & launch"
    echo "  npm run macos:build    # Full release package (.app + .dmg + .zip)"
    echo "  npm run macos:test     # Run native macOS test suite"
    echo ""
}

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--fast)
            FAST_MODE=true
            NO_BUILD=false
            shift
            ;;
        -n|--no-build)
            NO_BUILD=true
            shift
            ;;
        -d|--debug)
            BUILD_CONFIG="debug"
            NO_BUILD=false
            shift
            ;;
        -r|--release)
            FAST_MODE=false
            BUILD_CONFIG="release"
            NO_BUILD=false
            shift
            ;;
        -k|--kill)
            KILL_EXISTING=true
            shift
            ;;
        --no-kill)
            KILL_EXISTING=false
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}[ERROR] Unknown option: $1${RESET}"
            echo ""
            print_usage
            exit 1
            ;;
    esac
done

echo -e "${BOLD}${CYAN}======================================================${RESET}"
echo -e "${BOLD}${CYAN}   Ivory & Steel — Native macOS Runner               ${RESET}"
echo -e "${BOLD}${CYAN}======================================================${RESET}"

# Kill any existing instance if requested
if [ "${KILL_EXISTING}" = true ]; then
    if pgrep -x "${APP_NAME}" > /dev/null 2>&1; then
        echo -e "${DIM}Stopping running instance of ${APP_NAME}...${RESET}"
        pkill -x "${APP_NAME}" || true
        sleep 0.3
    fi
fi

# Step 1: Build if needed
if [ "${NO_BUILD}" = false ]; then
    BUILD_FLAGS=()
    if [ "${FAST_MODE}" = true ]; then
        BUILD_FLAGS+=("--fast")
    fi
    if [ "${BUILD_CONFIG}" = "debug" ]; then
        BUILD_FLAGS+=("--debug")
    else
        BUILD_FLAGS+=("--release")
    fi
    
    echo -e "${DIM}Invoking build pipeline with flags: ${BUILD_FLAGS[*]}${RESET}"
    "${SCRIPT_DIR}/build_app.sh" "${BUILD_FLAGS[@]}"
else
    echo -e "${DIM}Skipping build (--no-build flag active)${RESET}"
    if [ ! -d "${APP_BUNDLE}" ]; then
        echo -e "${RED}[ERROR] App bundle not found at:${RESET} ${APP_BUNDLE}"
        echo -e "${YELLOW}Please build the application first by running:${RESET}"
        echo "  ./macos/scripts/build_app.sh --fast"
        exit 1
    fi
fi

# Step 2: Launch App
echo ""
echo -e "${BOLD}${GREEN}▶ Launching Ivory & Steel...${RESET}"
open "${APP_BUNDLE}"
echo -e "  ${GREEN}✓${RESET} App running: ${DIM}${APP_BUNDLE}${RESET}"
echo ""
