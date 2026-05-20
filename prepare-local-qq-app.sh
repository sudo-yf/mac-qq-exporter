#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_APP="${QCE_SOURCE_QQ_APP:-/Applications/QQ.app}"
LOCAL_APP="${QCE_LOCAL_QQ_APP:-$HOME/Applications/QQ Chat Exporter/QQ-QCE-runtime.app}"
LOCAL_BIN="$LOCAL_APP/Contents/MacOS/QQ"
APP_RES="$LOCAL_APP/Contents/Resources/app"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.qq-chat-exporter}"
MARKER="$STATE_DIR/local-qq-bundle.ready"

if [ ! -d "$SOURCE_APP" ]; then
  echo "[Error] QQ source app not found: $SOURCE_APP" >&2
  exit 1
fi

repair_bundle() {
  if [ ! -d "$LOCAL_APP" ]; then
    return
  fi

  rm -f "$LOCAL_APP/.qce-local-bundle-ready" >/dev/null 2>&1 || true
  xattr -cr "$LOCAL_APP" >/dev/null 2>&1 || true
  if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "$LOCAL_APP" >/dev/null 2>&1 || true
    codesign --verify --deep --strict "$LOCAL_APP" >/dev/null 2>&1 || true
  fi
  xattr -cr "$LOCAL_APP" >/dev/null 2>&1 || true
}

bundle_is_healthy() {
  [ -x "$LOCAL_BIN" ] && [ -f "$MARKER" ]
}

needs_build=0
if [ ! -x "$LOCAL_BIN" ]; then
  needs_build=1
elif [ -L "$LOCAL_BIN" ]; then
  needs_build=1
elif [ ! -f "$MARKER" ]; then
  needs_build=1
elif ! bundle_is_healthy; then
  needs_build=1
elif [ ! -d "$APP_RES/node_modules" ]; then
  needs_build=1
elif [ ! -d "$APP_RES/plugins/qq-chat-exporter" ]; then
  needs_build=1
elif [ ! -d "$APP_RES/static/qce-v4-tool" ]; then
  needs_build=1
elif [ ! -f "$APP_RES/loadNapCat.js" ] || [ ! -f "$APP_RES/napcat.mjs" ] || [ ! -f "$APP_RES/qqnt.json" ]; then
  needs_build=1
fi

if [ "$needs_build" -eq 1 ]; then
  TMP_APP="$LOCAL_APP.tmp"
  mkdir -p "$(dirname "$LOCAL_APP")"
  rm -rf "$TMP_APP"
  ditto "$SOURCE_APP" "$TMP_APP"
  rm -rf "$LOCAL_APP"
  mv "$TMP_APP" "$LOCAL_APP"

  mkdir -p "$APP_RES"

  cp "$SCRIPT_DIR/loadNapCat.js" "$APP_RES/loadNapCat.js"
  cp "$SCRIPT_DIR/napcat.mjs" "$APP_RES/napcat.mjs"
  cp "$SCRIPT_DIR/napcat-bootstrap.mjs" "$APP_RES/napcat-bootstrap.mjs"
  cp "$SCRIPT_DIR/qqnt.json" "$APP_RES/qqnt.json"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$SCRIPT_DIR/config/" "$APP_RES/config/"
    rsync -a --delete "$SCRIPT_DIR/plugins/" "$APP_RES/plugins/"
    rsync -a --delete "$SCRIPT_DIR/static/" "$APP_RES/static/"
    if [ -d "$SCRIPT_DIR/native" ]; then
      rsync -a --delete "$SCRIPT_DIR/native/" "$APP_RES/native/"
    fi
    if [ -d "$SCRIPT_DIR/worker" ]; then
      rsync -a --delete "$SCRIPT_DIR/worker/" "$APP_RES/worker/"
    fi
    rsync -a --delete "$SCRIPT_DIR/node_modules/" "$APP_RES/node_modules/"
  else
    rm -rf "$APP_RES/config" "$APP_RES/plugins" "$APP_RES/static" "$APP_RES/native" "$APP_RES/worker" "$APP_RES/node_modules"
    cp -R "$SCRIPT_DIR/config" "$APP_RES/config"
    cp -R "$SCRIPT_DIR/plugins" "$APP_RES/plugins"
    cp -R "$SCRIPT_DIR/static" "$APP_RES/static"
    [ -d "$SCRIPT_DIR/native" ] && cp -R "$SCRIPT_DIR/native" "$APP_RES/native"
    [ -d "$SCRIPT_DIR/worker" ] && cp -R "$SCRIPT_DIR/worker" "$APP_RES/worker"
    cp -R "$SCRIPT_DIR/node_modules" "$APP_RES/node_modules"
  fi

  find "$SCRIPT_DIR" -maxdepth 1 -type f -name 'conout-*.js' -exec cp {} "$APP_RES/" \;

  python3 - "$APP_RES/package.json" <<'PY2'
import json
import sys
from pathlib import Path

pkg = Path(sys.argv[1])
payload = json.loads(pkg.read_text(encoding='utf-8'))
payload['main'] = './loadNapCat.js'
pkg.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
PY2

  mkdir -p "$STATE_DIR"
  touch "$MARKER"
  repair_bundle
else
  repair_bundle
fi

printf '%s\n' "$LOCAL_BIN"
