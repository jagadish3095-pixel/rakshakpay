"""Shared test setup: a fresh temporary database for the test run."""
import os
import tempfile

os.environ["RAKSHAK_DB"] = os.path.join(tempfile.mkdtemp(), "test.db")
os.environ.pop("DATABASE_URL", None)
os.environ.pop("ADMIN_KEY", None)

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

from app.main import app  # noqa: E402


@pytest.fixture()
def client():
    with TestClient(app) as c:
        c.post("/api/demo/reset")
        yield c
