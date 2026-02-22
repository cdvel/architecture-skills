---
name: adr-md-behavior-supersede
description: "Superseding an Accepted ADR writes a new Draft or Proposed record listing it in supersedes; the old record is unchanged until accept. Run with --scaffold and --allow-tools Write Edit Bash."
tags: [adr-md, behavior]
plugins: ["../.."]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

ADR-0002 no longer fits and we're replacing it fully: order confirmation emails will be sent by a queue consumer as soon as an order is placed, instead of the nightly cron job. Go ahead without asking me.

Why: the cron job (src/jobs/confirmation-cron.js) delays emails by up to a day, and one failed run loses a whole day's emails.

Options we weighed: run the cron job every minute instead of nightly; call the email provider directly in the checkout request; publish an order placed event to a queue and send emails from a consumer. We chose the queue consumer.

Consequences: emails go out within a minute and failed sends are retried. But we now run a queue, and emails can be sent twice unless the consumer is idempotent.
