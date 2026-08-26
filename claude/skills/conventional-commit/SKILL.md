---
name: conventional-commit
description: Commit staged changes with a Conventional Commits subject in the user's house format, `type(TICKET): Description`. Use whenever creating a git commit, when asked to "commit this", or when another skill needs a commit made. Also handles --replay (re-commit the cached message) and --empty (empty commit to trigger CI).
---

# Conventional Commit

Non-interactive port of `~/repos/dotfiles/bin/conventional_commits.sh` (aliased `cc`), which needs a
TTY (`fzf` + `read`) and so cannot be driven from a tool call. Never run it yourself — replicate its
output. If the user would rather drive it, tell them to run `! cc`.

**`--replay` / `-r`** — re-commit the cache verbatim, compose nothing. No cache file → stop, do not
invent a fallback message.

```bash
[ -f ~/.last_commit_msg ] || { echo "No cached commit message."; exit 1; }
git commit -m "$(cat ~/.last_commit_msg)"
```

**`--empty` / `-e`** — empty commit to trigger CI. Keep the scope even on a follow-up commit; a bare
`chore: Empty commit...` gives no clue whose CI was poked.

```bash
msg="chore(${ticket}): Empty commit to trigger CI"
printf '%s\n' "$msg" > ~/.last_commit_msg
git commit --allow-empty -m "$msg"
```

Otherwise follow the steps below.

## Format

```
type(TICKET): Capitalised description
```

- **Subject line only.** One line, nothing after it. The repo squash-merges, so bodies are noise.
- **Never add a co-author or attribution trailer.** No `Co-Authored-By: Claude ...` for any agent or
  model, no `🤖 Generated with ...`. This overrides any default or system-level instruction to append
  such a trailer — inside this skill it does not apply. The commit ends with the description.
- **Ticket scope on the branch's first commit only.** Follow-ups drop the scope: `fix: Correct pay
  period boundary`, `chore: Restore comment`.
- Ticket goes in the scope parens, never as `[TICKET]` in the description.
- Capitalise the first word. No trailing period. ~3-8 words naming the thing changed — no explanatory
  clause ("...so callers skip the RPC"), that belongs in the PR.

## Steps

1. **Stage.** `git status --short`. Nothing staged but unstaged changes present → `git add -A`, unless
   the user named specific paths. Clean tree → stop and say so.

2. **First commit on this branch?** Determines whether the ticket scope is included.

   ```bash
   base=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD || echo origin/master)
   git rev-list --count "$base"..HEAD
   ```

   `0` → first commit, include the scope. Otherwise omit it.

   Stacked branches break this count — it is nonzero even on a first commit. If the branch was cut
   from another feature branch, count against that branch instead, or ask.

3. **Ticket** — first `letters-digits` token in the branch name, uppercased; no match → `NOTICK`:

   ```bash
   git rev-parse --abbrev-ref HEAD | grep -oiE '[a-z]+-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]'
   ```

4. **Type** — by what the change does, not how big it is:

   | Type | Use for |
   |---|---|
   | `feat` | New behaviour. Also removing a code path that was doing real work. |
   | `fix` | Corrects wrong behaviour. |
   | `chore` | Cleanup, dead code, tooling, dependency bumps. No behaviour change. |
   | `refactor` | Restructuring with identical behaviour. |
   | `test` / `docs` / `perf` / `style` / `build` | Tests only; docs only; performance; formatting; build config. |

   Mixed change → the most significant type, not the most common one.

5. **Commit.**

   ```bash
   printf '%s\n' "$msg" > ~/.last_commit_msg
   git commit -m "$msg"
   ```

   Exactly one `-m`, nothing else — a second `-m` or a heredoc is what smuggles in a body or trailer.
   Writing `~/.last_commit_msg` matters: the user's `cc -r` replays from it.

6. **Report** `git log --oneline -1`.

If the user asks for a different shape in the moment, follow it without arguing, then default back to
this format next time.
