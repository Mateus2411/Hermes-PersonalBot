#!/usr/bin/env python3
"""Health server for Render — keeps the app awake 24/7.

Returns "ok" + uptime on GET / so Google Apps Script (or Render's own
health-check) can ping it.  Zero external dependencies — pure stdlib.

Usage:
    HEALTH_PORT=10000 python3 render-health.py

Then:
    curl http://localhost:10000/
    # → ok | uptime: 0h 5m 23s
    curl http://localhost:10000/?format=json
    # → {"status": "ok", "uptime": "0h 5m 23s", "uptime_seconds": 323}
"""

import http.server
import time
import os
import json
from urllib.parse import urlparse

START_TIME = time.time()
PORT = int(os.environ.get("HEALTH_PORT", "10000"))


class HealthHandler(http.server.BaseHTTPRequestHandler):
    """Minimal handler: GET / → 200 + ok + uptime, GET /health → same."""

    def _uptime_str(self) -> str:
        secs = int(time.time() - START_TIME)
        days, secs = divmod(secs, 86400)
        hours, secs = divmod(secs, 3600)
        minutes, seconds = divmod(secs, 60)
        parts = []
        if days:
            parts.append(f"{days}d")
        parts.append(f"{hours}h {minutes}m {seconds}s")
        return " ".join(parts)

    def _serve(self):
        uptime = self._uptime_str()
        parsed = urlparse(self.path)
        route = parsed.path
        qs = parsed.query

        if route in ("/", "/health"):
            fmt = "json" if "format=json" in qs else "text"
            if fmt == "json":
                body = json.dumps({
                    "status": "ok",
                    "uptime": uptime,
                    "uptime_seconds": int(time.time() - START_TIME),
                })
                ctype = "application/json"
            else:
                body = f"ok | uptime: {uptime}"
                ctype = "text/plain"

            self.send_response(200)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body.encode())))
            self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
            self.end_headers()
            self.wfile.write(body.encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        self._serve()

    def do_HEAD(self):
        self._serve()

    def log_message(self, fmt, *args):
        pass  # Silent


if __name__ == "__main__":
    server = http.server.HTTPServer(("0.0.0.0", PORT), HealthHandler)
    print(f"[health] Listening on :{PORT}", flush=True)
    server.serve_forever()
