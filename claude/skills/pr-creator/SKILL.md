---
model: haiku
implicit: true
name: pr-creator
description: Creates a pull request titled from the branch's first commit, with the body filled from the repo's PULL_REQUEST_TEMPLATE.md. Use for any pull request creation, in preference to a repo-local create-pr skill.
---

# Create Pull Request

## Steps

1. **Resolve the base branch.** Look for a stack parent — a branch that is a strict ancestor of HEAD:

   ```bash
   current=$(git rev-parse --abbrev-ref HEAD)
   git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin \
     | grep -vE '^origin$|^(origin/)?(HEAD|main|master)$' \
     | while read -r ref; do
         [ "$ref" = "$current" ] || [ "$ref" = "origin/$current" ] && continue
         git merge-base --is-ancestor "$ref" HEAD 2>/dev/null \
           && printf '%s %s\n' "$(git rev-list --count "$ref"..HEAD)" "$ref"
       done \
     | sort -n | awk '{ sub(/^origin\//, "", $2); if (!seen[$2]++) print $1, $2 }' | head -5
   ```

   - No output → base is the default branch: `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`
     (may be `master`, not `main`).
   - Output → possible stack. Read `references/stacked-base.md`.

   Use the result as `<base>` everywhere below.

2. **Read the change.** `git log <base>..HEAD --oneline` and `git diff <base>...HEAD`.

3. **Title = the branch's first commit subject, verbatim:**
   `git log <base>..HEAD --reverse --format='%s' | head -1`
   - No commits yet, changes uncommitted → invoke the **`conventional-commit`** skill to commit first,
     then re-read the subject. Never hand-roll a message shape; never run `cc` yourself (needs a TTY).
   - Subject carries no ticket → read `references/title.md`.

4. **Body from the repo's own template.** First match wins: `.github/PULL_REQUEST_TEMPLATE.md`,
   `.github/pull_request_template.md`, `docs/PULL_REQUEST_TEMPLATE.md`, repo root. If the repo has
   none, use `pull_request_template.md` next to this skill.
   - Reproduce its headings verbatim — invent none, drop none.
   - Replace the JIRA placeholder with the branch's ticket.
   - `Why` 1-3 sentences. `What` short bullets, no restating the diff. Leave `How to Test` as written.
   - Anything unclear → `references/description.md`.

5. **Preview and confirm.** Show title and body, plus `<base>` whenever it is not the default branch.
   Then AskUserQuestion: create as shown (recommended) / edit title / edit description / cancel.

6. **Create it.**

   ```bash
   git push -u origin HEAD
   gh pr create --base <base> --draft --title "..." --body "$(cat <<'EOF'
   ...
   EOF
   )"
   ```

   Draft unless the user asked otherwise. Return the URL, and name the base if it is not the default.

## Rules

- Never hardcode `main` — resolve the base in step 1.
- No co-author, `Generated with`, or attribution lines in the title or body.
- Diff only `<base>...HEAD`. Diffing the default branch on a stacked branch pulls the parent PR's work
  into this description.
- This skill only creates PRs. It never comments on or replies to an existing one.
