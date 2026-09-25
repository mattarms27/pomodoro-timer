#!/usr/bin/env bash
# Builds the app and packages it into a drag-to-install disk image.
# Usage: ./Scripts/make-dmg.sh [--skip-build]
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Pomodoro Timer"
APP_DIR="dist/${APP_NAME}.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' Resources/Info.plist)"
DMG_PATH="dist/Pomodoro-Timer-${VERSION}.dmg"
BACKGROUND_2X="Resources/DMG/background@2x.png"

# Finder window layout, in points. The background is drawn at 2x for this size.
WINDOW_WIDTH=660
WINDOW_HEIGHT=400
ICON_SIZE=128
ICON_Y=247
APP_ICON_X=150
APPLICATIONS_ICON_X=510
# Finder's window bounds include the title bar, which sits above the background.
TITLE_BAR_HEIGHT=32

if [[ "${1:-}" != "--skip-build" ]]; then
    ./Scripts/bundle.sh
fi

WORK_DIR="$(mktemp -d)"
MOUNT_DIR="${WORK_DIR}/mount"
trap 'hdiutil detach "${MOUNT_DIR}" -quiet -force 2>/dev/null || true; rm -rf "${WORK_DIR}"' EXIT

echo "▸ Staging disk image contents…"
STAGING="${WORK_DIR}/staging"
mkdir -p "${STAGING}/.background"
cp -R "${APP_DIR}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

# A multi-resolution TIFF keeps the background sharp on Retina and standard displays.
sips -z "${WINDOW_HEIGHT}" "${WINDOW_WIDTH}" "${BACKGROUND_2X}" --out "${WORK_DIR}/background.png" >/dev/null
tiffutil -cathidpicheck "${WORK_DIR}/background.png" "${BACKGROUND_2X}" \
    -out "${STAGING}/.background/background.tiff" 2>/dev/null

cp Resources/AppIcon.icns "${STAGING}/.VolumeIcon.icns"

echo "▸ Creating writable image…"
RW_DMG="${WORK_DIR}/rw.dmg"
hdiutil create -quiet -srcfolder "${STAGING}" -volname "${APP_NAME}" \
    -fs HFS+ -format UDRW -ov "${RW_DMG}"

mkdir -p "${MOUNT_DIR}"
hdiutil attach -quiet -readwrite -noverify -noautoopen -mountpoint "${MOUNT_DIR}" "${RW_DMG}"
SetFile -a C "${MOUNT_DIR}"

echo "▸ Arranging the Finder window…"
osascript <<EOF
tell application "Finder"
    set dmgFolder to POSIX file "${MOUNT_DIR}" as alias
    open dmgFolder
    set dmgWindow to container window of dmgFolder
    set current view of dmgWindow to icon view
    set toolbar visible of dmgWindow to false
    set statusbar visible of dmgWindow to false
    set bounds of dmgWindow to {200, 120, 200 + ${WINDOW_WIDTH}, 120 + ${WINDOW_HEIGHT} + ${TITLE_BAR_HEIGHT}}
    set viewOptions to icon view options of dmgWindow
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to ${ICON_SIZE}
    set text size of viewOptions to 13
    set background picture of viewOptions to file ".background:background.tiff" of dmgFolder
    set position of item "${APP_NAME}.app" of dmgFolder to {${APP_ICON_X}, ${ICON_Y}}
    set position of item "Applications" of dmgFolder to {${APPLICATIONS_ICON_X}, ${ICON_Y}}
    update dmgFolder without registering applications
    delay 1
    close dmgWindow
end tell
EOF

sync
hdiutil detach -quiet "${MOUNT_DIR}"

echo "▸ Compressing ${DMG_PATH}…"
rm -f "${DMG_PATH}"
hdiutil convert -quiet "${RW_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}"

echo "✓ Built ${DMG_PATH}"
