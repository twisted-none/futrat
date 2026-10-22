import os
import json
from pathlib import Path
import socket
import subprocess
import sys
import time
from urllib.error import URLError
from urllib.request import urlopen

import pytest


def test_existing_postgresql_url_keeps_psycopg2_driver(tmp_path):
    environment = {
        **os.environ,
        "DATABASE_URL": "postgresql://test:test@localhost/futrat_upgrade_test",
        "PYTHONPATH": str(Path(__file__).resolve().parents[1]),
    }
    result = subprocess.run(
        [sys.executable, "-B", "-c", "from app.database import engine; print(engine.dialect.driver)"],
        cwd=tmp_path, env=environment, capture_output=True, text=True,
    )
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "psycopg2"


def test_uvicorn_serves_http(db, tmp_path):
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    environment = {**os.environ, "PYTHONPATH": str(Path(__file__).resolve().parents[1])}
    code = (
        "from app import main; import uvicorn; "
        "main.init_db = lambda: None; "
        "main.update_all_data = lambda: None; "
        "main.update_live_data = lambda: None; "
        f"uvicorn.run(main.app, host='127.0.0.1', port={port}, log_level='error')"
    )
    process = subprocess.Popen(
        [sys.executable, "-B", "-c", code], cwd=tmp_path, env=environment,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
    )
    try:
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            if process.poll() is not None:
                stdout, stderr = process.communicate()
                pytest.fail(f"Uvicorn exited before serving HTTP: {stdout}\n{stderr}")
            try:
                with urlopen(f"http://127.0.0.1:{port}/", timeout=1) as response:
                    assert response.status == 200
                    assert json.load(response) == {"message": "Futrat LIVE API Running"}
                    return
            except URLError:
                time.sleep(0.1)
        pytest.fail("Uvicorn did not start within 15 seconds")
    finally:
        process.terminate()
        try:
            process.communicate(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.communicate()
