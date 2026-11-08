#!/bin/bash
# 本地开发：编译 Debug 版 Stats 并在前台运行（日志直接输出到终端，Ctrl+C 退出）
set -euo pipefail

cd "$(dirname "$0")"

DERIVED_DATA="build/DerivedData"
APP="$DERIVED_DATA/Build/Products/Debug/Stats.app"

echo "==> Building Stats (Debug)..."
xcodebuild \
	-project Stats.xcodeproj \
	-scheme Stats \
	-configuration Debug \
	-derivedDataPath "$DERIVED_DATA" \
	-quiet \
	CODE_SIGN_IDENTITY="-" \
	CODE_SIGNING_REQUIRED=NO \
	DEVELOPMENT_TEAM="" \
	build

# 正式版和 Debug 版 Bundle ID 相同，同时运行会冲突
if pgrep -x Stats >/dev/null; then
	echo "==> Quitting running Stats..."
	pkill -x Stats || true
	while pgrep -x Stats >/dev/null; do sleep 0.2; done
fi

echo "==> Launching $APP"
exec "$APP/Contents/MacOS/Stats"
