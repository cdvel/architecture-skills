#!/usr/bin/env bash
set -e
git init -q
git config user.name "Test Author"
git config user.email "test@example.com"
mkdir -p docs/adr src/orders src/jobs src/cart
cat > package.json <<'SRC'
{ "name": "online-shop", "version": "1.4.0", "dependencies": { "express": "^4.19.0", "pg": "^8.11.0" } }
SRC
cat > src/orders/repository.js <<'SRC'
const { Pool } = require('pg');
const pool = new Pool();

async function insertOrder(cart) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query('INSERT INTO orders (customer_id) VALUES ($1) RETURNING id', [cart.customerId]);
    for (const line of cart.lines) {
      await client.query('INSERT INTO order_lines (order_id, sku, qty) VALUES ($1, $2, $3)', [rows[0].id, line.sku, line.qty]);
    }
    await client.query('COMMIT');
    return rows[0].id;
  } finally {
    client.release();
  }
}

module.exports = { insertOrder };
SRC
cat > src/orders/service.js <<'SRC'
const repo = require('./repository');

async function placeOrder(cart) {
  return repo.insertOrder(cart);
}

module.exports = { placeOrder };
SRC
cat > src/jobs/confirmation-cron.js <<'SRC'
// Runs at 02:00 and sends one batch of confirmation emails for the previous day's orders.
const email = require('../email/client');
const db = require('../orders/repository');

async function run() {
  const orders = await db.ordersPlacedYesterday();
  await email.sendBatch(orders.map((o) => ({ to: o.email, template: 'order-confirmation', data: o })));
}

module.exports = { run };
SRC
cat > src/cart/session.js <<'SRC'
// Cart sessions live in this process; they are lost on restart and not shared between instances.
const sessions = new Map();

function getCart(sessionId) {
  return sessions.get(sessionId) || { lines: [] };
}

function saveCart(sessionId, cart) {
  sessions.set(sessionId, cart);
}

module.exports = { getCart, saveCart };
SRC
cat > docs/adr/0001-use-relational-database-for-orders.md <<'ADR'
---
id: ADR-0001
title: Use a relational database for orders
status: Accepted
status_note: ""
date: 2026-01-03
revised: []
authors: [Test Author]
deciders: [Shop team]
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - {term: Order, definition: A confirmed purchase of one or more items by one customer.}
---

# ADR-0001: Use a relational database for orders

**Status:** Accepted · **Date:** 2026-01-03

## Context

Orders and their line items must be written together or not at all (`src/orders/repository.js`). The shop has one operations person, who already runs a relational database for the catalog.

## Options considered

### Relational database (chosen)

Transactions across orders and line items, mature tooling, and the team already runs one.

### Document database

Documents fit an order with nested lines and avoid joins. Rejected because multi-document transactions were new to the team and reporting relies on SQL.

## Decision

We will store orders and order lines in a relational database, accessed only through `src/orders/repository.js`.

## Consequences

### Positive

- Orders and lines are written in one transaction.

### Negative

- Every schema change needs a migration.

## References

- `src/orders/repository.js`
ADR
cat > docs/adr/0002-send-order-emails-from-nightly-cron.md <<'ADR'
---
id: ADR-0002
title: Send order confirmation emails from a nightly cron job
status: Accepted
status_note: ""
date: 2026-01-10
revised: []
authors: [Test Author]
deciders: [Shop team]
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - {term: Nightly batch, definition: The orders whose confirmation emails the nightly job sends together.}
---

# ADR-0002: Send order confirmation emails from a nightly cron job

**Status:** Accepted · **Date:** 2026-01-10

## Context

The email provider charges per API call and offers a batch endpoint. Order volume is low (`src/orders/service.js`).

## Options considered

### Nightly cron job (chosen)

One batch call per day keeps provider costs low and needs no new infrastructure.

### Send from the checkout request

Customers get the email at once. Rejected because checkout would fail whenever the provider is down.

## Decision

We will send order confirmation emails from a nightly cron job (`src/jobs/confirmation-cron.js`) that batches the day's orders.

## Consequences

### Positive

- One provider call per day.

### Negative

- Customers wait up to a day for their confirmation.

## References

- `src/jobs/confirmation-cron.js`
ADR
cat > docs/adr/README.md <<'IDX'
# Architecture decision records

Why the system has its current shape, one decision per record.

| ADR | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-use-relational-database-for-orders.md) | Use a relational database for orders | Accepted | 2026-01-03 |
| [ADR-0002](0002-send-order-emails-from-nightly-cron.md) | Send order confirmation emails from a nightly cron job | Accepted | 2026-01-10 |
IDX
git add -A
git commit -qm "chore: initial commit"
