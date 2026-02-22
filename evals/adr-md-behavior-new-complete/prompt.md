---
name: adr-md-behavior-new-complete
description: "A complete decision with pre-approval is written as ADR-0001 with the contract frontmatter, Draft or Proposed, plus an index row. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [adr-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Record this decision for the image-resizing API. Go ahead without asking me anything and use the defaults.

Problem: POST /resize (src/api/resize.js) resizes images inside the request. Large uploads take 20 to 40 seconds, the load balancer times out at 30, and clients retry, which doubles the load. We need this fixed before the mobile app launches next month.

Options:
1. Keep resizing in the request and raise the timeouts to 120 seconds. Simple and no new parts, but a slow resize still ties up a worker and clients still wait.
2. Pre-generate every size at upload time. Reads are instant, but we would store sizes nobody asks for and must know every size in advance.
3. Accept the upload, return 202 with a job id, and resize in a background worker fed by a job queue. Clients poll or get a webhook.

We chose option 3.

Consequences: requests return in under a second and the worker retries failed resizes. On the downside, clients must poll or handle a webhook, and we have to run and monitor a queue and a worker process.
