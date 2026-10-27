#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_BUNDLE="$BUILD_DIR/Arcade Library.app"
CACHE_DIR="$PROJECT_DIR/.build_cache"

echo "=== Compilando Arcade Library para macOS Apple Silicon (ARM64) ==="

mkdir -p "$BUILD_DIR" "$CACHE_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

echo "-> Compilando código fuente con Swift 6..."
swiftc \
    -O \
    -disable-sandbox \
    -module-cache-path "$CACHE_DIR" \
    -parse-as-library \
    -lsqlite3 \
    "$PROJECT_DIR"/Theme/*.swift \
    "$PROJECT_DIR"/Models/*.swift \
    "$PROJECT_DIR"/Services/*.swift \
    "$PROJECT_DIR"/Views/*.swift \
    "$PROJECT_DIR"/App/*.swift \
    -o "$APP_BUNDLE/Contents/MacOS/ArcadeLibrary"

chmod +x "$APP_BUNDLE/Contents/MacOS/ArcadeLibrary"

echo "=== Compilación exitosa ==="
echo "Aplicación generada en: $APP_BUNDLE"
ls -lh "$APP_BUNDLE/Contents/MacOS/ArcadeLibrary"
