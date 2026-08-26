# Composing a title when the commit subject has no ticket

Prefer the existing subject. Only compose when the branch's first commit subject carries no ticket at
all, or the branch has no commits reachable from the base.

## Legacy shapes

If the subject already matches `type: [TICKET] Description` — the old `conventional_commits.sh`
output — reuse it verbatim. Do not reformat someone's existing commit to the current style.

## Composing

Follow the `conventional-commit` skill's format: `type(TICKET): Capitalised description`

- Ticket: from the branch name, uppercased. None → `NOTICK`.
- Description: under 60 characters, what changed not how, no trailing period.

## Picking the type

The `conventional-commit` skill owns the type table — use it rather than a second copy that can drift.
