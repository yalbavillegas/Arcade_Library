#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
CACHE_DIR="$PROJECT_DIR/.build_cache"
TEST_RUNNER="$BUILD_DIR/arcade_test_runner"

echo "=== Compilando Suite de Pruebas Automatizadas de Arcade Library ==="
mkdir -p "$BUILD_DIR" "$CACHE_DIR"

swiftc \
    -O \
    -disable-sandbox \
    -module-cache-path "$CACHE_DIR" \
    -parse-as-library \
    -lsqlite3 \
    "$PROJECT_DIR"/Models/*.swift \
    "$PROJECT_DIR"/Services/*.swift \
    "$PROJECT_DIR"/Tests/ArcadeLibraryTests.swift \
    -o "$TEST_RUNNER"

chmod +x "$TEST_RUNNER"

echo "=== Ejecutando 15 Pruebas de Validación ==="
"$TEST_RUNNER"
