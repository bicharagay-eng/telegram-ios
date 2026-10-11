#!/bin/bash
# Empty submodule dirs in the repo — pull trees from upstream Telegram-iOS before Bazel build.
set -euo pipefail

ROOT="${1:-.}"
UPSTREAM_REF="${2:-master}"
UPSTREAM_URL="${3:-https://github.com/TelegramMessenger/Telegram-iOS.git}"
WORK_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

echo "Fetching external submodules from ${UPSTREAM_URL} (${UPSTREAM_REF})"
git clone --filter=blob:none --no-checkout "$UPSTREAM_URL" "$WORK_DIR/upstream"
git -C "$WORK_DIR/upstream" checkout "$UPSTREAM_REF"
git -C "$WORK_DIR/upstream" submodule sync --recursive
git -C "$WORK_DIR/upstream" submodule update --init --recursive --jobs 4

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if [[ ! -d "$ROOT/$path" ]] || [[ -z "$(ls -A "$ROOT/$path" 2>/dev/null || true)" ]]; then
    echo "Installing submodule content: $path"
    mkdir -p "$(dirname "$ROOT/$path")"
    rm -rf "$ROOT/$path"
    cp -R "$WORK_DIR/upstream/$path" "$ROOT/$path"
  else
    echo "Keeping existing content: $path"
  fi
done <<'PATHS'
submodules/rlottie/rlottie
build-system/bazel-rules/rules_apple
build-system/bazel-rules/rules_swift
build-system/bazel-rules/apple_support
submodules/TgVoipWebrtc/tgcalls
third-party/libvpx/libvpx
third-party/webrtc/webrtc
build-system/bazel-rules/rules_xcodeproj
third-party/dav1d/dav1d
third-party/td/td
third-party/wallet-engine/wallet-engine
submodules/tlottie/tlottie
third-party/mtproto-engine
PATHS

echo "External submodules ready."
