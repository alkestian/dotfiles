# Filling the PR template

The repo's template is the source of truth for structure. Reproduce its headings verbatim — never
substitute a different structure, never add or drop a heading because a section feels empty.

## Trimming

- Drop any "Away Team" switch block at the top. That is for external contributors.
- Replace the JIRA link placeholder (`XXX`, `TICKET-ID`, etc.) with the branch's ticket.

## Scale the body to the diff — shortest that works

**Write the shortest body that does the job, and expand only when the change genuinely earns it.**
The sections below (1-3 sentences, bullets, domain groupings) are the escalation for complex changes,
not the starting point.

**Default assumption: the change is small.** A diff under ~20 changed lines, or one that changes a
single behaviour, gets **one sentence per section**. Not "one or two sentences" — one. Write it, then
cut every clause that isn't load-bearing.

- `Why` — one sentence: the failure or need, and why it matters. Nothing else.
- `What Changed` — one sentence: the mechanism, and the effect. No bullets, no file names, no
  before/after table.

Worked example, a two-line log-level change:

```markdown
## Why

V3 earnings enqueue can fail with `context canceled`, but no action is needed from the Ledger team so
it shouldn't raise an error.

## What Changed

Use `LogWarnOrError` to prevent context cancelled from causing alerts.
```

What that example deliberately omits, and you must omit too: what the caller does next, what the
retry semantics are, which other error classes still log at error level, which paths were touched,
what the change does *not* cover. Every one of those is recoverable from the diff. A reviewer of a
small PR wants to start reading code in the first five seconds.

If you catch yourself writing "so that", "which means", "note that", or a second clause after a dash —
stop and delete from there to the end of the sentence.

## Length

- `What` — a short summary, not an inventory. The diff is already in the PR; a reviewer opening it
  does not need a bullet per file. One or two sentences, or a few bullets at most.
  - Exception: a large changelist earns more detail, because a reviewer needs a map before they can
    start. Give them one by **grouping by subject area** — the domain the change touches (`Bonuses`,
    `Users`, `Pay periods`, `Payments`) with a line per group saying what happened to it. Group by
    layer (`DB`, `gRPC clients`, `fixtures`) only when the change really is layer-shaped rather than
    domain-shaped.
  - Still never a file listing. Five domain groups beat sixty bullets, and the bullets go stale the
    moment anything is rebased.
- `Why` — 1-3 sentences. The constraint or ordering that forced this change, not a restatement of
  what.
- `How to Test` — leave the template's steps as written. Only replace them when the change needs
  genuinely unusual setup. Docs-only and other untestable changes are not an exception.

## Do not add

- Sections the template does not have.
- Caveats, TODOs, follow-up notes, or advice for reviewers that the user did not ask for. If something
  genuinely needs flagging, say it in chat and let the user decide whether it goes in the PR.
- Co-author, `Generated with`, or attribution lines.
