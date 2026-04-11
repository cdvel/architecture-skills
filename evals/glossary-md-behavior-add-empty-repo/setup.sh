#!/usr/bin/env bash
# Fixture: a small image-resizing API with no glossary and no ADR register.
set -e

git init -q
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

mkdir -p src

cat > README.md <<'EOF'
# image-resizer

An HTTP API that resizes uploaded images into a fixed set of preset sizes.
EOF

cat > src/presets.py <<'EOF'
"""Preset sizes the API can produce for an uploaded image."""

PRESETS = {
    "thumb": {"width": 160, "height": 160, "format": "webp"},
    "card": {"width": 640, "height": 360, "format": "jpeg"},
    "hero": {"width": 1600, "height": 900, "format": "jpeg"},
}
EOF

cat > src/resize.py <<'EOF'
"""Produces one variant of an uploaded image per preset."""

from presets import PRESETS


def variants_for(upload_id: str) -> list[str]:
    return [f"{upload_id}/{name}" for name in PRESETS]
EOF

git add -A
git commit -q -m "chore: initial commit"
