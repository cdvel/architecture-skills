# Glossary

This file is the project's current vocabulary: each term has one definition and the source it comes from. The Source column is a citation, not a history. Rows that no longer apply are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| Job queue | The Redis list resize:jobs, which the API pushes resize jobs onto and the worker pops them from. | [ADR-0001](adr/0001-resize-images-in-a-separate-worker.md) |
| Resize job | One upload's request for thumbnails, recorded as a row in the jobs table and queued as a message on the job queue. | [ADR-0001](adr/0001-resize-images-in-a-separate-worker.md) |
| Worker | The separate process in worker/worker.py that pops resize jobs from the job queue and writes thumbnails, as opposed to gunicorn's request-serving worker processes. | [ADR-0001](adr/0001-resize-images-in-a-separate-worker.md) |
