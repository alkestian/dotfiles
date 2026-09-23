#!/usr/bin/env bash
# Remove the focused worktree checkout and delete its local branch.
# Usage: herdr_worktree_close.sh [workspace-id]
set -uo pipefail

ws_id="${1:-}"
if [[ -z "$ws_id" ]]; then
    ws_id=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused==true) | .workspace_id')
fi

info=$(herdr worktree list --workspace "$ws_id")
branch=$(jq -r --arg ws "$ws_id" '.result.worktrees[] | select(.open_workspace_id==$ws) | .branch' <<<"$info")
repo_root=$(jq -r '.result.source.repo_root' <<<"$info")

if ! herdr worktree remove --workspace "$ws_id"; then
    echo "failed to remove worktree (uncommitted or unmerged changes?)."
    read -r -p "press enter to close" _
    exit 1
fi

if [[ -n "$branch" && "$branch" != "null" ]]; then
    git -C "$repo_root" branch -D "$branch"
    echo "removed worktree and deleted branch $branch"
fi
