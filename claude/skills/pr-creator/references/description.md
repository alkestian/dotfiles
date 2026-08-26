# Filling the PR template

The repo's template is the source of truth for structure. Reproduce its headings verbatim — never
substitute a different structure, never add or drop a heading because a section feels empty.

## Trimming

- Drop any "Away Team" switch block at the top. That is for external contributors.
- Replace the JIRA link placeholder (`XXX`, `TICKET-ID`, etc.) with the branch's ticket.

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
