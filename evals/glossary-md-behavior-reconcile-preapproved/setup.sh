#!/usr/bin/env bash
# Fixture: an online shop whose glossary has a duplicate term (Cart, Carts) and
# rows out of order. Every term appears in the code or README, and every ADR
# link resolves, so the duplicate and the order are the only findings.
set -e

git init -q
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

mkdir -p docs/adr src

cat > README.md <<'EOF'
# shop

A small online shop: carts, checkout, orders and fulfillment. Prices are stored
in minor units with an ISO 4217 currency code. Every product variant has its own SKU.
EOF

cat > src/cart.py <<'EOF'
"""Shopping cart: the items a shopper has picked but not yet paid for."""


class Cart:
    def __init__(self) -> None:
        self.lines: list[tuple[str, int]] = []  # (SKU, quantity)

    def add(self, sku: str, quantity: int = 1) -> None:
        self.lines.append((sku, quantity))
EOF

cat > src/checkout.py <<'EOF'
"""Checkout turns a cart into an order once the payment is authorized."""

from cart import Cart


def checkout(cart: Cart, currency_code: str) -> dict:
    return {"lines": cart.lines, "currency": currency_code}
EOF

cat > src/orders.py <<'EOF'
"""Orders are created only after the card issuer authorizes the payment (ADR-0001)."""


def create_order(checkout_result: dict) -> str:
    return "order-1"
EOF

cat > src/fulfillment.py <<'EOF'
"""Fulfillment is handed to an external warehouse (ADR-0002)."""


def request_fulfillment(order_id: str) -> None:
    ...
EOF

cat > docs/adr/README.md <<'EOF'
# Architecture decision records

| ID | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](0001-create-orders-after-payment-authorization.md) | Create orders after payment authorization | Accepted | 2025-11-06 |
| [ADR-0002](0002-ship-through-an-external-warehouse.md) | Ship through an external warehouse | Accepted | 2025-12-24 |
EOF

cat > docs/adr/0001-create-orders-after-payment-authorization.md <<'EOF'
---
id: ADR-0001
title: Create orders after payment authorization
status: Accepted
status_note: ""
date: 2025-11-06
revised: []
authors: [Eval Fixture]
deciders: [Eval Fixture]
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related: []
terms:
  - term: Order
    definition: A purchase whose payment the card issuer has authorized.
---

# ADR-0001: Create orders after payment authorization

Status: Accepted, 2025-11-06

## Context

Orders created before payment left unpaid orders for the warehouse to skip.

## Decision

Checkout creates an order only after the card issuer authorizes the payment.

## Consequences

Every order in src/orders.py has an authorized payment.
EOF

cat > docs/adr/0002-ship-through-an-external-warehouse.md <<'EOF'
---
id: ADR-0002
title: Ship through an external warehouse
status: Accepted
status_note: ""
date: 2025-12-24
revised: []
authors: [Eval Fixture]
deciders: [Eval Fixture]
supersedes: []
supersedes_in_part: []
superseded_by: []
superseded_in_part_by: []
related:
  - {id: ADR-0001, reason: Only authorized orders are sent to the warehouse}
terms:
  - term: Fulfillment
    definition: Picking, packing and shipping the items of an order.
---

# ADR-0002: Ship through an external warehouse

Status: Accepted, 2025-12-24

## Context

Packing orders in-house did not scale past a few hundred orders a day.

## Decision

The shop sends each order to an external warehouse, which picks, packs and ships it.

## Consequences

src/fulfillment.py calls the warehouse API; stock levels come from the warehouse.
EOF

cat > docs/GLOSSARY.md <<'EOF'
# Glossary

This file is the project's current vocabulary: each term has one definition and the source it comes from. The Source column is a citation, not a history. Rows that no longer apply are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| SKU | A code that identifies one sellable product variant. | Convention |
| Fulfillment | Picking, packing and shipping the items of an order. | [ADR-0002](adr/0002-ship-through-an-external-warehouse.md) |
| Cart | The items a shopper has picked but not yet paid for. | Convention |
| Currency code | A three-letter code that identifies a currency. | Standard: ISO 4217 |
| Order | A purchase whose payment the card issuer has authorized. | [ADR-0001](adr/0001-create-orders-after-payment-authorization.md) |
| Checkout | The steps a shopper takes to pay for a cart. | Predates ADRs |
| Carts | The saved list of products a shopper intends to buy. | Convention |
EOF

git add -A
git commit -q -m "docs: add glossary"
