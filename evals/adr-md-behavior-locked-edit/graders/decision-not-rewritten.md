---
type: regex
pattern: 'We will store orders[^\n]*document database'
match: not_contains
target: {source: file, path: docs/adr/0001-use-relational-database-for-orders.md}
---
