#!/usr/bin/env bash
# Fixture: an image-resizing API with an ADR register. ADR-0003 has just been
# accepted and supersedes ADR-0002; the glossary still cites ADR-0002 for Thumbnail.
set -e

git init -q
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

mkdir -p docs/adr src

cat > README.md <<'EOF'
# image-resizer

An HTTP API that stores uploaded images and resizes them into preset sizes.
Decisions are in docs/adr/; terms are in docs/GLOSSARY.md.
EOF

cat > src/resize.py <<'EOF'
"""Resizes an original into one variant per preset when it is uploaded."""

PRESETS = {"thumbnail": (160, 160), "card": (640, 360)}


def on_upload(original_key: str) -> list[str]:
    return [f"{original_key}/{name}" for name in PRESETS]
EOF

cat > docs/adr/README.md <<'EOF'
# Architecture decision records

| ID | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-store-originals-in-object-storage.md) | Store originals in object storage | Accepted | 2025-12-05 |
| [ADR-0002](0002-resize-on-request.md) | Resize on request | Superseded | 2025-12-13 |
| [ADR-0003](0003-resize-on-upload-with-presets.md) | Resize on upload with presets | Accepted | 2026-02-14 |
EOF

cat > docs/adr/0001-store-originals-in-object-storage.md <<'EOF'
---
id: ADR-0001
title: Store originals in object storage
status: Accepted
status_note: ""
date: 2025-12-05
revised: []
authors: [Eval Fixture]
deciders: [Eval Fixture]
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - term: Original
    definition: The image file exactly as the client uploaded it.
---

# ADR-0001: Store originals in object storage

Status: Accepted, 2025-12-05

## Context

Uploads were written to the API server's disk and lost when an instance was replaced.

## Decision

Every upload is stored unchanged in object storage under a key derived from its upload id.

## Consequences

Instances hold no state. Every resize reads the original from object storage.
EOF

cat > docs/adr/0002-resize-on-request.md <<'EOF'
---
id: ADR-0002
title: Resize on request
status: Superseded
status_note: ""
date: 2025-12-13
revised: []
authors: [Eval Fixture]
deciders: [Eval Fixture]
supersedes: []
supersedes_in_part: []
superseded_by: [ADR-0003]
superseded_in_part_by: []
related:
  - {id: ADR-0001, reason: Resizes read the stored original}
terms:
  - term: Thumbnail
    definition: A 160-pixel square copy of an original, made the first time a client requests it.
---

# ADR-0002: Resize on request

Status: Superseded by ADR-0003, 2025-12-13

## Context

Clients need small copies of images for list views.

## Decision

The API resizes an original the first time a client requests a thumbnail and caches the result.

## Consequences

The first request for each thumbnail is slow.
EOF

cat > docs/adr/0003-resize-on-upload-with-presets.md <<'EOF'
---
id: ADR-0003
title: Resize on upload with presets
status: Accepted
status_note: ""
date: 2026-02-14
revised: []
authors: [Eval Fixture]
deciders: [Eval Fixture]
supersedes: [ADR-0002]
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related:
  - {id: ADR-0001, reason: Variants are made from the stored original}
terms:
  - term: Thumbnail
    definition: The smallest preset variant, made when the original is uploaded.
  - term: Variant
    definition: A resized copy of an original at one preset's size.
---

# ADR-0003: Resize on upload with presets

Status: Accepted, 2026-02-14

## Context

Resizing on request (ADR-0002) made the first view of every image slow, and clients asked for more sizes than the thumbnail.

## Decision

When an original is uploaded, the API produces one variant per preset in src/resize.py and stores them next to the original.

## Consequences

No request waits on a resize. Adding a preset means backfilling variants for existing originals.
EOF

cat > docs/GLOSSARY.md <<'EOF'
# Glossary

This file is the project's current vocabulary: each term has one definition and the source it comes from. The Source column is a citation, not a history. Rows that no longer apply are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| Original | The image file exactly as the client uploaded it. | [ADR-0001](adr/0001-store-originals-in-object-storage.md) |
| Thumbnail | A 160-pixel square copy of an original, made the first time a client requests it. | [ADR-0002](adr/0002-resize-on-request.md) |
| Preset | A named combination of width, height and output format. | Convention |
EOF

git add -A
git commit -q -m "docs: accept ADR-0003, resize on upload with presets"
