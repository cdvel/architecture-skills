---
type: llm
focus:
  source: file
  path: docs/GLOSSARY.md
---
The repository is a small image-resizing service: a Flask API accepts uploads and records jobs in Postgres, a Redis list `resize:jobs` queues them, and a worker writes resized copies.

PASS if every row in the glossary table names something with a meaning specific to this service (for example a job, the job queue, a job status, the resized files, the original upload, the configured sizes).

FAIL if any row defines general programming, web or library vocabulary with no narrower meaning in this project, such as HTTP, API, endpoint, database, Postgres, Redis, Flask, Pillow, JSON, UUID or environment variable.
