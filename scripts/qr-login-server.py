#!/usr/bin/env python3
from __future__ import annotations

import argparse
import http.server
import json
import socketserver
import threading
import time
from pathlib import Path
from urllib.request import urlopen


HTML = """<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>QCE Login</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #0f172a;
      color: #e2e8f0;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
    }
    .card {
      width: min(92vw, 520px);
      background: rgba(15, 23, 42, 0.92);
      border: 1px solid rgba(148, 163, 184, 0.25);
      border-radius: 24px;
      padding: 28px;
      box-shadow: 0 24px 80px rgba(2, 6, 23, 0.45);
      text-align: center;
    }
    h1 {
      margin: 0 0 12px;
      font-size: 28px;
    }
    p {
      margin: 0 0 16px;
      color: #cbd5e1;
      line-height: 1.5;
    }
    .qr-shell {
      margin: 18px auto 18px;
      width: min(70vw, 320px);
      height: min(70vw, 320px);
      border-radius: 20px;
      background: white;
      display: flex;
      align-items: center;
      justify-content: center;
      overflow: hidden;
    }
    img {
      width: 100%;
      height: 100%;
      object-fit: contain;
      image-rendering: pixelated;
    }
    .hint {
      font-size: 14px;
      color: #94a3b8;
    }
    .state {
      margin-top: 10px;
      font-size: 15px;
      color: #67e8f9;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>QCE 登录二维码</h1>
    <p>请使用手机 QQ 扫描下面的二维码完成登录。登录成功后会自动跳转到 QCE 页面。</p>
    <div class="qr-shell">
      <img id="qr" src="/qr.png?t=0" alt="QCE QR code">
    </div>
    <div class="state" id="state">正在等待二维码…</div>
    <div class="hint">如果二维码失效，本页会自动刷新最新二维码。</div>
  </div>
  <script>
    const qr = document.getElementById('qr');
    const state = document.getElementById('state');

    async function poll() {
      try {
        const res = await fetch('/status?t=' + Date.now(), { cache: 'no-store' });
        const data = await res.json();
        if (data.ready && data.authUrl) {
          state.textContent = '登录成功，正在跳转…';
          window.location.href = data.authUrl;
          return;
        }
        if (data.qrExists) {
          qr.src = '/qr.png?t=' + Date.now();
          state.textContent = '请扫码登录';
        } else {
          state.textContent = '正在生成二维码…';
        }
      } catch (e) {
        state.textContent = '正在等待本地服务…';
      }
      setTimeout(poll, 1000);
    }

    poll();
  </script>
</body>
</html>
"""


class QrHandler(http.server.BaseHTTPRequestHandler):
    qr_path: Path
    qce_base: str
    security_json: Path

    def log_message(self, format: str, *args) -> None:  # noqa: A003
        return

    def do_GET(self) -> None:  # noqa: N802
        if self.path.startswith("/qr.png"):
            self._serve_qr()
            return
        if self.path.startswith("/status"):
            self._serve_status()
            return
        if self.path.startswith("/login") or self.path == "/":
            self._serve_html()
            return
        self.send_error(404)

    def _serve_html(self) -> None:
        payload = HTML.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def _serve_qr(self) -> None:
        if not self.qr_path.exists():
            self.send_error(404)
            return
        payload = self.qr_path.read_bytes()
        self.send_response(200)
        self.send_header("Content-Type", "image/png")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(payload)

    def _serve_status(self) -> None:
        ready = False
        auth_url = None
        try:
            with urlopen(self.qce_base, timeout=1.5) as resp:
                ready = resp.status == 200
        except Exception:
            ready = False

        if ready and self.security_json.exists():
            try:
                token = json.loads(self.security_json.read_text(encoding="utf-8")).get("accessToken", "").strip()
                if token:
                    auth_url = f"{self.qce_base}auth?token={token}"
            except Exception:
                auth_url = self.qce_base

        payload = json.dumps(
            {
                "ready": ready,
                "qrExists": self.qr_path.exists(),
                "authUrl": auth_url,
            }
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=40654)
    parser.add_argument("--qr-path", required=True)
    parser.add_argument("--qce-base", default="http://127.0.0.1:40653/qce-v4-tool/")
    parser.add_argument("--security-json", required=True)
    args = parser.parse_args()

    class Handler(QrHandler):
        qr_path = Path(args.qr_path)
        qce_base = args.qce_base
        security_json = Path(args.security_json)

    with socketserver.TCPServer((args.host, args.port), Handler) as httpd:
        httpd.allow_reuse_address = True
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
