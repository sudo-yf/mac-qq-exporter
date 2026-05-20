#!/bin/bash
set -euo pipefail

REPO_OWNER="${QCE_REPO_OWNER:-sudo-yf}"
REPO_NAME="${QCE_REPO_NAME:-mac-qq-exporter}"
REPO_BRANCH="${QCE_REPO_BRANCH:-main}"
INSTALL_BASE="${QCE_INSTALL_BASE:-$HOME/Applications/QQ Chat Exporter}"
INSTALL_DIR="$INSTALL_BASE/NapCat-QCE-macOS-arm64"
BIN_DIR="${QCE_BIN_DIR:-$HOME/.local/bin}"
APP_LINK_DIR="${QCE_APP_LINK_DIR:-$HOME/Applications}"
TMP_DIR="$(mktemp -d)"
ARCHIVE="$TMP_DIR/repo.tar.gz"
ARCHIVE_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/tarball/${REPO_BRANCH}"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This installer only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "Warning: this package is only validated on Apple Silicon (arm64)." >&2
fi

AUTH_HEADER=()
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [ -z "$TOKEN" ] && command -v gh >/dev/null 2>&1; then
  TOKEN="$(gh auth token 2>/dev/null || true)"
fi
if [ -n "$TOKEN" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer $TOKEN")
fi

echo "Downloading ${REPO_OWNER}/${REPO_NAME}@${REPO_BRANCH} ..."
curl -fsSL "${AUTH_HEADER[@]}" -H "Accept: application/vnd.github+json" "$ARCHIVE_URL" -o "$ARCHIVE"

mkdir -p "$TMP_DIR/src"
tar -xzf "$ARCHIVE" -C "$TMP_DIR/src"
SRC_DIR="$(find "$TMP_DIR/src" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

mkdir -p "$INSTALL_DIR"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.DS_Store' \
  --exclude 'guild1.db' \
  --exclude 'guild1.db-shm' \
  --exclude 'guild1.db-wal' \
  --exclude 'cache/' \
  --exclude 'logs/' \
  --exclude '.qce-app-launch.sh' \
  "$SRC_DIR/" "$INSTALL_DIR/"

chmod +x \
  "$INSTALL_DIR/qce" \
  "$INSTALL_DIR/launcher-user.sh" \
  "$INSTALL_DIR/start-standalone.sh" \
  "$INSTALL_DIR/prepare-local-qq-app.sh" \
  "$INSTALL_DIR/QCE Launcher.app/Contents/MacOS/qce-launcher"

xattr -r -d com.apple.quarantine "$INSTALL_DIR" >/dev/null 2>&1 || true

mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/qce" "$BIN_DIR/qce"

mkdir -p "$APP_LINK_DIR"
ln -sfn "$INSTALL_DIR/QCE Launcher.app" "$APP_LINK_DIR/QCE Launcher.app"

echo
echo "Installed to: $INSTALL_DIR"
echo "CLI link: $BIN_DIR/qce"
echo "App link: $APP_LINK_DIR/QCE Launcher.app"
echo
echo "Next steps:"
echo "  1. Ensure QQ.app is installed in /Applications/QQ.app"
echo "  2. Run: qce start"
echo "  3. Or double-click: $APP_LINK_DIR/QCE Launcher.app"
echo
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  echo "Note: $BIN_DIR is not currently in PATH."
  echo "Add this to your shell profile if you want to run 'qce' directly:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
  echo
fi
