# Choosing a stacked base

The step 1 command lists ancestor branches as `<commits ahead> <branch>`, nearest first. Nearest is
the candidate stack parent. Everything further down is usually an older branch in the same stack, or
noise from long-lived local branches — the counts make that obvious (a real parent is single or low
double digits ahead; `204 cb/PROJ-1234` is not a parent).

## Rule

Use the nearest candidate as the base **only if it has an open PR**:

```bash
gh pr list --head <candidate> --state open
```

- Open PR → that's a real stack. Use it as `<base>`.
- No open PR → stale, abandoned, or already merged. Fall back to the default branch.

Strip any `origin/` prefix before passing it to `gh pr create --base`.

## Say what you did

If a candidate ranked first but you fell back to the default branch, state that in the step 5
preview. Silently picking either way is how a PR ends up diffing 40 files that belong to someone
else's branch.

## Why the base matters more here than usual

The base decides two things at once: what GitHub shows as the diff, and what you describe in the
body. Get it wrong on a stacked branch and the PR claims credit for its parent's changes, and the
review is unreadable. It is also awkward to fix after the fact — changing the base of an open PR
rewrites the conversation's diff and can invalidate approvals.
