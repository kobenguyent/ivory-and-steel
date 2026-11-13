#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Ivory & Steel — Native macOS App Builder & Packager
# ==============================================================================
# Builds the standalone .app bundle, signs it ad-hoc with audio & MIDI entitlements,
# strips quarantine flags, and packages distribution .zip and .dmg installers.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${MACOS_DIR}/.." && pwd)"
BUILD_DIR="${MACOS_DIR}/build"
APP_NAME="IvoryAndSteel"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_BIN_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
DMG_STAGING="${BUILD_DIR}/dmg_staging"
ARCH="$(uname -m)"

# Resolve version from VERSION env var or package.json
if [ -n "${VERSION:-}" ]; then
    RAW_VERSION="${VERSION}"
elif command -v node >/dev/null 2>&1 && [ -f "${ROOT_DIR}/package.json" ]; then
    RAW_VERSION="$(node -p "require('${ROOT_DIR}/package.json').version" 2>/dev/null || echo "1.0.0")"
else
    RAW_VERSION="1.0.0"
fi
CLEAN_VERSION="${RAW_VERSION#v}"
CLEAN_VERSION="${CLEAN_VERSION#V}"

# Terminal Formatting
BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"
RESET="\033[0m"

BUILD_CONFIG="release"
FAST_MODE=false
AUTO_LAUNCH=false

print_usage() {
    echo -e "${BOLD}${CYAN}Ivory & Steel — macOS Build & Packaging CLI${RESET}"
    echo ""
    echo -e "${BOLD}USAGE:${RESET}"
    echo "  ./macos/scripts/build_app.sh [OPTIONS]"
    echo "  npm run macos:build"
    echo ""
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo "  --release      Build optimized release binary & DMG/ZIP (Default)"
    echo "  --debug        Build unoptimized debug binary with full debug symbols"
    echo "  --fast         Fast mode: build & sign .app, skip .dmg/.zip generation"
    echo "  --open         Automatically launch the app upon successful build"
    echo "  -h, --help     Show this meaningful help prompt"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "  ./macos/scripts/build_app.sh                  # Full release build (.app + .dmg + .zip)"
    echo "  ./macos/scripts/build_app.sh --fast --open    # Rapid compile, sign, and launch"
    echo "  ./macos/scripts/build_app.sh --debug          # Fast debug build for local testing"
    echo ""
}

# Parse Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --release)
            BUILD_CONFIG="release"
            shift
            ;;
        --debug)
            BUILD_CONFIG="debug"
            shift
            ;;
        --fast)
            FAST_MODE=true
            shift
            ;;
        --open)
            AUTO_LAUNCH=true
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
echo -e "${BOLD}${CYAN}   Ivory & Steel — Native macOS Build Pipeline        ${RESET}"
echo -e "${BOLD}${CYAN}======================================================${RESET}"
echo -e "${DIM}Config: ${BOLD}${BUILD_CONFIG}${RESET}${DIM} | Fast Mode: ${BOLD}${FAST_MODE}${RESET}${DIM} | Auto-Launch: ${BOLD}${AUTO_LAUNCH}${RESET}"
echo ""

# 1. Compile Swift Binary
echo -e "${BOLD}[1/5] Compiling Swift binary (${BUILD_CONFIG})...${RESET}"

# Auto-detect Xcode developer directory if default CLT lacks Swift macro plugins
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

cd "${MACOS_DIR}"

if [ "${BUILD_CONFIG}" = "release" ]; then
    swift build -c release
    BIN_DIR="$(swift build -c release --show-bin-path)"
    BIN_PATH="${BIN_DIR}/${APP_NAME}"
    if [ ! -f "${BIN_PATH}" ]; then
        BIN_PATH="${MACOS_DIR}/.build/release/${APP_NAME}"
    fi
else
    swift build
    BIN_DIR="$(swift build --show-bin-path)"
    BIN_PATH="${BIN_DIR}/${APP_NAME}"
    if [ ! -f "${BIN_PATH}" ]; then
        BIN_PATH="${MACOS_DIR}/.build/debug/${APP_NAME}"
    fi
fi

if [ ! -f "${BIN_PATH}" ]; then
    echo -e "${RED}[ERROR] Binary not found at ${BIN_PATH}${RESET}"
    exit 1
fi
echo -e "  ${GREEN}✓${RESET} Binary compiled: ${DIM}${BIN_PATH}${RESET}"

# 2. Prepare .app Bundle Structure
echo -e "${BOLD}[2/5] Staging .app bundle hierarchy...${RESET}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_BIN_DIR}"
mkdir -p "${RESOURCES_DIR}"

# 3. Copy Executable, Icons & Metadata
echo -e "${BOLD}[3/5] Packaging binary, icons, and metadata...${RESET}"
cp "${BIN_PATH}" "${MACOS_BIN_DIR}/${APP_NAME}"
chmod 755 "${MACOS_BIN_DIR}/${APP_NAME}"

if [ -f "${MACOS_DIR}/Resources/Info.plist" ]; then
    cp "${MACOS_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
    if [ -n "${CLEAN_VERSION}" ] && [ -x "/usr/libexec/PlistBuddy" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${CLEAN_VERSION}" "${CONTENTS_DIR}/Info.plist" || true
    fi
else
    echo -e "${RED}[ERROR] Missing Info.plist at ${MACOS_DIR}/Resources/Info.plist${RESET}"
    exit 1
fi

if [ -f "${MACOS_DIR}/Resources/AppIcon.icns" ]; then
    cp "${MACOS_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

if [ -f "${MACOS_DIR}/Resources/AppIcon.png" ]; then
    cp "${MACOS_DIR}/Resources/AppIcon.png" "${RESOURCES_DIR}/AppIcon.png"
fi

# Copy SPM resource bundle if present
if [ -d "${BIN_DIR}/${APP_NAME}_${APP_NAME}.bundle" ]; then
    cp -R "${BIN_DIR}/${APP_NAME}_${APP_NAME}.bundle" "${RESOURCES_DIR}/"
fi

echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"
echo -e "  ${GREEN}✓${RESET} Bundle structure assembled: ${DIM}${APP_BUNDLE}${RESET}"

# 4. Ad-Hoc Codesign & Quarantine Removal
echo -e "${BOLD}[4/5] Ad-hoc code signing & removing quarantine bits...${RESET}"
ENTITLEMENTS="${MACOS_DIR}/Resources/IvoryAndSteel.entitlements"

codesign --force --deep --sign - --entitlements "${ENTITLEMENTS}" "${APP_BUNDLE}"
xattr -cr "${APP_BUNDLE}"

# Strict Signature Verification
codesign --verify --deep --strict --verbose=1 "${APP_BUNDLE}" 2>&1 | while read -r line; do
    echo -e "  ${DIM}${line}${RESET}"
done
echo -e "  ${GREEN}✓${RESET} Code signature verified successfully (Ad-Hoc, No Dev Account Required)"

# 5. Packaging Distribution Artifacts (.dmg, .zip, and SHA256SUMS.txt)
if [ "${FAST_MODE}" = false ]; then
    echo -e "${BOLD}[5/5] Generating distribution installers (.dmg, .zip, SHA256SUMS.txt)...${RESET}"
    ZIP_VERSIONED="${BUILD_DIR}/${APP_NAME}-${CLEAN_VERSION}-macOS-${ARCH}.zip"
    DMG_VERSIONED="${BUILD_DIR}/${APP_NAME}-${CLEAN_VERSION}-macOS-${ARCH}.dmg"
    rm -f "${BUILD_DIR}/${APP_NAME}.zip" "${BUILD_DIR}/${APP_NAME}.dmg" "${ZIP_VERSIONED}" "${DMG_VERSIONED}" "${BUILD_DIR}/SHA256SUMS.txt"

    # Create zip preserving resource forks, symlinks, and permissions
    ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${BUILD_DIR}/${APP_NAME}.zip"
    cp "${BUILD_DIR}/${APP_NAME}.zip" "${ZIP_VERSIONED}"

    # Stage DMG with IvoryAndSteel.app + /Applications shortcut + one-click Gatekeeper-bypass installer
    rm -rf "${DMG_STAGING}"
    mkdir -p "${DMG_STAGING}"
    cp -R "${APP_BUNDLE}" "${DMG_STAGING}/${APP_NAME}.app"
    ln -s /Applications "${DMG_STAGING}/Applications"

    cat > "${DMG_STAGING}/Install Ivory & Steel (No Apple Dev Account).command" <<'INSTALLER_EOF'
#!/usr/bin/env bash
set -euo pipefail
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_SRC="${SRC_DIR}/IvoryAndSteel.app"
if [ -w "/Applications" ]; then
    DEST_DIR="/Applications"
else
    DEST_DIR="${HOME}/Applications"
    mkdir -p "${DEST_DIR}"
fi
DEST_APP="${DEST_DIR}/IvoryAndSteel.app"
echo "==> Installing Ivory & Steel to ${DEST_APP}"
rm -rf "${DEST_APP}"
ditto "${APP_SRC}" "${DEST_APP}"
echo "==> Removing browser quarantine attribute & applying local ad-hoc signature"
xattr -cr "${DEST_APP}" 2>/dev/null || true
codesign --force --deep --sign - "${DEST_APP}" 2>/dev/null || true
echo "==> Installed! Launching Ivory & Steel..."
open "${DEST_APP}"
INSTALLER_EOF
    chmod +x "${DMG_STAGING}/Install Ivory & Steel (No Apple Dev Account).command"

    # Create Apple Disk Image (UDZO)
    hdiutil create -volname "Ivory & Steel" -srcfolder "${DMG_STAGING}" -ov -format UDZO "${BUILD_DIR}/${APP_NAME}.dmg" > /dev/null
    cp "${BUILD_DIR}/${APP_NAME}.dmg" "${DMG_VERSIONED}"
    rm -rf "${DMG_STAGING}"

    # Generate SHA-256 checksums for release verification
    (
        cd "${BUILD_DIR}"
        shasum -a 256 "${APP_NAME}.dmg" "${APP_NAME}.zip" "$(basename "${DMG_VERSIONED}")" "$(basename "${ZIP_VERSIONED}")" > SHA256SUMS.txt
    )

    ZIP_SIZE="$(du -h "${BUILD_DIR}/${APP_NAME}.zip" | cut -f1)"
    DMG_SIZE="$(du -h "${BUILD_DIR}/${APP_NAME}.dmg" | cut -f1)"
    echo -e "  ${GREEN}✓${RESET} Disk Image (.dmg): ${BOLD}${DMG_SIZE}${RESET} ${DIM}(${BUILD_DIR}/${APP_NAME}.dmg)${RESET}"
    echo -e "  ${GREEN}✓${RESET} Zip Archive (.zip): ${BOLD}${ZIP_SIZE}${RESET} ${DIM}(${BUILD_DIR}/${APP_NAME}.zip)${RESET}"
    echo -e "  ${GREEN}✓${RESET} Checksums:          ${DIM}${BUILD_DIR}/SHA256SUMS.txt${RESET}"
else
    echo -e "${BOLD}[5/5] Skipping .dmg/.zip creation (--fast mode active)${RESET}"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

APP_SIZE="$(du -h -d 0 "${APP_BUNDLE}" | cut -f1)"

echo ""
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "${BOLD}${GREEN}   Build Completed Successfully in ${DURATION}s!       ${RESET}"
echo -e "${BOLD}${GREEN}======================================================${RESET}"
echo -e "  ${BOLD}App Bundle:${RESET}  ${APP_BUNDLE} ${DIM}(${APP_SIZE})${RESET}"
if [ "${FAST_MODE}" = false ]; then
    echo -e "  ${BOLD}Disk Image:${RESET}  ${BUILD_DIR}/${APP_NAME}.dmg ${DIM}(${DMG_SIZE})${RESET}"
    echo -e "  ${BOLD}Zip File:${RESET}    ${BUILD_DIR}/${APP_NAME}.zip ${DIM}(${ZIP_SIZE})${RESET}"
fi
echo ""
echo -e "${BOLD}Next Steps:${RESET}"
echo -e "  • Launch App:      ${CYAN}./macos/scripts/run.sh${RESET}  or  ${CYAN}open \"${APP_BUNDLE}\"${RESET}"
echo -e "  • Run Tests:       ${CYAN}./macos/scripts/run_tests.sh${RESET}"
echo -e "  • Open in Xcode:   ${CYAN}xed macos${RESET}"
echo ""

if [ "${AUTO_LAUNCH}" = true ]; then
    echo -e "${CYAN}Launching Ivory & Steel...${RESET}"
    open "${APP_BUNDLE}"
fi
