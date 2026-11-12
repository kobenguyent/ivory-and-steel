#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Ivory & Steel — Test Suite Runner (Dual-Platform macOS XCTest & Web Vitest)
# ==============================================================================
# Executes unit, integration, and DSP audio math tests with clear reporting.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${MACOS_DIR}/.." && pwd)"

# Terminal Formatting
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

RUN_ALL=false
TEST_FILTER=""
PARALLEL=true

print_usage() {
    echo -e "${BOLD}${CYAN}Ivory & Steel — Test Suite Runner${RESET}"
    echo ""
    echo -e "${BOLD}USAGE:${RESET}"
    echo "  ./macos/scripts/run_tests.sh [OPTIONS]"
    echo "  npm run macos:test"
    echo ""
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo "  -f, --filter <NAME>   Run specific test suite or test method"
    echo "  --all                 Run both native macOS (XCTest) and Web (Vitest) suites"
    echo "  --parallel            Run Swift tests in parallel (Default)"
    echo "  --no-parallel         Run Swift tests sequentially"
    echo "  -h, --help            Show this helpful prompt and guide"
    echo ""
    echo -e "${BOLD}AVAILABLE MACOS TEST SUITES:${RESET}"
    echo "  • MusicTheoryEngineTests  (Diatonic harmony, Roman numerals, circle of fifths)"
    echo "  • AudioEngineTests        (Steinway DSP partials, ADSR envelopes, 16-voice pool)"
    echo "  • MetronomeEngineTests    (Sample-accurate audio clock, tempo subdivision)"
    echo "  • MIDIManagerTests        (Hot-plugging, CoreMIDI UMP, 12-TET note events)"
    echo "  • AppStateTests           (Navigation, reactive state, scale/chord selection)"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "  ./macos/scripts/run_tests.sh                            # Run all macOS tests"
    echo "  ./macos/scripts/run_tests.sh -f AudioEngineTests        # Target Audio DSP tests"
    echo "  ./macos/scripts/run_tests.sh -f MusicTheoryEngineTests  # Target Music Theory tests"
    echo "  ./macos/scripts/run_tests.sh --all                      # Run macOS XCTest + Web Vitest"
    echo ""
    echo -e "${BOLD}NPM SHORTCUTS:${RESET}"
    echo "  npm run macos:test    # Run macOS native tests"
    echo "  npm test              # Run Web Vitest tests"
    echo "  npm run test:all      # Run both suites end-to-end"
    echo ""
}

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--filter)
            if [ -n "${2:-}" ]; then
                TEST_FILTER="$2"
                shift 2
            else
                echo -e "${RED}[ERROR] --filter requires a suite or test name.${RESET}"
                exit 1
            fi
            ;;
        --all)
            RUN_ALL=true
            shift
            ;;
        --parallel)
            PARALLEL=true
            shift
            ;;
        --no-parallel)
            PARALLEL=false
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

START_TIME=$(date +%s)

echo -e "${BOLD}${CYAN}======================================================${RESET}"
echo -e "${BOLD}${CYAN}   Ivory & Steel — Test Suite Execution               ${RESET}"
echo -e "${BOLD}${CYAN}======================================================${RESET}"

# Auto-detect Xcode developer directory if default CLT lacks XCTest
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

cd "${MACOS_DIR}"

SWIFT_TEST_ARGS=()
if [ "${PARALLEL}" = true ]; then
    SWIFT_TEST_ARGS+=("--parallel")
fi
if [ -n "${TEST_FILTER}" ]; then
    SWIFT_TEST_ARGS+=("--filter" "${TEST_FILTER}")
    echo -e "${DIM}Filter active: ${BOLD}${TEST_FILTER}${RESET}"
fi

echo -e "${BOLD}[1/2] Running Native macOS XCTest Suite...${RESET}"
if swift test "${SWIFT_TEST_ARGS[@]}"; then
    echo -e "  ${GREEN}✓${RESET} macOS XCTest Suite: ${BOLD}${GREEN}PASS${RESET}"
else
    echo -e "  ${RED}✗${RESET} macOS XCTest Suite: ${BOLD}${RED}FAIL${RESET}"
    exit 1
fi

if [ "${RUN_ALL}" = true ]; then
    echo ""
    echo -e "${BOLD}[2/2] Running Web Vitest Suite...${RESET}"
    cd "${ROOT_DIR}"
    if npm test; then
        echo -e "  ${GREEN}✓${RESET} Web Vitest Suite: ${BOLD}${GREEN}PASS${RESET}"
    else
        echo -e "  ${RED}✗${RESET} Web Vitest Suite: ${BOLD}${RED}FAIL${RESET}"
        exit 1
    fi
else
    echo -e "${DIM}[2/2] Web Vitest Suite skipped (use --all to run both platforms)${RESET}"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}   All Test Verification Passed in ${DURATION}s!       ${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo ""
