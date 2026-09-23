#!/usr/bin/env bash
# Create a git worktree and open it in herdr with 3 tabs: code, agent, terminal.
# Usage: herdr_worktree_flow.sh <branch> [base-ref] [agent-kind]
set -uo pipefail

die() {
    echo "$1"
    read -r -p "press enter to close" _
    exit 1
}

branch="${1:-}"
base="${2:-}"
agent_kind="${3:-claude}"

repo_root=$(git rev-parse --show-toplevel)
current=$(git -C "$repo_root" branch --show-current)
default_branch=$(git -C "$repo_root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default_branch="${default_branch:-main}"

reuse=""
if [[ -n "$current" && "$current" != "$default_branch" ]]; then
    reuse="$current"
fi

if [[ -z "$branch" ]]; then
    read -r -p "Branch name${reuse:+ [$reuse]}: " branch
    branch="${branch:-$reuse}"
    [[ -z "$branch" ]] && { echo "no branch given, aborting"; exit 1; }
fi

[[ "$branch" != cb/* ]] && branch="cb/$branch"

# Reusing the branch checked out in the main repo (e.g. from the jira-branch
# skill): free it up in the main checkout first so `git worktree add` doesn't
# refuse it as "already checked out".
if [[ "$branch" == "$reuse" ]]; then
    git -C "$repo_root" checkout "$default_branch"
    echo "switched main checkout back to $default_branch to free up $branch"
fi

# Check for a pre-existing worktree/branch before touching anything, since
# `herdr worktree create` fails outright on collision with no recovery option.
listing=$(herdr worktree list --cwd "$repo_root")
existing_path=$(jq -r --arg b "$branch" '.result.worktrees[] | select(.branch==$b) | .path' <<<"$listing" | head -1)
existing_ws=$(jq -r --arg b "$branch" '.result.worktrees[] | select(.branch==$b) | .open_workspace_id // empty' <<<"$listing" | head -1)

if [[ -n "$existing_path" ]]; then
    if [[ -n "$existing_ws" ]]; then
        read -r -p "$branch is already open (workspace $existing_ws). Focus it? [y/N] " ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
            herdr workspace focus "$existing_ws"
        fi
        exit 0
    fi

    read -r -p "worktree for $branch already exists at $existing_path (not open). Overwrite? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || die "cancelled"

    reopened=$(herdr worktree open --path "$existing_path" --no-focus) || die "failed to open existing worktree for removal"
    tmp_ws=$(jq -r '.result.workspace.workspace_id' <<<"$reopened")
    herdr worktree remove --workspace "$tmp_ws" --force || die "failed to remove existing worktree"
    git -C "$repo_root" branch -D "$branch" 2>/dev/null || true
fi

args=(--branch "$branch" --cwd "$repo_root" --label "$branch" --focus)
[[ -n "$base" ]] && args+=(--base "$base")

created=$(herdr worktree create "${args[@]}") || die "worktree create failed: $(jq -r '.error.message // .' <<<"$created")"
ws_id=$(jq -r '.result.workspace.workspace_id' <<<"$created")
wt_path=$(jq -r '.result.worktree.path' <<<"$created")

pane_for_tab() {
    herdr pane list --workspace "$ws_id" | jq -r --arg t "$1" '.result.panes[] | select(.tab_id==$t) | .pane_id'
}

# worktree create opens with one default tab; claim it as "code" and open the editor.
code_tab=$(herdr tab list --workspace "$ws_id" | jq -r '.result.tabs[0].tab_id')
herdr tab rename "$code_tab" code
herdr pane run "$(pane_for_tab "$code_tab")" nvim .

agent_tab=$(herdr tab create --workspace "$ws_id" --cwd "$wt_path" --label agent --focus | jq -r '.result.tab.tab_id')
herdr agent start "$branch" --kind "$agent_kind" --pane "$(pane_for_tab "$agent_tab")"

herdr tab create --workspace "$ws_id" --cwd "$wt_path" --label terminal --no-focus >/dev/null

herdr tab focus "$code_tab"
