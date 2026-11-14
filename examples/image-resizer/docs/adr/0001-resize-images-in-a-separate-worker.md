---
id: ADR-0001
title: Resize uploaded images in a separate worker fed by a Redis list
status: Accepted
status_note: ""
date: 2026-11-14
revised: []
authors:
  - Fixture Author
deciders: []
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - {term: Resize job, definition: "One upload's request for thumbnails, recorded as a row in the jobs table and queued as a message on the job queue."}
  - {term: Job queue, definition: "The Redis list resize:jobs, which the API pushes resize jobs onto and the worker pops them from."}
  - {term: Worker, definition: "The separate process in worker/worker.py that pops resize jobs from the job queue and writes thumbnails, as opposed to gunicorn's request-serving worker processes."}
---

# ADR-0001: Resize uploaded images in a separate worker fed by a Redis list

**Status:** Accepted · **Date:** 2026-11-14

## Context

image-resizer accepts uploads of up to 10 MiB at `POST /v1/images` (api/app.py:19, api/app.py:30-49) and turns each one into 128x128 and 512x512 PNG thumbnails (worker/worker.py:14). Resizing one upload takes seconds. The API runs under gunicorn with two synchronous worker processes per container (Dockerfile:10), so work done inside the request holds one of those two processes until it finishes.

Constraints: one small team runs the service, and PostgreSQL and Redis already run. An option that adds no new service or vendor costs the least to operate.

The code already follows this decision: the API pushes jobs onto the Redis list `resize:jobs` (api/app.py:48) and the worker pops them (worker/worker.py:33). docs/ARCHITECTURE.md lists this choice under key decisions with the reason marked as not stated. No earlier ADR covers it.

## Options considered

| | Resize in the request | Worker fed by a Redis list | External image CDN |
|---|---|---|---|
| Upload response time | Includes the resize (seconds) | A disk write, one INSERT, one push | The upload only |
| gunicorn processes held | For the whole resize | For the upload only | For the upload only |
| New service or vendor | None | None | Paid CDN |
| Where images are processed | API containers | Worker containers | Vendor's infrastructure |
| Processes to run | API | API and worker | API |
| Client contract | Thumbnails in the upload response | `202`, then poll for the result | Resized URLs fetched on demand |

### Resize in the request

The API decodes and resizes the upload before responding and returns the thumbnails in the same response. Its supporters point out that it is the simplest design: one process, no queue, no job table, no shared volume and no polling. A broken image is rejected with a `4xx` on the upload itself instead of turning up later as a failed job.

Rejected because each upload would take seconds and hold a gunicorn process for that time. With two synchronous processes per container (Dockerfile:10), two concurrent uploads would leave the container unable to answer any other request.

### Worker fed by a Redis list (chosen)

The API stores the original, records a job row and pushes the job onto a Redis list, then returns `202`. A separate worker process pops jobs, writes the thumbnails and updates the row. Its supporters point out that the upload returns as soon as the file is stored, that resize capacity grows by running more worker processes without touching the API, and that it uses the Redis and PostgreSQL the team already runs. A plain list with `LPUSH` and `BRPOP` is one line in each process (api/app.py:48, worker/worker.py:33).

Chosen because it keeps the resize out of the upload request without adding a service or vendor, which suits one small team.

### External image CDN that resizes on the fly

Originals are stored once and an image CDN produces each size when it is first requested, then caches it. Its supporters point out that there is no worker, queue, job table or thumbnail storage to run, that new sizes need no reprocessing of existing images, and that the vendor carries the work of decoding untrusted images.

Rejected because it adds a paid dependency and sends our images to infrastructure we do not run.

## Decision

We will resize uploaded images in a separate worker process, not inside the upload request: the API stores the original, records a `queued` row in the PostgreSQL `jobs` table, pushes the job onto the Redis list `resize:jobs` and returns `202` with the job id, and the worker pops jobs from that list, writes the thumbnails and records the result on the job row, which clients poll.

## Consequences

### Positive

- An upload's response time covers a disk write, one INSERT and one push, not the resize (api/app.py:39-49). gunicorn processes are free for the next request.
- Resize capacity scales on its own: running more worker processes adds throughput, since Redis hands each `BRPOP` result to one client (worker/worker.py:33).
- No new service or vendor. Images and thumbnails stay on our own volume.
- Only the worker decodes untrusted image bytes with Pillow (worker/worker.py:20). The API never parses an image (api/app.py:33-38).

### Negative

- A second process to deploy, restart and monitor. Both run from one image and the worker overrides the command (Dockerfile:8); nothing in the repo restarts a stopped worker.
- Clients get an asynchronous contract: `202`, then polling `GET /v1/images/<job_id>` (api/app.py:52-61). A broken image shows up later as a `failed` job, not as an error on the upload. Job state needs the `jobs` table (migrations/001_create_jobs.sql).
- A plain Redis list delivers each job at most once. `BRPOP` removes the message before work starts and nothing puts it back (worker/worker.py:33), so a job held by a worker that crashes is lost and its row stays `queued`. Retries and dead-lettering are left to the worker.
- Image bytes travel through a shared volume that both processes must mount at the same path, not through the queue (api/app.py:40-48, worker/worker.py:20). The worker already retries because the volume is sometimes slow to show new files (worker/worker.py:46).
- Redis is now on the upload path, and the file write, the INSERT and the push are separate steps with no transaction (api/app.py:41-48). If the push fails, the row stays `queued` with no message behind it.

## References

- docs/ARCHITECTURE.md: the upload and background resize data flows, and the performance notes
- api/app.py: upload handler and queue push
- worker/worker.py: queue consumer, resize and result update
- migrations/001_create_jobs.sql: the `jobs` table
- Dockerfile: gunicorn process count and the shared image for both processes
