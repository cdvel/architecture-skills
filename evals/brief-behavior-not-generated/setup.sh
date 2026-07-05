#!/usr/bin/env bash
# Fixture: online-shop repo with a hand-written ARCHITECTURE.md at the root (no generator field).
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

cat > ARCHITECTURE.md <<'FILE'
---
title: Shopfront architecture notes
author: backend team
updated: 2025-03-02
---

# Architecture notes

The shop backend is a FastAPI app plus an RQ worker. Orders are stored in Postgres; payment capture happens in the worker so checkout stays fast. See docker-compose.yml for the services.

Things to clean up:

- sign-in has no rate limit
- the worker has no tests
FILE

git add -A
git commit -qm "feat: initial shop backend"
