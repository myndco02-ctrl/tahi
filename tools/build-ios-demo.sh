#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ "$(uname -s)" != Darwin ]; then
  echo 'An iOS build requires macOS with Xcode.' >&2
  exit 1
fi
flutter pub get
flutter build ios --release --no-codesign
mkdir -p dist
staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
mkdir "$staging/Payload"
cp -R build/ios/iphoneos/Runner.app "$staging/Payload/"
destination="$PWD/dist/elTahi-demo-unsigned.ipa"
archive="$staging/elTahi-demo-unsigned.ipa"
(cd "$staging" && /usr/bin/zip -qry "$archive" Payload)
cp "$archive" "$destination"
echo "Unsigned IPA ready for signing with Sideloadly: $destination"
