CREATE TABLE jobs (
    id UUID PRIMARY KEY,
    source_path TEXT NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('queued', 'done', 'failed')),
    outputs JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX jobs_status_idx ON jobs (status);
