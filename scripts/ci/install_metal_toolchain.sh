#!/usr/bin/bash
# Xcode 26+: Metal ships as a separate MobileAsset. Host `xcrun metal` is often a stub
# that fails even after download; iPhoneOS SDK is what Bazel MetalCompile uses.
set -euo pipefail

metal_ios_ok() {
  xcrun -sdk iphoneos metal --version >/dev/null 2>&1
}

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "DEVELOPER_DIR=$(xcode-select -p)" >> "$GITHUB_ENV"
fi

if metal_ios_ok; then
  echo "Metal toolchain OK (iphoneos): $(xcrun -sdk iphoneos metal --version 2>&1 | head -1)"
  exit 0
fi

echo "Metal toolchain missing for iphoneos; downloading component..."
sudo xcodebuild -downloadComponent MetalToolchain

if ! metal_ios_ok; then
  echo "Retry after selecting newest Xcode 26..."
  latest="$(ls -d /Applications/Xcode_26*.app 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -n "${latest}" && -d "${latest}/Contents/Developer" ]]; then
    sudo xcode-select -s "${latest}/Contents/Developer"
    if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "DEVELOPER_DIR=$(xcode-select -p)" >> "$GITHUB_ENV"
fi
    sudo xcodebuild -downloadComponent MetalToolchain
  fi
fi

if ! metal_ios_ok; then
  echo "::error::Metal toolchain still unavailable for iphoneos"
  xcodebuild -version || true
  xcrun -sdk iphoneos metal --version || true
  xcrun metal --version || true
  exit 1
fi

echo "Metal toolchain ready: $(xcrun -sdk iphoneos metal --version 2>&1 | head -1)"
