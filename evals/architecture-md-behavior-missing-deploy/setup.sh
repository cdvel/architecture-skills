#!/usr/bin/env bash
# Fixture: the image-resizing service with no deployment files: no container file,
# no compose file, no manifests, no IaC, and a CI workflow that only checks the code.
set -e

mkdir -p api worker migrations .github/workflows

cat > README.md <<'EOF'
# image-resizer

Accepts image uploads over HTTP and produces thumbnails in the background.

Run locally: `flask --app api.app run` for the API and `python -m worker.worker` for the worker.
EOF

cat > requirements.txt <<'EOF'
flask==3.0.3
psycopg[binary]==3.2.1
redis==5.0.8
pillow==10.4.0
EOF

cat > .env.example <<'EOF'
# Postgres connection string, used by the api and the worker (required)
DATABASE_URL=postgresql://resizer:resizer@localhost:5432/resizer
# Redis instance used as the job queue
REDIS_URL=redis://localhost:6379/0
# Shared bearer token for API clients (required)
API_TOKEN=change-me
UPLOAD_DIR=/data/uploads
OUTPUT_DIR=/data/outputs
EOF

cat > api/__init__.py <<'EOF'
EOF

cat > api/app.py <<'EOF'
"""HTTP API for the image-resizing service.

Accepts uploads, records a job row and queues the job for the worker.
"""
import json
import os
import uuid

import psycopg
import redis
from flask import Flask, abort, jsonify, request

app = Flask(__name__)

DATABASE_URL = os.environ["DATABASE_URL"]
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/data/uploads")
API_TOKEN = os.environ["API_TOKEN"]
MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # must match the proxy's body size limit

queue = redis.Redis.from_url(REDIS_URL)


def require_token():
    # TODO: use hmac.compare_digest so the comparison is constant-time
    if request.headers.get("Authorization") != f"Bearer {API_TOKEN}":
        abort(401)


@app.post("/v1/images")
def create_job():
    require_token()
    upload = request.files.get("image")
    if upload is None:
        abort(400, "missing image field")
    data = upload.read(MAX_UPLOAD_BYTES + 1)
    if len(data) > MAX_UPLOAD_BYTES:
        abort(413)
    job_id = str(uuid.uuid4())
    path = os.path.join(UPLOAD_DIR, f"{job_id}.orig")
    with open(path, "wb") as fh:
        fh.write(data)
    with psycopg.connect(DATABASE_URL) as conn:
        conn.execute(
            "INSERT INTO jobs (id, source_path, status) VALUES (%s, %s, 'queued')",
            (job_id, path),
        )
    queue.lpush("resize:jobs", json.dumps({"job_id": job_id, "path": path}))
    return jsonify({"job_id": job_id, "status": "queued"}), 202


@app.get("/v1/images/<job_id>")
def get_job(job_id):
    require_token()
    with psycopg.connect(DATABASE_URL) as conn:
        row = conn.execute(
            "SELECT status, outputs FROM jobs WHERE id = %s", (job_id,)
        ).fetchone()
    if row is None:
        abort(404)
    return jsonify({"job_id": job_id, "status": row[0], "outputs": row[1]})


@app.get("/healthz")
def healthz():
    return "ok"
EOF

cat > worker/__init__.py <<'EOF'
EOF

cat > worker/worker.py <<'EOF'
"""Background worker: pops resize jobs from Redis and writes thumbnails."""
import json
import os
import time

import psycopg
import redis
from PIL import Image

DATABASE_URL = os.environ["DATABASE_URL"]
REDIS_URL = os.environ.get("REDIS_URL", "redis://localhost:6379/0")
OUTPUT_DIR = os.environ.get("OUTPUT_DIR", "/data/outputs")

SIZES = [(128, 128), (512, 512)]
MAX_ATTEMPTS = 3


def resize(job):
    outputs = []
    with Image.open(job["path"]) as img:
        for width, height in SIZES:
            copy = img.copy()
            copy.thumbnail((width, height))
            out = os.path.join(OUTPUT_DIR, f"{job['job_id']}_{width}x{height}.png")
            copy.save(out, "PNG")
            outputs.append(out)
    return outputs


def main():
    queue = redis.Redis.from_url(REDIS_URL)
    while True:
        _, raw = queue.brpop("resize:jobs")
        job = json.loads(raw)
        attempts = 0
        while True:
            try:
                outputs = resize(job)
                status = "done"
                break
            except OSError:
                attempts += 1
                if attempts >= MAX_ATTEMPTS:
                    outputs, status = [], "failed"
                    break
                # Back off because the shared volume is sometimes slow to show new files.
                time.sleep(2 ** attempts)
        with psycopg.connect(DATABASE_URL) as conn:
            conn.execute(
                "UPDATE jobs SET status = %s, outputs = %s WHERE id = %s",
                (status, json.dumps(outputs), job["job_id"]),
            )


if __name__ == "__main__":
    main()
EOF

cat > migrations/001_create_jobs.sql <<'EOF'
CREATE TABLE jobs (
    id UUID PRIMARY KEY,
    source_path TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('queued', 'done', 'failed')),
    outputs JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX jobs_status_idx ON jobs (status);
EOF

cat > .github/workflows/ci.yml <<'EOF'
name: ci

on:
  push:
    branches: [main]
  pull_request:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - run: python -m compileall api worker

EOF

git init -q -b main
git config user.name "Fixture Author"
git config user.email "fixture@example.com"
git config commit.gpgsign false
git add -A
git commit -q -m "feat: add image resizing api and worker"
