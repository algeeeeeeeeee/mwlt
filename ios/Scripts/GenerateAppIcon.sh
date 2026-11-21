#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="$ROOT/public/meow.png"
SET_DIR="$ROOT/ios/Resources/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing Meowlett icon source: $SOURCE" >&2
  exit 1
fi

mkdir -p "$SET_DIR"
sips -s format png -z 1024 1024 "$SOURCE" --out "$SET_DIR/icon.png" >/dev/null

cat > "$SET_DIR/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "icon.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "Generated the native app icon from public/meow.png."
