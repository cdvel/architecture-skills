---
type: regex
pattern: '## Technology stack\n\n\| Component \| Version \| Role \| Pinned at \|\n\|-{3}\|-{3}\|-{3}\|-{3}\|\n\| Python \| 3\.12 \| Runtime \| `Dockerfile:1`, `\.github/workflows/ci\.yml:15` \|\n\| Flask \| 3\.0\.3 \| HTTP framework \| `requirements\.txt:1` \|\n\| gunicorn \| 22\.0\.0 \| WSGI server \| `requirements\.txt:2` \|\n\| psycopg \| 3\.2\.1 \| PostgreSQL client \| `requirements\.txt:3` \|\n\| redis \| 5\.0\.8 \| Redis client \| `requirements\.txt:4` \|\n\| Pillow \| 10\.4\.0 \| Image resizing \| `requirements\.txt:5` \|\n'
target:
  source: file
  path: docs/ARCHITECTURE.md
---
