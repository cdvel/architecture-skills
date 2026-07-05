#!/usr/bin/env bash
# Fixture: online-shop repo whose docs/ARCHITECTURE.md (from architecture-md, left untracked) records a commit two commits behind HEAD.
set -e

git init -q
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"
mkdir -p src/shop/api/routes src/shop/worker migrations tests/api deploy .github/workflows

cat > README.md <<'FILE'
# shopfront

Backend for a small online shop. Run `docker compose up`, then open http://localhost:8000/docs.
FILE

cat > pyproject.toml <<'FILE'
[project]
name = "shopfront"
version = "0.4.0"
requires-python = ">=3.12"
dependencies = ["fastapi", "uvicorn", "psycopg[pool]", "redis", "rq", "httpx", "itsdangerous"]
FILE

cat > .env.example <<'FILE'
DATABASE_URL=postgresql://shop:shop@postgres:5432/shop
REDIS_URL=redis://redis:6379/0
SESSION_SECRET=change-me
PAYMENT_API_URL=https://payments.example.com/v1
PAYMENT_API_KEY=
SMTP_URL=smtp://mail:25
FILE

cat > docker-compose.yml <<'FILE'
services:
  api:
    build: .
    command: uvicorn shop.api.app:app --host 0.0.0.0 --port 8000
    env_file: .env
    ports: ["8000:8000"]
    depends_on: [postgres, redis]
  worker:
    build: .
    command: rq worker --url redis://redis:6379/0
    env_file: .env
    depends_on: [postgres, redis]
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: shop
      POSTGRES_PASSWORD: shop
  redis:
    image: redis:7
FILE

cat > .github/workflows/ci.yml <<'FILE'
name: ci
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install -e . pytest ruff
      - run: ruff check .
      - run: pytest
FILE

cat > deploy/README.md <<'FILE'
# Deploying

Production is one VM running the same docker-compose.yml.

1. ssh to the VM and `git pull`.
2. `docker compose up -d --build`.
3. Apply new files in migrations/ by hand with psql.
FILE

cat > migrations/001_init.sql <<'FILE'
CREATE TABLE products (id serial PRIMARY KEY, name text NOT NULL, price_cents int NOT NULL, stock int NOT NULL);
CREATE TABLE users (id serial PRIMARY KEY, email text UNIQUE NOT NULL, password_hash text NOT NULL, role text NOT NULL DEFAULT 'customer');
CREATE TABLE orders (id serial PRIMARY KEY, user_id int REFERENCES users(id), status text NOT NULL, created_at timestamptz DEFAULT now());
CREATE TABLE order_lines (order_id int REFERENCES orders(id), product_id int REFERENCES products(id), quantity int NOT NULL);
FILE

touch src/shop/__init__.py src/shop/api/__init__.py src/shop/api/routes/__init__.py src/shop/worker/__init__.py

cat > src/shop/db.py <<'FILE'
"""Connection pool shared by the API and the worker."""
import os

from psycopg_pool import ConnectionPool

# One database for catalog, orders and users: single small deployment at launch.
pool = ConnectionPool(os.environ["DATABASE_URL"])
FILE

cat > src/shop/api/app.py <<'FILE'
from fastapi import FastAPI

from shop.api.routes import catalog, orders

app = FastAPI(title="shopfront")
app.include_router(catalog.router)
app.include_router(orders.router)
FILE

cat > src/shop/api/auth.py <<'FILE'
"""Sign-in and signed session cookies."""
import os

from fastapi import Cookie, HTTPException
from itsdangerous import BadSignature, URLSafeTimedSerializer

# Signed cookies: no server-side session store to run.
signer = URLSafeTimedSerializer(os.environ["SESSION_SECRET"])
MAX_AGE = 7 * 24 * 3600


def require_user(session: str = Cookie(None)) -> dict:
    try:
        return signer.loads(session, max_age=MAX_AGE)
    except (BadSignature, TypeError):
        raise HTTPException(status_code=401)


# TODO: rate-limit sign-in attempts.
FILE

cat > src/shop/api/routes/catalog.py <<'FILE'
from fastapi import APIRouter

from shop.db import pool

router = APIRouter()


@router.get("/products")
def list_products():
    # TODO: cache the product list.
    with pool.connection() as conn:
        return conn.execute("SELECT id, name, price_cents FROM products").fetchall()
FILE

cat > src/shop/api/routes/orders.py <<'FILE'
import os

from fastapi import APIRouter, Depends
from redis import Redis
from rq import Queue

from shop.api.auth import require_user
from shop.db import pool

router = APIRouter()
queue = Queue(connection=Redis.from_url(os.environ["REDIS_URL"]))


@router.post("/orders", status_code=202)
def place_order(cart: dict, user: dict = Depends(require_user)):
    with pool.connection() as conn:
        order_id = conn.execute(
            "INSERT INTO orders (user_id, status) VALUES (%s, 'pending_payment') RETURNING id",
            (user["id"],),
        ).fetchone()[0]
    # Capture is async: the provider can take 10 s, checkout must answer in under 1 s.
    queue.enqueue("shop.worker.tasks.capture_payment", order_id)
    return {"order_id": order_id}
FILE

cat > src/shop/payments.py <<'FILE'
import os

import httpx


def capture(order_id: int) -> bool:
    resp = httpx.post(
        f"{os.environ['PAYMENT_API_URL']}/captures",
        json={"order_id": order_id},
        headers={"Authorization": f"Bearer {os.environ['PAYMENT_API_KEY']}"},
        timeout=15,
    )
    return resp.status_code == 200
FILE

cat > src/shop/worker/tasks.py <<'FILE'
from shop.db import pool
from shop.payments import capture


def capture_payment(order_id: int) -> None:
    # FIXME: retry does not send an idempotency key; a timeout after capture can charge twice.
    ok = capture(order_id)
    status = "paid" if ok else "payment_failed"
    with pool.connection() as conn:
        conn.execute("UPDATE orders SET status = %s WHERE id = %s", (status, order_id))
FILE

cat > tests/api/test_orders.py <<'FILE'
def test_place_order_requires_session(client):
    assert client.post("/orders", json={}).status_code == 401
FILE

mkdir -p docs/adr

cat > docs/adr/README.md <<'FILE'
# Architecture decision records

| ID | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-capture-payments-in-worker.md) | Capture payments in a background worker | Accepted | 2025-12-05 |
FILE

cat > docs/adr/0001-capture-payments-in-worker.md <<'FILE'
---
id: ADR-0001
title: Capture payments in a background worker
status: Accepted
status_note: ""
date: 2025-12-05
revised: []
authors: []
deciders: []
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - {term: Capture, definition: Taking the money for an order from the customer's card through the payment provider.}
---

# Capture payments in a background worker

## Context

The payment provider's capture call takes up to 10 seconds. Checkout has to answer in under 1 second.

## Decision

The checkout request writes the order as `pending_payment` and enqueues a capture job. An RQ worker calls the provider and sets the final status.

## Consequences

Customers see `pending_payment` for a few seconds and poll for the result. A failed capture leaves the order in `payment_failed` for staff to follow up.
FILE

cat > docs/GLOSSARY.md <<'FILE'
# Glossary

This file is the shop's current vocabulary. The source column is a citation. Outdated rows are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| Capture | Taking the money for an order from the customer's card through the payment provider. | [ADR-0001](adr/0001-capture-payments-in-worker.md) |
| Pending payment | Order status between checkout and a finished capture. | Predates ADRs |
FILE

git add -A
git commit -qm "feat: initial shop backend"

DOC_COMMIT=$(git rev-parse HEAD)
{
  printf -- '---\n'
  printf 'title: shopfront architecture\n'
  printf 'generator: architecture-md 0.1.0\n'
  printf 'generated: 2026-02-12\n'
  printf 'level: comprehensive\n'
  printf 'repository: none\n'
  printf 'commit: %s\n' "$DOC_COMMIT"
  printf 'commit_short: %s\n' "$(git rev-parse --short "$DOC_COMMIT")"
  printf 'release_version: 0.4.0\n'
  printf -- '---\n\n'
  cat <<'FILE'
# shopfront architecture

## Summary

shopfront is the backend of a small online shop. Customers browse a catalog, sign in and place orders paid by card. It is one Python codebase that runs as two processes: an HTTP API and a background worker.

Core capabilities: catalog browsing, sign-in with signed session cookies, checkout, payment capture in the background. Confirmation emails are inferred from `SMTP_URL` in `.env.example`; no code sends mail yet (gap).

### Key decisions

| Decision | Reason | Impact |
|---|---|---|
| Payment capture runs in the worker, not in the checkout request | The provider can take 10 s and checkout must answer in under 1 s (`src/shop/api/routes/orders.py:21`, [ADR-0001](adr/0001-capture-payments-in-worker.md)) | Orders stay `pending_payment` until the worker captures them |
| One PostgreSQL database for catalog, orders and users | "single small deployment at launch" (`src/shop/db.py:6`) | Catalog reads and checkout writes share one instance |
| Sessions are signed cookies with no server-side store | No session store to run (`src/shop/api/auth.py:7`) | A stolen cookie stays valid until it expires (7 days) |

### Stack at a glance

Python 3.12, FastAPI, RQ (Redis Queue) workers, PostgreSQL 16, Redis 7, Docker Compose.

### Environments

| Environment | Where | Notes |
|---|---|---|
| local | `docker-compose.yml` | All four services in containers |
| production | One VM running the same Compose file | From `deploy/README.md:3`; no IaC in the repo |

## Diagrams

### Level 1: system context

```
  +----------+   HTTPS   +-------------+   HTTPS   +------------------+
  | Customer |---------->|  shopfront  |---------->| Payment provider |
  +----------+           +-------------+           +------------------+
                                |
                                | SMTP
                                v
                         +-------------+
                         | Mail relay  |
                         +-------------+
```

### Level 2: containers

```
  +----------+  HTTPS  +---------+  SQL   +------------+
  | Customer |-------->|   api   |------->| PostgreSQL |
  +----------+         +---------+        +------------+
                            |                   ^
                            | enqueue           | SQL
                            v                   |
                       +---------+  dequeue +--------+
                       |  Redis  |<---------| worker |
                       +---------+          +--------+
                                                |
                                                | HTTPS, SMTP
                                                v
                                  payment provider, mail relay
```

### Level 4: deployment

One VM runs `docker compose up -d` with the four services above (`deploy/README.md:3`). Inferred: no load balancer or TLS termination is defined in the repo; gap: where does HTTPS end?

## Components

### api

Path `src/shop/api/`. FastAPI application serving the catalog, sign-in and checkout.

| File | Role |
|---|---|
| `src/shop/api/app.py` | Creates the app and mounts the routers |
| `src/shop/api/auth.py` | Signed session cookies and the `require_user` dependency |
| `src/shop/api/routes/catalog.py` | Product list |
| `src/shop/api/routes/orders.py` | Checkout: writes the order and enqueues the capture job |
| `src/shop/db.py` | Connection pool shared by api and worker |

> Reason in code, `src/shop/api/routes/orders.py:21`: "Capture is async: the provider can take 10 s, checkout must answer in under 1 s."

Tested by `tests/api/` with pytest.

### worker

Path `src/shop/worker/`. RQ worker that captures payments.

| File | Role |
|---|---|
| `src/shop/worker/tasks.py` | `capture_payment(order_id)` |
| `src/shop/payments.py` | Client for the payment provider's capture endpoint |

> Reason in code, `src/shop/worker/tasks.py:6`: "FIXME: retry does not send an idempotency key; a timeout after capture can charge twice."

No tests for the worker (gap). No task sends mail yet, though the diagrams show the mail relay that `SMTP_URL` points to (inferred).

## Infrastructure and deployment

`docker-compose.yml` defines four services: `api`, `worker`, `postgres`, `redis`. Production runs the same file on one VM (`deploy/README.md:3`). There is no IaC, container registry or health check in the repo.

## CI/CD

`.github/workflows/ci.yml` runs `ruff check` and `pytest` on every push. Deployment is manual: `git pull` and `docker compose up -d --build` on the VM (`deploy/README.md:5`). No rollback is defined.

## Data flows

### Place an order

1. The browser sends `POST /orders` with the `session` cookie (`src/shop/api/routes/orders.py:14`).
2. `require_user` checks the cookie signature and its 7-day age limit; on failure the caller gets `401` (`src/shop/api/auth.py:12`).
3. The route inserts the order with status `pending_payment` (`src/shop/api/routes/orders.py:16`).
4. It enqueues `capture_payment(order_id)` on Redis and returns `202 Accepted` with `{"order_id": ...}` (`src/shop/api/routes/orders.py:22`).
5. The worker posts `{"order_id": ...}` to `PAYMENT_API_URL/captures` with `Authorization: Bearer <PAYMENT_API_KEY>` (`src/shop/payments.py:7`).
6. A `200` sets the order to `paid`; anything else sets `payment_failed` (`src/shop/worker/tasks.py:8`).

Inferred: the customer polls for the final status; no polling route exists yet (gap).

## Security

Authentication: session in a cookie signed with `SESSION_SECRET` (itsdangerous), 7-day expiry (`src/shop/api/auth.py`). Authorization: a `role` column on `users` (`customer` default); no route checks it yet (gap). Secrets come from environment variables (`.env.example`).

| Threat | Status | Where |
|---|---|---|
| Credential stuffing on sign-in | Not mitigated | No rate limit; TODO at `src/shop/api/auth.py:19` |
| Stolen session cookie | Partial | Signed, but no revocation before expiry |
| Double charge on capture retry | Not mitigated | FIXME at `src/shop/worker/tasks.py:6` |
| SQL injection | Mitigated | Parameterized queries in all routes |
| Traffic interception | Partial | Provider calls use HTTPS; TLS for the API is not defined in the repo |

## Configuration

| Variable | Purpose | Required |
|---|---|---|
| `DATABASE_URL` | PostgreSQL connection | Yes |
| `REDIS_URL` | Job queue | Yes |
| `SESSION_SECRET` | Cookie signing key | Yes |
| `PAYMENT_API_URL`, `PAYMENT_API_KEY` | Payment provider | Yes |
| `SMTP_URL` | Mail relay | Yes |

## Observability

No logging configuration, metrics or tracing in the repo (gap: how is the queue length or a failed capture noticed?).

## Data stores

PostgreSQL 16: tables `products`, `users`, `orders`, `order_lines` (`migrations/001_init.sql`). Migrations are plain SQL applied by hand with psql (`deploy/README.md:7`). Redis holds only the RQ queue.

## Technology stack

| Layer | Choice |
|---|---|
| Language | Python 3.12 |
| Web framework | FastAPI |
| Jobs | RQ on Redis 7 |
| Database | PostgreSQL 16 |
| Packaging | Docker Compose |

## Open work

- TODO `src/shop/api/auth.py:19`: rate-limit sign-in attempts.
- FIXME `src/shop/worker/tasks.py:6`: idempotency key on capture retry.
- TODO `src/shop/api/routes/catalog.py:10`: cache the product list.

## Quick reference

| Need | Path or command |
|---|---|
| API entry point | `src/shop/api/app.py` |
| Checkout route | `src/shop/api/routes/orders.py` |
| Worker task | `src/shop/worker/tasks.py` |
| Schema | `migrations/001_init.sql` |
| Run locally | `docker compose up` |
| Tests | `pytest` |

## Related documents

- [ADR index](adr/README.md)
- [Glossary](GLOSSARY.md)
FILE
} > docs/ARCHITECTURE.md

cat > src/shop/api/routes/refunds.py <<'FILE'
from fastapi import APIRouter, Depends

from shop.api.auth import require_user
from shop.db import pool

router = APIRouter()


@router.post("/orders/{order_id}/refund", status_code=202)
def request_refund(order_id: int, user: dict = Depends(require_user)):
    with pool.connection() as conn:
        conn.execute("UPDATE orders SET status = 'refund_requested' WHERE id = %s", (order_id,))
    return {"order_id": order_id}
FILE
git add src/shop/api/routes/refunds.py
git commit -qm "feat: add refund request endpoint"

cat > src/shop/worker/tasks.py <<'FILE'
from shop.db import pool
from shop.payments import capture


def capture_payment(order_id: int) -> None:
    ok = capture(order_id, idempotency_key=f"capture-{order_id}")
    status = "paid" if ok else "payment_failed"
    with pool.connection() as conn:
        conn.execute("UPDATE orders SET status = %s WHERE id = %s", (status, order_id))
FILE
git add src/shop/worker/tasks.py
git commit -qm "fix: send an idempotency key on capture"
