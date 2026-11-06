---
name: herdr
description: Open a herdr worktree or workspace for a ticket or repo, or close one, by running the user's herdr_*.sh scripts. Use when the user asks to "open a worktree for LEDGR-123", "start a workspace for <repo>", "spin up <ticket> in <repo>", "close that worktree", or mentions the herdr prefix+u / prefix+shift+i / prefix+shift+u bindings.
---

# herdr

The scripts live in `~/repos/dotfiles/bin` and are on `PATH`. Never press keys; call the scripts.
stdin is not a TTY, so any y/N prompt falls back to N (cancel). Report that rather than retrying.

| Want | Command | Binding |
|---|---|---|
| Worktree + branch for a ticket | `cd ~/repos/<repo> && herdr_worktree_flow.sh [--prompt "<text>"] <KEY> [base-ref] [agent]` | prefix+u |
| Repo on its default branch | `herdr_workspace_flow.sh <repo> [agent]` | prefix+shift+i |
| Add tabs to a workspace | `herdr_workspace_tabs.sh <ws-id> [agent]` | prefix+i |
| Remove a worktree | `herdr_worktree_close.sh <ws-id>` | prefix+shift+u |

## Worktree

1. **Repo.** The user names it, or infer it from the ticket (a ticket for event-bus goes in
   `~/repos/event-bus`, not the current repo). Ask if unclear. Run from any checkout of that repo;
   the script resolves the main checkout itself.
2. **Branch.** Pass the bare key (`LEDGR-6873`); the script adds `cb/`.
3. **Prompt (optional).** The text becomes the new agent's first message.
   - If the `ledger:ticket` skill is available in this session and the key is a LEDGR ticket, pass
     `--prompt "Use the ledger:ticket skill to fetch <KEY>, then plan the change. Do not edit yet."`
   - Otherwise pass whatever context the user gave (a ticket summary, a task description), or omit
     `--prompt` for an empty agent. Never assume `/ledger` exists.
4. **Verify** after it returns:
   `herdr worktree list --cwd ~/repos/<repo> | jq -r '.result.worktrees[] | select(.branch=="cb/<KEY>")'`
   shows the path and an `open_workspace_id`. Report path, branch and workspace ID.

## Close

`herdr_worktree_close.sh` with no argument removes the **focused** worktree, which may not be the one
meant. Always pass an explicit workspace ID from `herdr worktree list`, and confirm with the user
first: it deletes the checkout and its local branch.
