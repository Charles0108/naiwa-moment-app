#!/usr/bin/env bash
set -euo pipefail
NAIWA_SOURCE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$NAIWA_SOURCE/app"
flutter pub get
flutter build macos --release
mkdir -p "$NAIWA_SOURCE/outputs/apple"
MAC_APP="$(find build/macos/Build/Products/Release -maxdepth 1 -name '*.app' -print -quit)"
ditto -c -k --sequesterRsrc --keepParent "$MAC_APP" "$NAIWA_SOURCE/outputs/apple/NaiwaMoment-macOS.zip"
flutter build ios --release --no-codesign
mkdir -p "$NAIWA_SOURCE/work/ios-package/Payload"
ditto build/ios/iphoneos/Runner.app "$NAIWA_SOURCE/work/ios-package/Payload/Runner.app"
cd "$NAIWA_SOURCE/work/ios-package"
zip -q -r "$NAIWA_SOURCE/outputs/apple/NaiwaMoment-iOS-unsigned.ipa" Payload
