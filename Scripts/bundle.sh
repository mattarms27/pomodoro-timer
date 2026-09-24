#!/usr/bin/env bash
# Builds a release binary with SwiftPM and wraps it in a signed macOS .app bundle.
# Usage: ./Scripts/bundle.sh [--run]
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Pomodoro Timer"
EXECUTABLE="PomodoroTimer"
APP_DIR="dist/${APP_NAME}.app"

echo "▸ Building release binary…"
swift build -c release --arch arm64

BIN_DIR="$(swift build -c release --arch arm64 --show-bin-path)"

echo "▸ Assembling ${APP_DIR}…"
rm -rf "${APP_DIR}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources"
cp "${BIN_DIR}/${EXECUTABLE}" "${APP_DIR}/Contents/MacOS/${EXECUTABLE}"
cp Resources/Info.plist "${APP_DIR}/Contents/Info.plist"
if [[ -f Resources/AppIcon.icns ]]; then
    cp Resources/AppIcon.icns "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

echo "▸ Signing (ad hoc)…"
codesign --force --deep --sign - "${APP_DIR}" >/dev/null

echo "✓ Built ${APP_DIR}"

if [[ "${1:-}" == "--run" ]]; then
    # Quit any running copy so the fresh build launches.
    osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
    sleep 0.5
    open "${APP_DIR}"
fi
