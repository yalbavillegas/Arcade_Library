#!/bin/bash
set -e

# Locate the generated JPEG icon (first match)
ICON_SRC=$(find "$HOME/.gemini/antigravity-ide/brain/5808f7f3-bfcc-45e0-9bca-36ae7e83f071" -name "arcade_library_icon_*.jpg" | head -n 1)

if [ -z "$ICON_SRC" ]; then
  echo "Generated icon not found"
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/Resources"
ICONSET_DIR="$PROJECT_ROOT/tmp.iconset"

mkdir -p "$ICONSET_DIR"

# Create required icon sizes (including @2x variants)
# Base sizes: 16, 32, 128, 256, 512, 1024 (1024 only base, no @2x)
for size in 16 32 128 256 512 1024; do
  sips -z $size $size "$ICON_SRC" -s format png --out "$ICONSET_DIR/icon_${size}x${size}.png"
done

# Create @2x variants for sizes 16, 32, 128, 256, 512
for size in 16 32 128 256 512; do
  double=$((size * 2))
  sips -z $double $double "$ICON_SRC" -s format png --out "$ICONSET_DIR/icon_${size}x${size}@2x.png"
done

# Build .icns file
iconutil -c icns "$ICONSET_DIR"

# Move generated .icns to Resources folder, overwrite existing
mv "$ICONSET_DIR.icns" "$RESOURCES_DIR/AppIcon.icns"

# Clean up temporary iconset directory
rm -rf "$ICONSET_DIR"

echo "App icon generated and placed at $RESOURCES_DIR/AppIcon.icns"
