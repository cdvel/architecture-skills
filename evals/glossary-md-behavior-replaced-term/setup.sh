#!/usr/bin/env bash
# Fixture: a small worker repo whose glossary calls one upload a "task"; the code still says task.
# The team renames the term to "job"; the old name must stay as a replaced term.
set -e

mkdir -p docs worker

cat > docs/GLOSSARY.md <<'EOF'
# Glossary

This file is the project's current vocabulary: each term has one definition and the source it comes from. The Source column is a citation, not a history. A replaced term keeps a row naming its replacement while the old name still appears in the repo; other rows that no longer apply are removed.

| Term | Definition | Source |
|---|---|---|
| Rendition | One resized copy of an uploaded image at one of the configured sizes. | Convention |
| Task | One upload accepted by the API, tracked until its renditions are written. | Convention |
EOF

cat > worker/worker.py <<'EOF'
"""Worker: takes queued tasks and writes their renditions."""

SIZES = [(128, 128), (512, 512)]


def process(task):
    """Write one rendition per entry in SIZES for this task."""
    return [f"{task['id']}_{w}x{h}.png" for w, h in SIZES]
EOF

cat > README.md <<'EOF'
# resizer-worker

Takes queued tasks and writes their renditions.
EOF

git init -q -b main
git config user.name "Fixture Author"
git config user.email "fixture@example.com"
git config commit.gpgsign false
git add -A
git commit -q -m "feat: add resize worker"
