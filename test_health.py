#!/usr/bin/env python3
"""Test the health server locally before deploying."""

import subprocess
import time
import urllib.request
import sys
import signal

# Start health server
server = subprocess.Popen(
    [sys.executable, "render-health.py"],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE,
)
time.sleep(2)

try:
    # Test plain text
    resp = urllib.request.urlopen("http://localhost:10000/")
    body = resp.read().decode()
    print(f"GET /       -> {resp.status} {body}")
    assert resp.status == 200
    assert "ok" in body
    assert "uptime" in body

    # Test /health
    resp = urllib.request.urlopen("http://localhost:10000/health")
    body = resp.read().decode()
    print(f"GET /health -> {resp.status} {body}")
    assert resp.status == 200

    # Test JSON
    resp = urllib.request.urlopen("http://localhost:10000/?format=json")
    data = resp.read().decode()
    print(f"GET /?format=json -> {resp.status} {data}")
    assert resp.status == 200
    assert '"status": "ok"' in data

    print("\n✅ Todos os testes passaram!")
finally:
    server.terminate()
    server.wait()
