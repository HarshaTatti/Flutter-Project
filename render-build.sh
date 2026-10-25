#!/usr/bin/env bash
# Render Build Script for Flutter Web Application
set -euo pipefail

echo "========================================="
echo "   Privacy-Preserving Chatbot Web Build  "
echo "========================================="

FLUTTER_DIR="$HOME/flutter"

# Check if Flutter SDK already exists (e.g. cached), otherwise clone shallow stable
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  echo "==> Downloading Flutter SDK (stable branch)..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "==> Using existing Flutter SDK in $FLUTTER_DIR..."
  git -C "$FLUTTER_DIR" fetch --depth 1 origin stable || true
  git -C "$FLUTTER_DIR" checkout stable || true
fi

# Add Flutter and Dart to PATH
export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

echo "==> Verifying Flutter environment..."
flutter --version

echo "==> Configuring Flutter Web..."
flutter config --no-analytics --enable-web

echo "==> Resolving dependencies..."
flutter pub get

echo "==> Running static analysis check..."
flutter analyze

echo "==> Building Flutter Web release bundle..."
flutter build web --release

echo "==> Verifying build output..."
if [ -f "build/web/index.html" ]; then
  echo "========================================="
  echo "  SUCCESS: build/web generated cleanly!  "
  echo "========================================="
else
  echo "ERROR: build/web/index.html not found!"
  exit 1
fi
