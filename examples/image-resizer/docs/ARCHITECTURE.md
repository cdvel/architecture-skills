---
title: image-resizer architecture
generator: architecture-md 0.1.0
generated: 2026-11-14
level: comprehensive
repository: none
commit: c996f9c45d6b3a7972e0b881072e644d407d3b6b
commit_short: c996f9c
release_version: none
---

# image-resizer architecture

As of commit c996f9c (2026-11-14), level comprehensive.

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

Sections left out because the repo has nothing for them: Cloud services (no cloud SDK, provider
config or cloud credentials; the container registry is covered in [CI/CD](#cicd)), External
integrations (the code calls no third-party API at runtime), Cross-repo dependencies (one
repository, no shared libraries, no clients for other services), Related documents (no glossary
and no ADR register).

## Summary

image-resizer accepts image uploads over HTTP and produces thumbnails in the background
(README.md:3). A client posts an image to the `api` process, which writes the file to disk,
records a job row in PostgreSQL and queues the job on a Redis list (api/app.py:1-4). The `worker`
process pops the job, writes PNG thumbnails and updates the row (worker/worker.py:1). The client
polls the API for the result.

Callers are API clients that share one bearer token (api/app.py:18, api/app.py:24-27).
*Inferred:* the callers are other services or internal tools rather than end users; rests on the
single shared token, no user accounts and no UI in the repo.

### Core capabilities

- Upload an image of up to 10 MiB and get a job id back (`POST /v1/images`, api/app.py:30-49).
- Resize each upload into two PNG thumbnails bounded by 128x128 and 512x512 pixels
  (worker/worker.py:14, worker/worker.py:18-27).
- Report a job's status and output file paths (`GET /v1/images/<job_id>`, api/app.py:52-61).
- Answer an unauthenticated liveness probe (`GET /healthz`, api/app.py:64-66).

### Key decisions

The repo has no ADR register. Reasons come from code comments where one exists; otherwise they
are marked as not stated.

| Decision | Reason | Impact |
|---|---|---|
| One container image runs both the API and the worker (Dockerfile:8) | "One image runs both processes; the worker overrides the command." (Dockerfile:8); why one image is preferred is not stated | Both processes ship from the same tag; the worker's command lives in deployment config that is not in the repo |
| Redis list `resize:jobs` as the job queue: `LPUSH` to enqueue, `BRPOP` to consume (api/app.py:48, worker/worker.py:33) | Not stated | FIFO order; *Inferred:* a job popped by a worker that then crashes is lost (see [Data flows](#data-flows)) |
| Image bytes pass through a shared filesystem, not through the queue or the database (api/app.py:40-42, worker/worker.py:20, worker/worker.py:24) | Not stated | API and worker must see the same files at the same path; the worker retries "because the shared volume is sometimes slow to show new files" (worker/worker.py:46) |
| One shared bearer token for all clients (api/app.py:18, api/app.py:24-27) | Not stated | No per-client identity; any token holder can read any job (see [Security](#security)) |
| PostgreSQL table `jobs` holds job state; clients poll it through the API (migrations/001_create_jobs.sql:1-7, api/app.py:52-61) | Not stated | No callback or push; three states only: `queued`, `done`, `failed` (migrations/001_create_jobs.sql:4) |
| 10 MiB upload limit in the app, kept equal to a proxy limit (api/app.py:19) | "must match the proxy's body size limit" (api/app.py:19) | The limit is set in two places, one of them outside the repo |
| Images tagged with the commit SHA (.github/workflows/ci.yml:25-27) | Not stated | Each commit on `main` maps to one image tag |

### Stack at a glance

Python 3.12, Flask 3.0.3 served by gunicorn 22.0.0, psycopg 3.2.1 for PostgreSQL, redis-py 5.0.8
for Redis, Pillow 10.4.0 for image processing. One Docker image, built and pushed by GitHub
Actions. Pins and sources are in [Technology stack](#technology-stack).

### Environments

| Name | How it is reached or deployed | Source |
|---|---|---|
| Local | `flask --app api.app run` for the API and `python -m worker.worker` for the worker; the sample values point at PostgreSQL on `localhost:5432` and Redis on `localhost:6379` | README.md:5, .env.example:1-8 |
| CI | GitHub Actions on `ubuntu-latest`, on pushes to `main` and on pull requests | .github/workflows/ci.yml:3-10 |
| Image registry | `registry.example.com/image-resizer:<commit SHA>`, pushed from `main` only | .github/workflows/ci.yml:19-27 |

> **Gap:** no staging or production environment is defined in the repo, and nothing shows where
> the image runs.
> **Question:** which environments run the image, and what deploys it there?

## Diagrams

### System context (C4 level 1)

```
+-----------------------------+
| API client                  |
| holds the shared API_TOKEN  |
+-----------------------------+
              |
              | HTTP, Authorization: Bearer <API_TOKEN>
              v
+-----------------------------+
| reverse proxy               |
| not in repo; Inferred from  |
| api/app.py:19               |
+-----------------------------+
              |
              | HTTP :8000
              v
+---------------------------------------------+
| image-resizer (this repo)                   |
| api/app.py, worker/worker.py                |
| with PostgreSQL, Redis, shared file volume  |
+---------------------------------------------+

+-----------------------------+  docker login, docker push  +-------------------------------+
| GitHub Actions              |---------------------------->| container registry            |
| .github/workflows/ci.yml    |                             | registry.example.com          |
+-----------------------------+                             +-------------------------------+
```

The proxy appears only in the comment at api/app.py:19. PostgreSQL and Redis are drawn inside the
system because the repo owns their schema and queue key; where they are hosted is not in the repo.

### Containers (C4 level 2)

```
                    +------------+  HTTP  +---------------+
                    | API client |------->| proxy         |
                    +------------+        | (not in repo) |
                                          +---------------+
                                                  |
                                                  | HTTP :8000
                                                  v
                                    +------------------------------------------------+
                                    | api: gunicorn + Flask, api/app.py              |
                                    +------------------------------------------------+
                                        |                  |                     |
                            SQL INSERT, |  LPUSH, RESP     |  file write         |
                            SELECT      |                  |  <job_id>.orig      |
                                        v                  v                     v
                                +--------------+  +-----------------+  +--------------------+
                                | PostgreSQL   |  | Redis           |  | shared volume      |
                                | table jobs   |  | list            |  | UPLOAD_DIR         |
                                |              |  | resize:jobs     |  | OUTPUT_DIR         |
                                +--------------+  +-----------------+  +--------------------+
                                        ^                  |                     ^
                            SQL UPDATE  |  BRPOP, RESP     |  PNG write,         |
                                        |                  v  .orig read         |
                                    +------------------------------------------------+
                                    | worker: worker/worker.py                       |
                                    +------------------------------------------------+
```

SQL calls go through psycopg (api/app.py:43-47, api/app.py:55-58, worker/worker.py:48-52). The
Redis calls are at api/app.py:48 and worker/worker.py:33. RESP is the Redis wire protocol.

### Components (C4 level 3)

```
api/app.py (api container)
+------------------------------------------------------------------------+
| setup, lines 13-21: Flask app, env config, MAX_UPLOAD_BYTES, Redis     |
|                                                                        |
| POST /v1/images          -> create_job 30-49 -> require_token 24-27    |
|                                              -> write UPLOAD_DIR file  |
|                                              -> INSERT jobs            |
|                                              -> LPUSH resize:jobs      |
| GET /v1/images/<job_id>  -> get_job 52-61    -> require_token 24-27    |
|                                              -> SELECT jobs            |
| GET /healthz             -> healthz 64-66       no token check         |
+------------------------------------------------------------------------+

worker/worker.py (worker container)
+------------------------------------------------------------------------+
| setup, lines 10-15: env config, SIZES, MAX_ATTEMPTS                    |
|                                                                        |
| main 30-52  -> BRPOP resize:jobs, json.loads          lines 33-34      |
|             -> retry loop, OSError only, 3 attempts   lines 35-47      |
|                  -> resize 18-27: Image.open, thumbnail, save PNG      |
|             -> UPDATE jobs status, outputs            lines 48-52      |
+------------------------------------------------------------------------+
```

### Deployment (C4 level 4)

```
+-----------------------------+  docker build, docker push  +-------------------------------+
| GitHub Actions runner       |---------------------------->| registry.example.com          |
| ubuntu-latest, ci.yml:19-27 |                             | image-resizer:<github.sha>    |
+-----------------------------+                             +-------------------------------+
                                                                            |
                                                                            | pull (not in repo)
                                                                            v
+------------------------------------------------------------------------------------------+
| runtime host or orchestrator: not in repo                                                |
|                                                                                          |
|  +------------------------------------+    +------------------------------------+        |
|  | container: api                     |    | container: worker                  |        |
|  | python:3.12-slim, WORKDIR /app     |    | same image                         |        |
|  | gunicorn 0.0.0.0:8000, 2 workers   |    | command overridden (Dockerfile:8)  |        |
|  +------------------------------------+    +------------------------------------+        |
|                   |                                          |                           |
|                   +------------ shared volume ---------------+                           |
|                     Inferred from worker/worker.py:46                                    |
+------------------------------------------------------------------------------------------+
        PostgreSQL :5432 and Redis :6379 (sample ports, .env.example:2, .env.example:4)
```

In the diagram, `ci.yml` is `.github/workflows/ci.yml`.

> **Gap:** the runtime (hosts, orchestrator, volume type, network, PostgreSQL and Redis hosting)
> is not in the repo. The diagram shows only what the Dockerfile and CI define.
> **Question:** where do the two containers run, how is the shared volume provided, and where do
> PostgreSQL and Redis run?

## Components

The repo has three units. Every tracked file was read; no file is uncovered.

| Unit | Root path | Language | Source files | Lines | Entry points |
|---|---|---|---|---|---|
| api | `api/` | Python | 2 | 66 | Flask object `app` (api/app.py:13), served by gunicorn as `api.app:app` (Dockerfile:10) |
| worker | `worker/` | Python | 2 | 56 | `main()` (worker/worker.py:30, worker/worker.py:55-56), run as `python -m worker.worker` (README.md:5) |
| migrations | `migrations/` | SQL | 1 | 9 | None; nothing in the repo applies it |

The Dockerfile, the CI workflow, `.env.example` and the README are covered in
[Infrastructure and deployment](#infrastructure-and-deployment), [CI/CD](#cicd) and
[Configuration](#configuration).

### api

- **Path:** `api/`
- **Technology:** Python 3.12, Flask 3.0.3, gunicorn 22.0.0, psycopg 3.2.1, redis-py 5.0.8
- **Purpose:** accepts uploads, records a job row and queues the job for the worker
  (api/app.py:1-4).

#### Structure

One module, `api/app.py`. At import it creates the Flask app (line 13), reads four environment
variables (lines 15-18), sets the upload limit (line 19) and creates a Redis client named `queue`
(line 21). There is no application factory, blueprint, error handler or middleware. Each job
handler calls `require_token()` itself (lines 32 and 54) and opens its own PostgreSQL connection
(lines 43 and 55).

`DATABASE_URL` and `API_TOKEN` are read with `os.environ[...]` (api/app.py:15, api/app.py:18), so
importing the module raises `KeyError` when either is unset.

#### Public interface

| Method | Path | Auth | Request | Success | Errors | Source |
|---|---|---|---|---|---|---|
| POST | `/v1/images` | `Authorization: Bearer <API_TOKEN>` | `multipart/form-data`, file field `image`, at most 10 MiB | `202`, `{"job_id": "<uuid4>", "status": "queued"}` | `401`; `400` "missing image field"; `413` | api/app.py:30-49 |
| GET | `/v1/images/<job_id>` | `Authorization: Bearer <API_TOKEN>` | Job id in the path | `200`, `{"job_id", "status", "outputs"}` | `401`; `404` | api/app.py:52-61 |
| GET | `/healthz` | None | None | `200`, body `ok` | None | api/app.py:64-66 |

#### Files

| File | Role |
|---|---|
| `api/__init__.py` | Empty; makes `api` a package so `api.app:app` and `flask --app api.app` resolve |
| `api/app.py` | Flask app: configuration, token check, the three routes, the PostgreSQL and Redis calls |

#### Code excerpt

The token check and the upload handler, api/app.py:24-49:

```python
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
```

#### Reasons in comments

> "must match the proxy's body size limit" (api/app.py:19)

> "TODO: use hmac.compare_digest so the comparison is constant-time" (api/app.py:25)

#### Behavior details

- The client's filename is ignored. The stored path is `UPLOAD_DIR/<job_id>.orig`, built from a
  server-generated UUID (api/app.py:39-40).
- The API checks neither content type nor image format; any bytes under the limit are accepted and
  the worker is the first to parse them (api/app.py:33-38, worker/worker.py:20).
- The size check reads at most `MAX_UPLOAD_BYTES + 1` bytes from the parsed upload
  (api/app.py:36-38). Flask's `MAX_CONTENT_LENGTH` is not set anywhere in api/app.py.
  *Inferred:* the request body is received and parsed before this check runs, so the outer limit
  depends on the proxy; rests on the comment at api/app.py:19.
- The file write, the INSERT and the queue push are not one transaction and have no error handling
  (api/app.py:41-48). *Inferred:* if the push fails after the INSERT commits, the row stays
  `queued` with no message behind it; if the INSERT fails, the `.orig` file stays on disk with no
  row; rests on no `try` in `create_job` and the connection block closing before line 48.
- `get_job` passes `job_id` to PostgreSQL without validation (api/app.py:55-58), and the column
  is `UUID` (migrations/001_create_jobs.sql:2). *Inferred:* a non-UUID id fails in PostgreSQL and
  the client gets `500`, not `404`; rests on the column type and no error handler in api/app.py.
- `/healthz` returns `ok` without touching PostgreSQL or Redis (api/app.py:64-66).

#### Dependencies

PostgreSQL table `jobs` (INSERT, SELECT), Redis list `resize:jobs` (LPUSH), directory `UPLOAD_DIR`
(write). Libraries `flask`, `psycopg`, `redis` (api/app.py:9-11).

#### Tests

None. The repo has no test files and requirements.txt lists no test framework; CI only
byte-compiles the code (.github/workflows/ci.yml:17).

> **Gap:** no automated tests for the routes, the token check or the size limit.
> **Question:** is the API tested anywhere outside this repo, and which behavior must a change
> keep?

### worker

- **Path:** `worker/`
- **Technology:** Python 3.12, Pillow 10.4.0, psycopg 3.2.1, redis-py 5.0.8
- **Purpose:** pops resize jobs from Redis and writes thumbnails (worker/worker.py:1).

#### Structure

One module, `worker/worker.py`. At import it reads three environment variables (lines 10-12) and
defines the output sizes and the retry limit (lines 14-15). `main()` (lines 30-52) runs forever:
it blocks on the queue, retries `resize()` on `OSError`, then records the result. `resize()`
(lines 18-27) opens the source image and writes one PNG per size.

The worker has no inbound interface. It never reads `UPLOAD_DIR`; it opens whatever path the
queue message carries (worker/worker.py:20).

#### Public interface

| Kind | Name | Payload | Source |
|---|---|---|---|
| Queue consumer | Redis list `resize:jobs`, `BRPOP`, no timeout | JSON `{"job_id": "<uuid4>", "path": "<UPLOAD_DIR>/<job_id>.orig"}` | worker/worker.py:33-34; producer api/app.py:48 |
| Files written | `OUTPUT_DIR/<job_id>_128x128.png`, `OUTPUT_DIR/<job_id>_512x512.png` | PNG | worker/worker.py:14, worker/worker.py:24-25 |
| Table updated | `jobs.status`, `jobs.outputs` | `done` with a JSON list of paths, or `failed` with `[]` | worker/worker.py:39, worker/worker.py:44, worker/worker.py:48-52 |

#### Files

| File | Role |
|---|---|
| `worker/__init__.py` | Empty; makes `worker` a package so `python -m worker.worker` resolves |
| `worker/worker.py` | Queue loop, retry with backoff, Pillow resize, result UPDATE |

#### Code excerpt

The main loop, worker/worker.py:30-52:

```python
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
```

#### Reasons in comments

> "Back off because the shared volume is sometimes slow to show new files." (worker/worker.py:46)

#### Behavior details

- One job at a time per process (worker/worker.py:32-52).
- Only `OSError` is retried, at most three attempts, sleeping 2 s after the first failure and 4 s
  after the second (worker/worker.py:41-47). A job that fails three times holds the worker for
  about 6 s of sleep plus three attempts.
- *Inferred:* Pillow's `UnidentifiedImageError` subclasses `OSError`, so a non-image upload is
  retried twice before it is marked `failed`; rests on worker/worker.py:20 and Pillow's exception
  hierarchy.
- *Inferred:* images in modes the PNG writer can't store (for example CMYK JPEGs) fail at
  `copy.save(out, "PNG")` with `OSError` and end as `failed`, since nothing converts the mode;
  rests on worker/worker.py:22-25. **To confirm:** whether CMYK or other modes reach the service.
- Any other exception leaves `main()` and ends the process: invalid JSON (line 34), a missing key
  (lines 20, 24, 51), a Redis error (line 33), a PostgreSQL error (lines 48-52). *Inferred:* the
  popped job is gone from Redis and its row stays `queued`; restarting the process depends on a
  supervisor that is not in the repo.
- *Inferred:* Pillow raises `DecompressionBombError`, which is not an `OSError`, for images far
  above its default pixel limit, so such an upload ends the worker process; rests on
  worker/worker.py:20 and worker/worker.py:41, and the repo not setting `Image.MAX_IMAGE_PIXELS`.
  **To confirm** against the Pillow version in requirements.txt:5.
- `job["job_id"]` from the message becomes part of the output filename (worker/worker.py:24) and
  `job["path"]` is opened as given (worker/worker.py:20); neither is validated. See
  [Security](#security).
- The row stays `queued` while the worker processes it; the schema has no `processing` state
  (migrations/001_create_jobs.sql:4).

#### Dependencies

Redis list `resize:jobs` (BRPOP), the shared volume (read `.orig`, write PNGs), PostgreSQL table
`jobs` (UPDATE). Libraries `psycopg`, `redis`, `PIL` (worker/worker.py:6-8).

#### Tests

None; see the api tests gap. CI byte-compiles `worker` only (.github/workflows/ci.yml:17).

> **Gap:** no tests for `resize()`, the retry loop or the failure paths.
> **Question:** which image formats and sizes must the worker support, and where is that checked?

### migrations

- **Path:** `migrations/`
- **Technology:** SQL for PostgreSQL (`JSONB`, `TIMESTAMPTZ` at migrations/001_create_jobs.sql:5-6)
- **Purpose:** creates the `jobs` table and its status index.

| File | Role |
|---|---|
| `migrations/001_create_jobs.sql` | `CREATE TABLE jobs` and `CREATE INDEX jobs_status_idx` |

The schema is described in [Data stores](#data-stores). The folder is copied into the image
(Dockerfile:7), but no code, script or CI step runs it, and the repo has no migration tool.

> **Gap:** how and when migrations are applied.
> **Question:** who runs `001_create_jobs.sql` against each environment, and how will later
> migrations be ordered and tracked?

## Infrastructure and deployment

### Container image

The repo builds one image for both processes. Dockerfile:1-10:

```dockerfile
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
```

- Base image `python:3.12-slim`, pinned by tag, not by digest (Dockerfile:1).
- Dependencies installed before the source is copied (Dockerfile:3-4). *Inferred:* this keeps the
  dependency layer cached across source-only changes; rests on the order of the instructions.
- No `USER` instruction, so the processes run as the image's default user (Dockerfile:1-10).
  *Inferred:* root, the default for the official Python images.
- No `HEALTHCHECK` instruction; the API's `/healthz` (api/app.py:64-66) is available for an
  external probe.
- Default command starts gunicorn with two workers on `0.0.0.0:8000` (Dockerfile:9-10). The worker
  container must override it (Dockerfile:8). *Inferred:* with `python -m worker.worker`, the
  local command in README.md:5.

### Orchestration, provisioning and network

No compose file, Kubernetes manifest, Helm chart or infrastructure-as-code (IaC) file exists in the
repo.

| Item | What the repo shows | Source |
|---|---|---|
| API port | 8000 inside the container | Dockerfile:9-10 |
| Worker port | None; the worker only makes outbound connections | worker/worker.py:31, worker/worker.py:48 |
| PostgreSQL | Sample URL on port 5432 | .env.example:2 |
| Redis | Default URL on port 6379, database 0 | api/app.py:16, worker/worker.py:11, .env.example:4 |
| Proxy in front of the API | Named in a comment only | api/app.py:19 |
| Shared volume | Default paths `/data/uploads` and `/data/outputs` | api/app.py:17, worker/worker.py:12 |

*Inferred:* both containers mount one shared volume at the same path, because the API writes
`UPLOAD_DIR/<job_id>.orig`, puts that absolute path in the message (api/app.py:40, api/app.py:48),
and the worker opens it as is (worker/worker.py:20); the comment at worker/worker.py:46 names "the
shared volume".

> **Gap:** orchestration, ingress, TLS, the proxy, volume provisioning and the PostgreSQL and
> Redis instances are not in the repo.
> **Question:** where is the runtime defined (another repo, a platform team, manual setup), and
> what proxy sits in front of the API?

## CI/CD

One workflow, `.github/workflows/ci.yml:1-27`:

```yaml
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
```

| Job | Trigger | Steps | Source |
|---|---|---|---|
| `check` | Push to `main`, any pull request | Install requirements, byte-compile `api` and `worker` | .github/workflows/ci.yml:3-17 |
| `image` | After `check`, only when the ref is `refs/heads/main` | Build, log in to `registry.example.com` as `ci`, push `image-resizer:<github.sha>` | .github/workflows/ci.yml:19-27 |

- **Test:** `python -m compileall` catches syntax errors only (.github/workflows/ci.yml:17). No
  tests, linting, type checks or image scanning.
- **Packaging:** one image per commit on `main`, tagged with the full commit SHA
  (.github/workflows/ci.yml:25-27). No `latest` or version tag.
- **Deploy, promotion, rollback:** not defined. *Inferred:* rollback would mean redeploying an
  earlier SHA tag; rests on the SHA tagging at .github/workflows/ci.yml:25.
- **Secrets:** `REGISTRY_TOKEN` (.github/workflows/ci.yml:26). The workflow has no `permissions:`
  key, so the `GITHUB_TOKEN` gets the repository's default permissions.
- **Action pinning:** `actions/checkout@v4` and `actions/setup-python@v5` by major tag, not commit
  SHA (.github/workflows/ci.yml:12-13, .github/workflows/ci.yml:24).
- `registry.example.com` is the IANA example domain. **To confirm:** whether it is a placeholder
  for the real registry.

> **Gap:** nothing deploys the pushed image.
> **Question:** what deploys `image-resizer:<sha>`, and how is a release promoted or rolled back?

## Data flows

The repo has two entry-point kinds: HTTP requests to the API and queue messages to the worker. The
three flows below trace `POST /v1/images`, the resize job it produces, and the status poll.

### Upload request

```
client -> proxy      : POST /v1/images, Authorization: Bearer <API_TOKEN>,
                       multipart/form-data, file field "image"
proxy  -> api        : same request on :8000                 (proxy not in repo)
api                  : require_token()                       api/app.py:24-27
api                  : upload.read(MAX_UPLOAD_BYTES + 1)     api/app.py:33-38
api    -> volume     : write UPLOAD_DIR/<job_id>.orig        api/app.py:39-42
api    -> PostgreSQL : INSERT INTO jobs ... 'queued'         api/app.py:43-47
api    -> Redis      : LPUSH resize:jobs {job_id, path}      api/app.py:48
api    -> client     : 202 {"job_id", "status": "queued"}    api/app.py:49
```

| Hop | Where | Reads, builds or sets | Payload | Checks | Caller sees on failure |
|---|---|---|---|---|---|
| Token check | api/app.py:24-27 | Reads header `Authorization`; expects exactly `Bearer <API_TOKEN>` | None | String inequality, not constant-time (api/app.py:25) | `401` |
| Field and size | api/app.py:33-38 | Reads multipart file field `image` | Up to 10,485,761 bytes read into memory | Field present; length at most 10,485,760 bytes | `400` "missing image field"; `413` |
| Store original | api/app.py:39-42 | `job_id = str(uuid.uuid4())`; path `os.path.join(UPLOAD_DIR, f"{job_id}.orig")` | Raw upload bytes | None | *Inferred:* `500`, no error handler |
| Record job | api/app.py:43-47 | New connection from `DATABASE_URL` | `(job_id, path, 'queued')` | Parameterized query | *Inferred:* `500`; the `.orig` file stays |
| Enqueue | api/app.py:48 | Redis key `resize:jobs` | `{"job_id": "<uuid4>", "path": "<UPLOAD_DIR>/<uuid4>.orig"}` | None | *Inferred:* `500`; the row stays `queued` |
| Respond | api/app.py:49 | Status `202` | `{"job_id": "<uuid4>", "status": "queued"}` | None | None |

Example request, built from api/app.py:30-49 and the port in Dockerfile:9-10 with the sample token
from .env.example:6; not captured from a run:

```
curl -i -X POST http://localhost:8000/v1/images \
  -H "Authorization: Bearer change-me" \
  -F "image=@photo.jpg"
```

Response the handler returns (api/app.py:49), with an example UUID:

```
HTTP/1.1 202
Content-Type: application/json

{"job_id": "6f1c2d9e-3b4a-4e8f-9c71-0a5d2e7b8c43", "status": "queued"}
```

Message pushed to `resize:jobs` (api/app.py:48), with the default `UPLOAD_DIR`:

```
{"job_id": "6f1c2d9e-3b4a-4e8f-9c71-0a5d2e7b8c43",
 "path": "/data/uploads/6f1c2d9e-3b4a-4e8f-9c71-0a5d2e7b8c43.orig"}
```

### Background resize job

```
worker -> Redis      : BRPOP resize:jobs, no timeout             worker/worker.py:33
worker               : json.loads(raw) -> {"job_id", "path"}     worker/worker.py:34
worker -> volume     : Image.open(job["path"])                   worker/worker.py:20
worker -> volume     : save OUTPUT_DIR/<job_id>_128x128.png      worker/worker.py:21-26
worker -> volume     : save OUTPUT_DIR/<job_id>_512x512.png      worker/worker.py:21-26
  on OSError         : sleep 2 s, then 4 s; 3rd failure: failed  worker/worker.py:41-47
worker -> PostgreSQL : UPDATE jobs SET status, outputs WHERE id  worker/worker.py:48-52
```

| Hop | Where | Reads, builds or sets | Payload | Checks | On failure |
|---|---|---|---|---|---|
| Pop | worker/worker.py:33-34 | Redis key `resize:jobs` | JSON `{"job_id", "path"}` | None; fields not validated | *Inferred:* Redis or JSON error ends the process; the job is lost |
| Resize | worker/worker.py:18-27 | Opens `job["path"]`; builds `os.path.join(OUTPUT_DIR, f"{job['job_id']}_{width}x{height}.png")` | Two PNGs | None | `OSError` goes to the retry loop |
| Retry | worker/worker.py:35-47 | `attempts` counter, `time.sleep(2 ** attempts)` | None | `MAX_ATTEMPTS = 3` (worker/worker.py:15) | Status `failed`, outputs `[]` |
| Record result | worker/worker.py:48-52 | New connection from `DATABASE_URL` | `(status, json.dumps(outputs), job["job_id"])` | Parameterized query | *Inferred:* error ends the process; the row stays `queued` |

This flow has no HTTP headers; it speaks RESP to Redis and the PostgreSQL protocol through psycopg.
Delivery is at most once: `BRPOP` removes the message before work starts and nothing puts it back
(worker/worker.py:33). There is no dead-letter list.

### Status poll

```
client -> proxy -> api : GET /v1/images/<job_id>, Authorization: Bearer <API_TOKEN>
api                    : require_token()                          api/app.py:54
api    -> PostgreSQL   : SELECT status, outputs FROM jobs WHERE id api/app.py:55-58
api    -> client       : 404, or 200 {"job_id", "status", "outputs"} api/app.py:59-61
```

Example request, built from api/app.py:52-61; not captured from a run:

```
curl -i http://localhost:8000/v1/images/6f1c2d9e-3b4a-4e8f-9c71-0a5d2e7b8c43 \
  -H "Authorization: Bearer change-me"
```

Bodies by state, from the INSERT (api/app.py:45), the worker's UPDATE (worker/worker.py:24,
worker/worker.py:44, worker/worker.py:51) and `jsonify` (api/app.py:61):

```
queued: {"job_id": "6f1c...8c43", "status": "queued", "outputs": null}
done:   {"job_id": "6f1c...8c43", "status": "done",
         "outputs": ["/data/outputs/6f1c...8c43_128x128.png",
                     "/data/outputs/6f1c...8c43_512x512.png"]}
failed: {"job_id": "6f1c...8c43", "status": "failed", "outputs": []}
```

*Inferred:* `outputs` comes back as a JSON array because psycopg loads `JSONB` into a Python list
before `jsonify` sees it; rests on api/app.py:61 passing `row[1]` straight through.

`outputs` holds absolute paths on the server's volume, and no endpoint serves those files.

> **Gap:** how clients get the thumbnail bytes.
> **Question:** what reads `OUTPUT_DIR` and serves the PNGs to clients (a static file server, a
> CDN sync, the caller mounting the volume)?

## Security

### Authentication

- One static bearer token, `API_TOKEN`, read from the environment (api/app.py:18).
  `require_token()` compares the whole `Authorization` header with `f"Bearer {API_TOKEN}"` using
  `!=` and aborts with `401` (api/app.py:26-27). The TODO at api/app.py:25 records that the
  comparison is not constant-time.
- Both job routes call it (api/app.py:32, api/app.py:54). `/healthz` does not
  (api/app.py:64-66).
- No rotation, expiry or per-client tokens. Nothing refuses to start with the sample value
  `change-me` (.env.example:6).
- The worker has no inbound interface and no authentication of its own; it processes anything on
  `resize:jobs` (worker/worker.py:33-34).
- CI logs in to the registry as user `ci` with `secrets.REGISTRY_TOKEN`
  (.github/workflows/ci.yml:26).

### Authorization

None beyond holding the token. Any token holder can read any job (api/app.py:52-61). Job ids are
random UUID version 4 values (api/app.py:39), so reading another client's job takes knowing its
id; there is no ownership check.

### Secrets handling

| Secret | Source | Used at |
|---|---|---|
| `API_TOKEN` | Environment variable (api/app.py:18); sample `change-me` (.env.example:6) | api/app.py:26 |
| PostgreSQL credentials | Inside `DATABASE_URL` (api/app.py:15, worker/worker.py:10); sample user and password `resizer` (.env.example:2) | api/app.py:43, api/app.py:55, worker/worker.py:48 |
| Redis credentials | Inside `REDIS_URL` if set; the default URL has none (api/app.py:16, worker/worker.py:11) | api/app.py:21, worker/worker.py:31 |
| `REGISTRY_TOKEN` | GitHub Actions secret | .github/workflows/ci.yml:26, piped to `docker login --password-stdin` |

No secret manager is referenced. Nothing in `api/` or `worker/` reads a `.env` file, and
`python-dotenv` is not in requirements.txt. *Inferred:* the runtime sets these variables directly.

### Encryption

- **In transit:** gunicorn serves plain HTTP on `0.0.0.0:8000` (Dockerfile:10), with no TLS
  settings in the repo. The sample PostgreSQL and Redis URLs carry no TLS options (.env.example:2,
  .env.example:4). *Inferred:* client TLS, if any, ends at the proxy named in api/app.py:19.
- **At rest:** originals and thumbnails are plain files (api/app.py:41-42, worker/worker.py:25).
  No encryption settings for the volume, PostgreSQL or Redis appear in the repo.

> **Gap:** TLS and at-rest encryption are not defined in the repo.
> **Question:** where does TLS terminate, are the PostgreSQL and Redis links encrypted, and is the
> shared volume encrypted?

### Trust boundaries

| Boundary | Crossed at | Control as of c996f9c |
|---|---|---|
| Client to API | `POST /v1/images`, `GET /v1/images/<job_id>` | Bearer token (api/app.py:24-27); `/healthz` open |
| Untrusted bytes to Pillow | `Image.open(job["path"])` (worker/worker.py:20) | 10 MiB cap upstream (api/app.py:36-38); no format allowlist, no pixel limit set in the repo |
| API to Redis to worker | `LPUSH` (api/app.py:48), `BRPOP` (worker/worker.py:33) | Redis credentials in `REDIS_URL`, if any; message fields not validated (worker/worker.py:20, worker/worker.py:24) |
| API and worker to PostgreSQL | `psycopg.connect` (api/app.py:43, api/app.py:55, worker/worker.py:48) | Credentials in `DATABASE_URL`; parameterized queries |
| CI to registry | `docker login`, `docker push` (.github/workflows/ci.yml:26-27) | `REGISTRY_TOKEN` secret; image job runs on `main` only (.github/workflows/ci.yml:21) |

### Threats

| Threat | Where it applies | Mitigation | Status | Gap |
|---|---|---|---|---|
| Credential theft | `API_TOKEN`, credentials in `DATABASE_URL` and `REDIS_URL`, `REGISTRY_TOKEN` | Secrets come from the environment and GitHub secrets, not code (api/app.py:15-18, .github/workflows/ci.yml:26) | partial | One long-lived shared token with no rotation; sample `change-me` not rejected (.env.example:6); the image runs without a `USER` (Dockerfile:1-10) |
| Traffic interception | Client to API; API and worker to PostgreSQL and Redis | None in the repo | not mitigated | Plain HTTP on :8000 (Dockerfile:10); TLS only *Inferred* at the proxy (api/app.py:19); no TLS options in .env.example:2, .env.example:4 |
| Token or request replay | Every authenticated request | None | not mitigated | Static token with no expiry or nonce (api/app.py:26); each replayed upload creates a new job (api/app.py:39) |
| Confused deputy and privilege escalation | Job reads; worker acting on queue messages | The API builds job ids and paths itself (api/app.py:39-40) | partial | No per-client authorization (api/app.py:52-61). *Inferred:* anyone who can write to Redis chooses which file the worker opens and, through `job_id`, where it writes (worker/worker.py:20, worker/worker.py:24) |
| Injection | SQL; file paths | Parameterized queries (api/app.py:44-47, api/app.py:56-58, worker/worker.py:49-52); upload path built from a UUID, client filename ignored (api/app.py:39-40) | mitigated | Worker-side path trust is covered in the confused deputy row |
| Sensitive data in logs | Applies in principle; the code writes no logs | No logging calls in api/app.py or worker/worker.py | mitigated | Gunicorn's logging is left at its defaults (Dockerfile:10). **To confirm:** whether the proxy logs `Authorization` headers |
| Resource exhaustion | Upload size, image decoding, disk, worker process | 10 MiB cap (api/app.py:19, api/app.py:36-38); three-attempt limit (worker/worker.py:15) | partial | `MAX_CONTENT_LENGTH` not set; no pixel limit; *Inferred:* non-`OSError` decode errors end the worker (worker/worker.py:41); no file cleanup anywhere; two gunicorn workers (Dockerfile:10) |
| Abuse without rate limits | `POST /v1/images`, `GET /v1/images/<job_id>` | None in the repo | not mitigated | No rate limiting in api/app.py; proxy behavior unknown |
| Dependency supply chain | requirements.txt, base image, CI actions; Pillow parses untrusted input | Direct dependencies pinned with `==` (requirements.txt:1-5) | partial | No hashes or lock file for transitive dependencies; base image by tag (Dockerfile:1); actions by major tag (.github/workflows/ci.yml:12-13, .github/workflows/ci.yml:24); no dependency or image scanning |
| Timing attack on the token | `require_token()` | None | not mitigated | Non-constant-time `!=` (api/app.py:26); TODO at api/app.py:25 |
| Internal path disclosure | `GET /v1/images/<job_id>` responses | None | not mitigated | Absolute server paths returned to clients (api/app.py:61, worker/worker.py:24) |

## Configuration

### Environment variables

| Name | Purpose | Required | Default | Read at | Sample |
|---|---|---|---|---|---|
| `DATABASE_URL` | PostgreSQL connection string for both processes | Required in api and worker | None | api/app.py:15, worker/worker.py:10 | `postgresql://resizer:resizer@localhost:5432/resizer` (.env.example:2) |
| `REDIS_URL` | Redis instance used as the job queue | Optional | `redis://localhost:6379/0` | api/app.py:16, worker/worker.py:11 | Same as the default (.env.example:4) |
| `API_TOKEN` | Shared bearer token for API clients | Required in api | None | api/app.py:18 | `change-me` (.env.example:6) |
| `UPLOAD_DIR` | Directory for uploaded originals | Optional, api only | `/data/uploads` | api/app.py:17 | `/data/uploads` (.env.example:7) |
| `OUTPUT_DIR` | Directory for thumbnails | Optional, worker only | `/data/outputs` | worker/worker.py:12 | `/data/outputs` (.env.example:8) |

The comments in `.env.example` mark `DATABASE_URL` and `API_TOKEN` as required (.env.example:1,
.env.example:5), which matches the `os.environ[...]` reads in the code.

The worker never reads `UPLOAD_DIR`; changing it on the API alone works only if the worker sees the
same path (api/app.py:40, worker/worker.py:20).

### Values fixed in code

| Setting | Value | Source |
|---|---|---|
| Upload limit | `10 * 1024 * 1024` bytes, kept equal to the proxy's limit | api/app.py:19 |
| Queue key | `resize:jobs` | api/app.py:48, worker/worker.py:33 |
| Thumbnail sizes | `[(128, 128), (512, 512)]` | worker/worker.py:14 |
| Retry attempts | `3` | worker/worker.py:15 |
| Backoff | `2 ** attempts` seconds | worker/worker.py:47 |
| Gunicorn bind and workers | `0.0.0.0:8000`, `2` | Dockerfile:10 |

### Config files and flags

- `.env.example`: sample values only (.env.example:1-8).
- `Dockerfile`: the API's runtime command (Dockerfile:10).
- `.github/workflows/ci.yml`: registry host and image name (.github/workflows/ci.yml:25-27).
- No feature flags.

> **Gap:** no per-environment configuration exists in the repo.
> **Question:** where are the values for each environment kept, and do any differ beyond
> connection strings and the token?

## Observability

As of c996f9c the repo has no logging, metrics, tracing or error tracking:

- No `logging` import or `print` in api/app.py or worker/worker.py.
- No observability library in requirements.txt:1-5.
- Gunicorn runs with no logging flags (Dockerfile:10), so its defaults apply.
- `GET /healthz` returns `ok` without checking PostgreSQL, Redis or the volume
  (api/app.py:64-66).
- The worker has no health signal. A failed job shows only as `status = 'failed'` with
  `outputs = []` (worker/worker.py:44, worker/worker.py:51); the exception is discarded.
- No dashboards or alerts are defined.

*Inferred:* queue depth (`LLEN resize:jobs`) and the count of rows by status (served by
`jobs_status_idx`, migrations/001_create_jobs.sql:9) are the only signals available without code
changes; rests on the queue key and the index.

> **Gap:** no logs, metrics or alerts for either process.
> **Question:** how does an operator learn that the worker has stopped or that jobs are failing?

## Data stores

### PostgreSQL

Engine inferred from the `postgresql://` sample URL (.env.example:2) and the `JSONB` and
`TIMESTAMPTZ` types (migrations/001_create_jobs.sql:5-6). No version is stated.

Table `jobs`, migrations/001_create_jobs.sql:1-7:

| Column | Type | Constraints | Written by | Read by |
|---|---|---|---|---|
| `id` | `UUID` | Primary key | api INSERT (api/app.py:45) | api SELECT (api/app.py:57); worker UPDATE `WHERE` (worker/worker.py:50) |
| `source_path` | `TEXT` | `NOT NULL` | api INSERT (api/app.py:45) | No code in the repo |
| `status` | `TEXT` | `NOT NULL`, `CHECK (status IN ('queued', 'done', 'failed'))` | api INSERT `'queued'`; worker UPDATE `done` or `failed` | api SELECT (api/app.py:57) |
| `outputs` | `JSONB` | Nullable | worker UPDATE (worker/worker.py:50-51) | api SELECT (api/app.py:57) |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL DEFAULT now()` | Database default | No code in the repo |

Index `jobs_status_idx` on `status` (migrations/001_create_jobs.sql:9). No query in `api/` or
`worker/` filters on `status`. **To confirm:** which queries the index is for.

Status lifecycle:

```
INSERT (api/app.py:45)       UPDATE (worker/worker.py:50)
        |                       +--> done    outputs = [paths]
        v                       |
     queued --------------------+
                                |
                                +--> failed  outputs = []
```

- **Connections:** one new connection per API request and per job, no pool (api/app.py:43,
  api/app.py:55, worker/worker.py:48). Commits rely on the `with psycopg.connect(...)` block;
  there is no explicit `commit()`.
- **Migrations:** one SQL file, copied into the image (Dockerfile:7), applied by nothing in the
  repo; see the gap in [Components](#components).
- **Backups and retention:** not stated. No code deletes rows.

### Redis

Used only as a queue. The list `resize:jobs` receives `LPUSH` from the API (api/app.py:48) and
`BRPOP` from the worker (worker/worker.py:33), giving FIFO order. Message format:
`{"job_id": "<uuid4>", "path": "<UPLOAD_DIR>/<job_id>.orig"}` (api/app.py:48). No version,
persistence or memory settings are in the repo.

### Shared file volume

| Directory | Variable | Files | Writer | Reader |
|---|---|---|---|---|
| `/data/uploads` by default | `UPLOAD_DIR` | `<job_id>.orig`, raw upload bytes | api (api/app.py:40-42) | worker, through the message path (worker/worker.py:20) |
| `/data/outputs` by default | `OUTPUT_DIR` | `<job_id>_128x128.png`, `<job_id>_512x512.png` | worker (worker/worker.py:24-25) | No code in the repo |

No code creates these directories or deletes files from them.

> **Gap:** retention for originals, thumbnails, job rows and Redis data; backups for PostgreSQL.
> **Question:** how long are uploads and thumbnails kept, and what cleans them up?

### Caching

None. No cache layer, HTTP cache headers or memoization in the code.

## Performance

Only what the repo shows:

- **API concurrency:** two gunicorn workers with no `--worker-class` or `--threads` flag
  (Dockerfile:10). *Inferred:* gunicorn's default synchronous workers, so two requests at a time
  per container, and a slow upload holds one of them.
- **Memory per upload:** up to 10 MiB plus one byte held in memory per request (api/app.py:36).
- **Database:** a new PostgreSQL connection per request and per job, no pool (api/app.py:43,
  api/app.py:55, worker/worker.py:48).
- **Worker throughput:** one job at a time per process (worker/worker.py:32-52). *Inferred:*
  scaling means running more worker processes; Redis hands each `BRPOP` result to one client.
- **Retry cost:** a job that fails three times sleeps 6 s in total (2 s, then 4 s) while blocking
  its worker (worker/worker.py:41-47).
- **Upload throughput:** the `202` returns before any resizing (api/app.py:49), so API latency
  covers the disk write, one INSERT and one push.
- No stated targets, benchmarks or load tests.

## Technology stack

### Languages and runtimes

| Item | Version | Pinned in |
|---|---|---|
| Python | 3.12 | Dockerfile:1 (`python:3.12-slim`), .github/workflows/ci.yml:15 |
| SQL, PostgreSQL dialect | Not pinned | migrations/001_create_jobs.sql |

### Frameworks and libraries

| Item | Version | Pinned in | Used for |
|---|---|---|---|
| Flask | 3.0.3 | requirements.txt:1 | HTTP routing (api/app.py:11) |
| gunicorn | 22.0.0 | requirements.txt:2 | WSGI server (Dockerfile:10) |
| psycopg[binary] | 3.2.1 | requirements.txt:3 | PostgreSQL client (api/app.py:9, worker/worker.py:6) |
| redis (redis-py) | 5.0.8 | requirements.txt:4 | Redis client (api/app.py:10, worker/worker.py:7) |
| Pillow | 10.4.0 | requirements.txt:5 | Image decode, resize, PNG encode (worker/worker.py:8) |

Transitive dependencies are not locked; requirements.txt has no hashes.

### Infrastructure tools

| Item | Version | Pinned in |
|---|---|---|
| Docker base image | `python:3.12-slim`, by tag | Dockerfile:1 |
| GitHub Actions runner | `ubuntu-latest`, floating | .github/workflows/ci.yml:10, .github/workflows/ci.yml:22 |
| actions/checkout | v4 | .github/workflows/ci.yml:12, .github/workflows/ci.yml:24 |
| actions/setup-python | v5 | .github/workflows/ci.yml:13 |

### Data stores

| Item | Version | Source |
|---|---|---|
| PostgreSQL | Not stated | .env.example:2, migrations/001_create_jobs.sql |
| Redis | Not stated | .env.example:4, api/app.py:16 |

### Observability and security tools

None in the repo.

## Open work

### Markers

| Area | TODO | FIXME | HACK |
|---|---|---|---|
| api | 1 | 0 | 0 |
| worker | 0 | 0 | 0 |

| Marker | Location | Text |
|---|---|---|
| TODO | api/app.py:25 | "use hmac.compare_digest so the comparison is constant-time" |

No deprecated code and no other planned work is referenced in the code.

### Visible technical debt

- No tests; CI checks syntax only (.github/workflows/ci.yml:17).
- No migration runner (Dockerfile:7 copies the SQL; nothing applies it).
- At-most-once queue delivery and a worker that exits on any non-`OSError` exception
  (worker/worker.py:33, worker/worker.py:41).
- Non-atomic upload path: file, row and queue push can disagree (api/app.py:41-48).
- No `processing` state (migrations/001_create_jobs.sql:4).
- No logging, metrics or dependency-aware health check (see [Observability](#observability)).
- No cleanup of uploads, thumbnails or rows (see [Data stores](#data-stores)).
- Upload limit duplicated between the app and an external proxy (api/app.py:19).
- Worker trusts the path and id in queue messages (worker/worker.py:20, worker/worker.py:24).

## Quick reference

### Key paths

| What | Path |
|---|---|
| API entry point | api/app.py:13, served as `api.app:app` (Dockerfile:10) |
| Worker entry point | worker/worker.py:30, worker/worker.py:55-56 |
| Token check | api/app.py:24-27 |
| Schema | migrations/001_create_jobs.sql |
| Sample configuration | .env.example |
| Image build | Dockerfile |
| CI | .github/workflows/ci.yml |

### URLs in config

| URL | Source |
|---|---|
| `registry.example.com/image-resizer:<sha>` | .github/workflows/ci.yml:25-27 |
| `postgresql://resizer:resizer@localhost:5432/resizer` (sample) | .env.example:2 |
| `redis://localhost:6379/0` (default and sample) | api/app.py:16, worker/worker.py:11, .env.example:4 |

### Commands

No Makefile or package scripts exist. Commands found in the repo (`ci.yml` is
`.github/workflows/ci.yml`):

```
flask --app api.app run                                   # run the API locally (README.md:5)
python -m worker.worker                                   # run the worker locally (README.md:5)
pip install -r requirements.txt                           # install dependencies (ci.yml:16)
python -m compileall api worker                           # the CI check (ci.yml:17)
docker build -t registry.example.com/image-resizer:<sha> .   # image build (ci.yml:25)
gunicorn --bind 0.0.0.0:8000 --workers 2 api.app:app      # container default (Dockerfile:10)
```

The README's local commands need `DATABASE_URL` and `API_TOKEN` set, a reachable PostgreSQL with
the migration applied, and Redis; README.md:5 doesn't mention these.

### Troubleshooting

| Symptom | Likely cause | Source |
|---|---|---|
| API or worker exits at start with `KeyError` | `DATABASE_URL` or `API_TOKEN` not set | api/app.py:15, api/app.py:18, worker/worker.py:10 |
| Jobs stay `queued` | *Inferred:* worker not running or crashed, or the Redis push failed after the INSERT | worker/worker.py:33-52, api/app.py:43-48 |
| Jobs end `failed` although the upload exists | Volume slow to show new files, or mounted at a different path in the worker | worker/worker.py:46, worker/worker.py:20 |
| Large uploads rejected inconsistently | App and proxy body limits differ | api/app.py:19 |
| `GET /v1/images/<id>` returns `500` | *Inferred:* the id is not a valid UUID | api/app.py:55-58, migrations/001_create_jobs.sql:2 |
