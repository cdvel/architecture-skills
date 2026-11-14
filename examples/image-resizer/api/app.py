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
