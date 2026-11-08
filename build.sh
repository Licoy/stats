#!/bin/bash
# 本地打包：编译 Release 版 Stats（ad-hoc 签名，不需要开发者证书）
#   ./build.sh            打包 build/Stats.dmg
#   ./build.sh --open     打包后打开 dmg
#   ./build.sh --release  不打包 dmg，直接安装到 /Applications 并重启正在运行的 Stats
set -euo pipefail

cd "$(dirname "$0")"

OPEN_DMG=false
INSTALL=false
for arg in "$@"; do
	case "$arg" in
		--open) OPEN_DMG=true ;;
		--release) INSTALL=true ;;
		*) echo "Unknown option: $arg"; echo "Usage: $0 [--open] [--release]"; exit 1 ;;
	esac
done

BUILD_PATH="build"
DERIVED_DATA="$BUILD_PATH/DerivedData"
APP="$DERIVED_DATA/Build/Products/Release/Stats.app"
DMG="$BUILD_PATH/Stats.dmg"
INSTALL_PATH="/Applications/Stats.app"

echo "==> Building Stats (Release)..."
xcodebuild \
	-project Stats.xcodeproj \
	-scheme Stats \
	-configuration Release \
	-derivedDataPath "$DERIVED_DATA" \
	-quiet \
	CODE_SIGN_IDENTITY="-" \
	CODE_SIGNING_REQUIRED=NO \
	DEVELOPMENT_TEAM="" \
	build

if $INSTALL; then
	WAS_RUNNING=false
	if pgrep -x Stats >/dev/null; then
		WAS_RUNNING=true
		echo "==> Quitting running Stats..."
		pkill -x Stats || true
		while pgrep -x Stats >/dev/null; do sleep 0.2; done
	fi

	echo "==> Installing to $INSTALL_PATH"
	rm -rf "$INSTALL_PATH"
	ditto "$APP" "$INSTALL_PATH"

	if $WAS_RUNNING; then
		echo "==> Relaunching Stats..."
		open "$INSTALL_PATH"
	fi
	exit 0
fi

echo "==> Creating $DMG"
STAGING="$BUILD_PATH/dmg"
rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/Stats.app"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname Stats -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo "==> Done: $DMG"
if $OPEN_DMG; then
	open "$DMG"
fi
