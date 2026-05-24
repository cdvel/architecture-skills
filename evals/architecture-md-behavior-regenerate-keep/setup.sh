#!/usr/bin/env bash
# Fixture: the image-resizing service, an ARCHITECTURE.md generated at the first commit,
# then a later commit that changes the worker.
set -e

mkdir -p api worker migrations .github/workflows

cat > README.md <<'EOF'
# image-resizer

Accepts image uploads over HTTP and produces thumbnails in the background.

Run locally: `flask --app api.app run` for the API and `python -m worker.worker` for the worker.
EOF

cat > requirements.txt <<'EOF'
flask==3.0.3
gunicorn==22.0.0
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

cat > Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY api/ api/
COPY worker/ worker/
COPY migrations/ migrations/
# One image runs both processes; the worker overrides the command.
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "api.app:app"]
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

  image:
    needs: check
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t registry.example.com/image-resizer:${{ github.sha }} .
      - run: echo "${{ secrets.REGISTRY_TOKEN }}" | docker login registry.example.com -u ci --password-stdin
      - run: docker push registry.example.com/image-resizer:${{ github.sha }}
EOF

git init -q -b main
git config user.name "Fixture Author"
git config user.email "fixture@example.com"
git config commit.gpgsign false

# First commit: the code.
git add -A
GIT_AUTHOR_DATE="2026-01-03T10:00:00Z" GIT_COMMITTER_DATE="2026-01-03T10:00:00Z" \
  git commit -q -m "feat: add image resizing api and worker"
FIRST=$(git rev-parse HEAD)
SHORT=$(git rev-parse --short HEAD)

# Second commit: the doc generated at the first commit.
mkdir -p docs
cat > docs/ARCHITECTURE.md <<'EOF'
---
title: image-resizer architecture
generator: architecture-md 0.1.0
generated: 2026-01-03
level: comprehensive
repository: none
commit: __COMMIT__
commit_short: __SHORT__
release_version: none
---

# image-resizer architecture

As of commit __SHORT__ (2026-01-03), level comprehensive.

- [Summary](#summary)
- [Diagrams](#diagrams)
- [Components](#components)
- [Infrastructure and deployment](#infrastructure-and-deployment)
- [CI/CD](#cicd)
- [Data flows](#data-flows)
- [Security](#security)
- [Configuration](#configuration)
- [Observability](#observability)
- [Data stores](#data-stores)
- [Performance](#performance)
- [Technology stack](#technology-stack)
- [Open work](#open-work)
- [Quick reference](#quick-reference)

## Summary

image-resizer accepts image uploads from API clients over HTTP and produces thumbnails in the background, so clients don't wait for resizing. It has two units, an HTTP API and a queue worker, which share one PostgreSQL table and one Redis list.

Core capabilities:

- Accept an upload and return a job ID (`api/app.py:30-49`).
- Report a job's status and output paths (`api/app.py:52-61`).
- Resize queued images into fixed thumbnail sizes (`worker/worker.py:18-27`).

| Decision | Reason | Impact |
|---|---|---|
| Resize in a separate worker fed by a Redis list | Uploads return at once with `202 Accepted` (`api/app.py:49`) | Clients poll `GET /v1/images/<job_id>` for the result |
| One container image for both units | Stated in `Dockerfile:8` | The worker's start command is not defined in the repo |
| One shared bearer token for all clients | Single check in `api/app.py:24-27` | No per-client identity or revocation |

Stack at a glance: Python 3.12, Flask behind gunicorn, PostgreSQL, Redis, Pillow. Details in [Technology stack](#technology-stack).

| Environment | How it is reached or deployed | Source |
|---|---|---|
| Local | `flask --app api.app run` and `python -m worker.worker` | `README.md:5` |
| Image registry | Image pushed on every commit to `main` | `.github/workflows/ci.yml:19-27` |

> **Gap:** No deployment target is defined in the repo.
> **Question:** Where does the pushed image run, and how is the worker started there?

## Diagrams

Level 1, system context:

```
+------------+  HTTPS, bearer token  +---------------+
| API client |---------------------->| image-resizer |
+------------+                       +---------------+
```

Level 2, containers:

```
+------------+  HTTP  +------------+  SQL  +------------+
| API client |------->| api        |------>| PostgreSQL |
+------------+        | api/app.py |       +------------+
                      +------------+             ^
                            | LPUSH              | SQL
                            v                    |
                      +-------------+  BRPOP  +------------------+
                      | Redis list  |<--------| worker           |
                      | resize:jobs |         | worker/worker.py |
                      +-------------+         +------------------+
```

Level 3, components:

```
api/app.py                          worker/worker.py
+-----------------+                 +---------------+
| require_token   |                 | main (loop)   |
| create_job      |                 |   -> resize   |
| get_job         |                 +---------------+
| healthz         |
+-----------------+
```

Level 4, deployment:

> **Gap:** No orchestration or host files exist; only `Dockerfile` and the image push in CI.
> **Question:** What runs the image, and with which volumes for `/data/uploads` and `/data/outputs`?

## Components

### api

- Path: `api/`
- Technology: Python, Flask 3.0.3, served by gunicorn (`Dockerfile:10`)
- Purpose: accepts uploads, records jobs and reports their status.

| Method | Path | Handler | Success |
|---|---|---|---|
| POST | `/v1/images` | `create_job` (`api/app.py:30-49`) | `202` with `job_id` |
| GET | `/v1/images/<job_id>` | `get_job` (`api/app.py:52-61`) | `200` with status and outputs |
| GET | `/healthz` | `healthz` (`api/app.py:64-66`) | `200 ok` |

| File | Role |
|---|---|
| `api/__init__.py` | Marks `api` as a package |
| `api/app.py` | Flask app, token check and the three routes |

> `MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # must match the proxy's body size limit` (`api/app.py:19`). The proxy is not in the repo.

Depends on PostgreSQL, Redis and the upload directory. No tests exist; CI only byte-compiles the code (`.github/workflows/ci.yml:17`).

### worker

- Path: `worker/`
- Technology: Python, Pillow 10.4.0
- Purpose: takes jobs off the Redis list and writes PNG thumbnails.

The worker blocks on `BRPOP resize:jobs` (`worker/worker.py:33`), writes one PNG per entry in `SIZES = [(128, 128), (512, 512)]` (`worker/worker.py:14`), and retries `OSError` up to `MAX_ATTEMPTS = 3` times (`worker/worker.py:15`, `worker/worker.py:41-47`) with a backoff of `2 ** attempts` seconds.

<!-- keep -->
> Team note: keep the worker single-threaded until the image library upgrade lands; parallel resizes exhausted memory on the shared host.
<!-- /keep -->

| File | Role |
|---|---|
| `worker/__init__.py` | Marks `worker` as a package |
| `worker/worker.py` | Queue loop, retries and the resize function |

> `# Back off because the shared volume is sometimes slow to show new files.` (`worker/worker.py:46`)

Depends on Redis, PostgreSQL and the shared volume. No tests exist.

## Infrastructure and deployment

One image built from `Dockerfile:1-10` on `python:3.12-slim`, exposing port 8000 and starting gunicorn with two workers (`Dockerfile:9-10`):

```
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "api.app:app"]
```

*Inferred:* both units need the same volume for `/data/uploads`, because the worker opens the path the API wrote (`api/app.py:40`, `worker/worker.py:20`).

> **Gap:** No compose file, manifests or IaC.
> **Question:** How are the API, the worker, PostgreSQL and Redis deployed and connected?

## CI/CD

`.github/workflows/ci.yml` runs on pushes to `main` and on pull requests (`.github/workflows/ci.yml:3-6`).

| Job | Steps | Source |
|---|---|---|
| `check` | Install requirements, byte-compile `api` and `worker` | `.github/workflows/ci.yml:9-17` |
| `image` | On `main` only: build, log in with `REGISTRY_TOKEN`, push `registry.example.com/image-resizer:<sha>` | `.github/workflows/ci.yml:19-27` |

> **Gap:** No deploy, promotion or rollback steps.
> **Question:** What deploys a pushed image?

## Data flows

### Upload request

```
client             api                       PostgreSQL    Redis
  | POST /v1/images |                            |           |
  |---------------->| check bearer token         |           |
  |                 | write <job_id>.orig        |           |
  |                 | INSERT jobs (queued) ----->|           |
  |                 | LPUSH resize:jobs ------------------->|
  |<----------------| 202 {"job_id", "status"}   |           |
```

```
POST /v1/images HTTP/1.1
Authorization: Bearer <API_TOKEN>
Content-Type: multipart/form-data; boundary=...
```

- Token check: `api/app.py:26`; failure returns `401`.
- A missing `image` field returns `400` (`api/app.py:34-35`); a body over 10 MiB returns `413` (`api/app.py:36-38`).
- Job ID: `str(uuid.uuid4())` (`api/app.py:39`); file path `<UPLOAD_DIR>/<job_id>.orig` (`api/app.py:40`).
- Queue message: `{"job_id": ..., "path": ...}` (`api/app.py:48`).

### Resize job

The worker pops the message (`worker/worker.py:33`), writes `<job_id>_<w>x<h>.png` for each size (`worker/worker.py:24`), retries `OSError` up to three attempts (`worker/worker.py:15`, `worker/worker.py:43`), then sets `status` to `done` or `failed` with the output paths (`worker/worker.py:48-52`).

## Security

- Authentication: one shared bearer token compared with `!=` (`api/app.py:26`).
- Authorization: none beyond the token; any client can read any job ID (`api/app.py:52-61`).
- Secrets: `API_TOKEN` and `DATABASE_URL` come from the environment (`api/app.py:15`, `api/app.py:18`); CI uses `REGISTRY_TOKEN` (`.github/workflows/ci.yml:26`).
- Encryption: *Inferred:* TLS ends at a proxy outside the repo, from the comment at `api/app.py:19`.
- Trust boundaries: client to api; api and worker to PostgreSQL and Redis.

| Threat | Where it applies | Mitigation | Status | Gap |
|---|---|---|---|---|
| Credential theft | Shared `API_TOKEN` | None | not mitigated | One token for all clients; non-constant-time compare (`api/app.py:25`) |
| Traffic interception | Client to api | *Inferred:* TLS at the proxy | partial | Proxy not in the repo |
| Token or request replay | Bearer token | None | not mitigated | The token never expires |
| Confused deputy and privilege escalation | Job lookup | None | not mitigated | Any token holder reads any job (`api/app.py:52-61`) |
| Injection | SQL | Parameterized queries (`api/app.py:44-47`, `worker/worker.py:49-52`) | mitigated | |
| Sensitive data in logs | Logging | No logging configured | not mitigated | See [Observability](#observability) |
| Resource exhaustion | Uploads | 10 MiB cap (`api/app.py:36-38`) | partial | No disk quota |
| Abuse without rate limits | Public routes | None | not mitigated | No rate limiting |
| Dependency supply chain | `requirements.txt` | Pinned versions (`requirements.txt:1-5`) | partial | No hashes |

## Configuration

| Variable | Purpose | Required | Default | Read at |
|---|---|---|---|---|
| `DATABASE_URL` | PostgreSQL connection | Yes | none | `api/app.py:15`, `worker/worker.py:10` |
| `REDIS_URL` | Job queue | No | `redis://localhost:6379/0` | `api/app.py:16`, `worker/worker.py:11` |
| `API_TOKEN` | Shared bearer token | Yes | none | `api/app.py:18` |
| `UPLOAD_DIR` | Where uploads are written | No | `/data/uploads` | `api/app.py:17` |
| `OUTPUT_DIR` | Where thumbnails are written | No | `/data/outputs` | `worker/worker.py:12` |

All five appear in `.env.example:1-8`. No feature flags or per-environment config.

## Observability

Only `GET /healthz` (`api/app.py:64-66`). No metrics, logging configuration, error tracking or tracing.

> **Gap:** No observability beyond the health check.
> **Question:** How are failed jobs noticed?

## Data stores

### PostgreSQL

`migrations/001_create_jobs.sql:1-9`:

```sql
CREATE TABLE jobs (
    id UUID PRIMARY KEY,
    source_path TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('queued', 'done', 'failed')),
    outputs JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX jobs_status_idx ON jobs (status);
```

> **Gap:** No migration runner; the file is copied into the image (`Dockerfile:7`) but nothing applies it.
> **Question:** How and when is the schema applied?

### Redis

One list, `resize:jobs`: `LPUSH` by the api (`api/app.py:48`), `BRPOP` by the worker (`worker/worker.py:33`). No persistence settings in the repo.

### Shared volume

Uploads and thumbnails live on disk under `UPLOAD_DIR` and `OUTPUT_DIR`. No retention or cleanup.

## Performance

gunicorn runs two workers (`Dockerfile:10`). Uploads are read into memory up to 10 MiB (`api/app.py:36`). No caching, stated targets or load tests.

## Technology stack

| Component | Version | Role | Pinned at |
|---|---|---|---|
| Python | 3.12 | Runtime | `Dockerfile:1`, `.github/workflows/ci.yml:15` |
| Flask | 3.0.3 | HTTP framework | `requirements.txt:1` |
| gunicorn | 22.0.0 | WSGI server | `requirements.txt:2` |
| psycopg | 3.2.1 | PostgreSQL client | `requirements.txt:3` |
| redis | 5.0.8 | Redis client | `requirements.txt:4` |
| Pillow | 10.4.0 | Image resizing | `requirements.txt:5` |

## Open work

| Marker | Where | Note |
|---|---|---|
| TODO | `api/app.py:25` | Constant-time token comparison |

## Quick reference

| What | Where |
|---|---|
| API entry point | `api/app.py:13` |
| Worker entry point | `worker/worker.py:55-56` |
| Configuration | `.env.example` |
| Schema | `migrations/001_create_jobs.sql` |
| Image build | `Dockerfile` |

Commands: `flask --app api.app run` and `python -m worker.worker` (`README.md:5`).
EOF

sed -i -e "s/__COMMIT__/$FIRST/" -e "s/__SHORT__/$SHORT/g" docs/ARCHITECTURE.md
git add docs/ARCHITECTURE.md
GIT_AUTHOR_DATE="2026-01-03T11:00:00Z" GIT_COMMITTER_DATE="2026-01-03T11:00:00Z" \
  git commit -q -m "docs: add architecture doc"

# Third commit: the worker changes in place (same line numbers).
sed -i -e 's/^SIZES = \[(128, 128), (512, 512)\]$/SIZES = [(128, 128), (512, 512), (1024, 1024)]/' \
       -e 's/^MAX_ATTEMPTS = 3$/MAX_ATTEMPTS = 5/' worker/worker.py
git add worker/worker.py
GIT_AUTHOR_DATE="2026-01-22T09:00:00Z" GIT_COMMITTER_DATE="2026-01-22T09:00:00Z" \
  git commit -q -m "feat: add 1024px thumbnails and retry up to five times"
