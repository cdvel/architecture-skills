> Reply from `/architecture-skills:brief` in this folder on 2026-11-14 (Claude Code 2.1.325, Opus 5.5). `brief` answers in chat and writes no files; the reply was saved here by hand.

image-resizer is a small Python service that takes image uploads over HTTP and turns each one into 128x128 and 512x512 PNG thumbnails in the background. Its callers share one bearer token, and the doc infers they are internal services rather than end users [Summary]. A Flask API runs under gunicorn (a Python web server). It saves the original on a shared volume, records a job row in PostgreSQL and pushes the job onto a Redis list used as a queue. A separate worker process pops the job, resizes the image with Pillow (a Python imaging library) and updates the row, while the client polls for the result [Summary, ADR-0001]. In my view the core split between API and worker is sound and well reasoned for a small team, but the rest is unfinished: jobs can be lost or stuck as `queued` without anyone noticing, and the repo doesn't show how the service is deployed, migrated or monitored, or how clients get their thumbnails.

## Source

`docs/ARCHITECTURE.md` · architecture-md 0.1.0 · generated 2026-11-14 · commit c996f9c · 1 commit behind HEAD. That one commit only added ADR-0001 and the glossary, so the code it describes hasn't changed. The doc still says the repo has no ADR register, though. I'd regenerate it with architecture-md so it picks them up.

## Picture

```
+--------------+                            +------------------------+
| API client   |  HTTP, Bearer <API_TOKEN>  | reverse proxy          |
| (internal,   |--------------------------->| not in repo; inferred  |
|  inferred)   |<-- 202, status, outputs ---| from api/app.py:19     |
+--------------+                            +------------------------+
                                                        | HTTP :8000
                                                        v
        +-------------------------------------------------------+
        | api: Flask on gunicorn, 2 sync processes              |
        +-------------------------------------------------------+
             | SQL INSERT,        | LPUSH              | write
             | SELECT            | job message        | <job_id>.orig
             v                   v                    v
      +--------------+   +---------------+   +-----------------+
      | PostgreSQL   |   | Redis list    |   | shared volume   |
      | table jobs   |   | resize:jobs   |   | /data/uploads   |
      |              |   | (job queue)   |   | /data/outputs   |
      +--------------+   +---------------+   +-----------------+
             ^                   | BRPOP              ^ read .orig,
             | SQL UPDATE        v                    | write 2 PNGs
        +-------------------------------------------------------+
        | worker: Pillow resize, one job at a time              |
        +-------------------------------------------------------+

GitHub Actions --docker push--> registry.example.com/image-resizer:<sha>
(one image runs both api and worker; nothing in the repo deploys it)
```

[Diagrams]

## Parts

| Part | What it does | Where it lives |
|---|---|---|
| api | Checks the token, accepts uploads up to 10 MiB, saves the original, records a `queued` resize job, pushes it, answers status polls | `api/app.py` |
| worker | Pops one job at a time, writes two PNGs, retries file errors up to 3 times, marks the row `done` or `failed` | `worker/worker.py` |
| jobs table | Job state (`queued`, `done`, `failed`) and output paths; no `processing` state | `migrations/001_create_jobs.sql` (nothing in the repo applies it) |
| Job queue | Redis list `resize:jobs` carrying `{job_id, path}` | Key hard-coded in both modules |
| Shared volume | Originals and thumbnails, mounted at the same path in both containers (inferred) | `/data/uploads`, `/data/outputs` |
| Image and CI | One Docker image for both processes; CI (continuous integration) byte-compiles and pushes a commit-tagged image from `main` | `Dockerfile`, `.github/workflows/ci.yml` |

[Components, Data stores, CI/CD]

## A request, end to end

Upload an image and fetch its thumbnails [Data flows]:

1. **Client** posts the file as form field `image` to `POST /v1/images` through the proxy, with `Authorization: Bearer <API_TOKEN>`.
2. **api** compares the header with the token using a plain `!=` (not constant-time) and reads at most 10 MiB plus one byte. It answers `401`, `400` or `413` on failure.
3. **api** writes `UPLOAD_DIR/<uuid>.orig`, inserts a `queued` row and pushes `{job_id, path}` onto `resize:jobs`. These are three separate steps with no transaction.
4. **api** returns `202` with the job id. No image has been parsed yet.
5. **worker** takes the message with BRPOP (a blocking pop that removes it from Redis), opens the path with Pillow and writes two PNGs to `OUTPUT_DIR`. On a file error it waits 2 s, then 4 s, and gives up after the third try.
6. **worker** updates the row to `done` with the output paths, or to `failed` with `[]`.
7. **Client** polls `GET /v1/images/<job_id>` and gets the status plus absolute paths on the server's volume. No endpoint serves the PNGs themselves.

## Where to start reading

- `api/app.py:24-49`: the token check and the upload handler, the whole write path in about 25 lines.
- `worker/worker.py:30-52`: the queue loop and retry logic, which decide delivery and crash behavior.
- `migrations/001_create_jobs.sql`: the job table and its three states.
- `Dockerfile`: one image for both processes, with gunicorn running two synchronous processes.
- `.github/workflows/ci.yml`: what CI checks (syntax only) and what it publishes.

[Quick reference, Components]

## Assessment (opinion)

**Strengths**
- The separate worker is the right call here, and the reason is recorded [ADR-0001]. With only two synchronous gunicorn processes per container, resizing inside the request would stall the API. The worker adds no new service for a small team to run. The doc's Performance section shows that reason still holds.
- Only the worker decodes untrusted image bytes. The API never parses an image [ADR-0001], so Pillow's attack surface stays off the request path.
- Upload paths are built from a server-generated UUID and every query is parameterized [Security]. That closes the obvious path traversal and SQL injection routes.

**Risks**
- Jobs can disappear or sit `queued` forever with no signal [Data flows, Components]:
  - Delivery is at most once: if a worker dies after popping a job, the job is gone.
  - The worker exits on any error other than `OSError`: bad JSON, a database error, and (inferred) Pillow's error for decompression bombs (small files that decode to huge images).
  - The upload's file, row and queue push can disagree.

  ADR-0001 accepts at-most-once delivery and leaves retries to the worker. I think that only holds if something restarts the worker and sweeps up stale `queued` rows, and the repo has neither.
- Untrusted images are decoded with no format allowlist and no pixel limit, in a container that (inferred) runs as root [Security, Infrastructure and deployment]. No reason is recorded.
- Nothing would catch a regression or an outage [CI/CD, Observability, Data stores]:
  - There are no tests, and CI only byte-compiles.
  - There are no logs or metrics, and `/healthz` checks nothing.
  - There's no migration runner and no cleanup of files or rows.

  No reason is recorded.

**Open questions**
- How do clients get the thumbnails? `outputs` holds absolute server paths, and no endpoint serves the files [Data flows].
- Where does the service run? What deploys the image, provides the shared volume, applies migrations and restarts a dead worker? [Infrastructure and deployment, CI/CD]
- Who are the callers, and is one shared token with no per-client job ownership enough for them? The doc only infers they are internal services [Summary, Security].
