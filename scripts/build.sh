#!/usr/bin/env bash
# Build "Coffee Tray.app": compile with SwiftPM, assemble a minimal .app bundle,
# and ad-hoc codesign it. No .xcodeproj — everything stays text and diffable.
set -euo pipefail

APP_NAME="Coffee Tray"
EXE_NAME="CoffeeTray"  # SwiftPM target / executable name (no spaces allowed)
BUILD_DIR=".build"
BUNDLE_DIR="${APP_NAME}.app"

# 1. Compile the release executable.
echo "==> swift build -c release"
swift build -c release

# Locate the built executable (arm64 on Apple Silicon; release config).
EXE_PATH="$(swift build -c release --show-bin-path)/${EXE_NAME}"
if [[ ! -x "${EXE_PATH}" ]]; then
    echo "error: built executable not found at ${EXE_PATH}" >&2
    exit 1
fi

# 2. Assemble the .app bundle structure.
echo "==> assembling ${BUNDLE_DIR}"
rm -rf "${BUNDLE_DIR}"
mkdir -p "${BUNDLE_DIR}/Contents/MacOS"
mkdir -p "${BUNDLE_DIR}/Contents/Resources"

cp "${EXE_PATH}" "${BUNDLE_DIR}/Contents/MacOS/${EXE_NAME}"
cp "Resources/Info.plist" "${BUNDLE_DIR}/Contents/Info.plist"

# 2b. Generate the app icon (the same ☕ glyph as the menu bar icon).
echo "==> generating AppIcon.icns"
ICONSET_DIR="$(mktemp -d)/AppIcon.iconset"
swift scripts/make-icon.swift "${ICONSET_DIR}"
iconutil -c icns "${ICONSET_DIR}" -o "${BUNDLE_DIR}/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "${ICONSET_DIR}")"

# 3. Ad-hoc codesign so the bundle is treated as an app (SMAppService needs this).
echo "==> codesign (ad-hoc)"
codesign --force --sign - --deep "${BUNDLE_DIR}"

echo ""
echo "Done: $(pwd)/${BUNDLE_DIR}"
echo "Run with: open \"${BUNDLE_DIR}\""
