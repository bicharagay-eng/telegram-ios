#!/usr/bin/bash
# Xcode 26: Metal is a separate MobileAsset. Host `xcrun metal` is a stub on some runners.
# Bazel uses iphoneos SDK. On macos-26 arm64 images Metal is usually preinstalled — do not fail CI on a flaky pre-check.
set -euo pipefail

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "DEVELOPER_DIR=$(xcode-select -p)" >> "$GITHUB_ENV"
fi

metal_ios_ok() {
  xcrun -sdk iphoneos metal --version >/dev/null 2>&1
}

if metal_ios_ok; then
  echo "Metal toolchain OK (iphoneos): $(xcrun -sdk iphoneos metal --version 2>&1 | head -1)"
  exit 0
fi

echo "Metal pre-check failed; attempting MetalToolchain download..."
sudo xcodebuild -downloadComponent MetalToolchain || true

latest="$(ls -d /Applications/Xcode_26*.app 2>/dev/null | sort -V | tail -n 1 || true)"
if [[ -n "${latest}" && -d "${latest}/Contents/Developer" ]]; then
  sudo xcode-select -s "${latest}/Contents/Developer"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "DEVELOPER_DIR=$(xcode-select -p)" >> "$GITHUB_ENV"
  fi
  sudo xcodebuild -downloadComponent MetalToolchain || true
fi

if metal_ios_ok; then
  echo "Metal toolchain ready: $(xcrun -sdk iphoneos metal --version 2>&1 | head -1)"
  exit 0
fi

if [[ "$(uname -m)" == "arm64" ]]; then
  echo "::warning::iphoneos metal pre-check failed on arm64; continuing (GitHub macos-26 image usually still compiles .metal in Bazel)"
  exit 0
fi

echo "::error::Metal toolchain unavailable for iphoneos on Intel runner"
xcodebuild -version || true
xcrun -sdk iphoneos metal --version || true
exit 1
