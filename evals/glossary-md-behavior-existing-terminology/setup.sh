#!/usr/bin/env bash
# Fixture: a payments service whose vocabulary already lives in docs/TERMINOLOGY.md.
set -e

git init -q
git config user.name "Eval Fixture"
git config user.email "fixture@example.com"

mkdir -p docs src

cat > README.md <<'EOF'
# payments

Takes card payments for the shop, captures them, and handles refunds and chargebacks.
See docs/TERMINOLOGY.md for the terms we use.
EOF

cat > docs/TERMINOLOGY.md <<'EOF'
# Terminology

The terms the payments service uses, each with one definition and where it comes from. The Source column is a citation. Rows that no longer apply are removed, not marked.

| Term | Definition | Source |
|---|---|---|
| PAN | The primary account number printed on a payment card. | Standard: ISO/IEC 7812 |
| Capture | The request that turns an authorized payment into a charge. | Convention |
EOF

cat > src/payments.py <<'EOF'
"""Payment lifecycle: authorize, capture, refund."""


def capture(payment_id: str) -> None:
    ...


def refund(payment_id: str, amount_minor: int) -> None:
    ...


def record_chargeback(payment_id: str, reason_code: str) -> None:
    ...
EOF

git add -A
git commit -q -m "chore: initial commit"
