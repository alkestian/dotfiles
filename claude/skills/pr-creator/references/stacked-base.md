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

## Link the stack

Setting `--base` to the parent's branch only bases one PR on another. A stacked PR means GitHub's
native stack, made with the `gh stack` extension (`gh extension list` shows `github/gh-stack`). If it
is missing, say so and stop; do not report the PRs as stacked.

After `gh pr create`, link bottom to top, starting from the PR nearest the default branch:

```bash
gh stack link <parent-PR> <new-PR>
```

- If the parent is already in a stack, `gh stack link` adds the new PR to the top of it; existing
  PRs are never removed.
- It keeps each PR's base and draft state.
- Confirm with `gh stack view --short` and report "stack #N". Undo with `gh stack unstack`.

## Stack tracker

The team's PR summary bot lists titles only. Stacked PRs share a ticket id, so a position suffix is
the only way a reader can tell the order to review them in. Offered at step 6 when the PR is part of
a stack, which is any of:

- `<base>` is a stack parent.
- The user said it is stacked (e.g. "stack", "1 of 3", "first of the stack").
- It is the bottom of a stack: child branches descend from HEAD and are not merged into the default
  branch. Detect them with:

  ```bash
  git for-each-ref --format='%(refname:short)' refs/heads \
    | while read -r ref; do
        [ "$ref" = "$current" ] && continue
        git merge-base --is-ancestor "$ref" "$default" 2>/dev/null && continue
        git merge-base --is-ancestor HEAD "$ref" 2>/dev/null && echo "$ref"
      done
  ```

  Descendants that are not in one chain (siblings) are not a stack. Count only the longest chain.

- Format: suffix, `type(TICKET): Description (2/3)`. Suffix keeps the conventional-commit prefix
  parseable. Do not touch the commit subject; edit the PR title only.
- Position = number of PRs from the bottom of the stack to the new PR, inclusive. Count by walking
  `gh pr list --head <base> --state open --json baseRefName` down until the base is the default
  branch. The bottom PR is `1`.
- Total = the user's planned size if they give one (via "Other"), else the length of the chain of
  child branches above plus this PR, else the current depth, so the top PR reads `(2/2)`.
- The question comes after the step 5 preview, so the preview title has no tracker. Apply the suffix
  to `--title` in step 7 and state the final title when reporting the URL.
- Squash merge uses the PR title, so the suffix lands in the merged commit. Tell the user to strip it
  at merge.
- Never retitle other PRs in the stack on your own. If the total changed, say which PRs now have a
  stale count and offer to run `gh pr edit --title` on them.
