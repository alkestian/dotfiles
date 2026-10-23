#!/usr/bin/env bash
# Open a repo on its default branch in a new herdr workspace with 3 tabs:
# code, agent, terminal. No worktree, no new branch.
# Usage: herdr_workspace_flow.sh [repo-path-or-name] [agent-kind]
set -uo pipefail

die() {
    echo "$1"
    read -r -p "press enter to close" _
    exit 1
}

target="${1:-}"
agent_kind="${2:-claude}"

here=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$target" ]]; then
    read -r -p "Repo path or name${here:+ [$here]}: " target
    target="${target:-$here}"
    [[ -z "$target" ]] && { echo "no repo given, aborting"; exit 1; }
fi

# A bare name like "ledger" means ~/repos/ledger.
[[ "$target" != */* && ! -d "$target" ]] && target="$HOME/repos/$target"
repo_root=$(git -C "$target" rev-parse --show-toplevel 2>/dev/null) || die "$target is not a git repo"
repo_name=$(basename "$repo_root")

# One workspace per checkout: focus the existing one rather than open a second.
# herdr fills in worktree info lazily, so also match a workspace labelled with
# the repo name that has a pane sitting in the checkout.
existing_ws=$(herdr workspace list | jq -r --arg p "$repo_root" \
    '.result.workspaces[] | select(.worktree.checkout_path==$p) | .workspace_id' | head -1)
if [[ -z "$existing_ws" ]]; then
    for ws in $(herdr workspace list | jq -r --arg l "$repo_name" '.result.workspaces[] | select(.label==$l) | .workspace_id'); do
        herdr pane list --workspace "$ws" | jq -e --arg p "$repo_root" 'any(.result.panes[]; .cwd==$p)' >/dev/null \
            && { existing_ws=$ws; break; }
    done
fi
if [[ -n "$existing_ws" ]]; then
    read -r -p "$repo_name is already open (workspace $existing_ws). Focus it? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] && herdr workspace focus "$existing_ws"
    exit 0
fi

default_branch=$(git -C "$repo_root" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@')
default_branch="${default_branch:-main}"
current=$(git -C "$repo_root" branch --show-current)

if [[ "$current" != "$default_branch" ]]; then
    read -r -p "$repo_name is on ${current:-a detached HEAD}, not $default_branch. Switch to $default_branch? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        git -C "$repo_root" checkout "$default_branch" || die "checkout failed (uncommitted changes?)"
    fi
fi

# Bring the base branch up to date, like the worktree flow does for its base.
if [[ "$(git -C "$repo_root" branch --show-current)" == "$default_branch" ]]; then
    git -C "$repo_root" pull --ff-only --quiet origin "$default_branch" 2>/dev/null \
        || echo "could not fast-forward $default_branch from origin, opening it as-is"
fi

command -v mise >/dev/null 2>&1 && mise trust "$repo_root" --yes --quiet 2>/dev/null

created=$(herdr workspace create --cwd "$repo_root" --label "$repo_name" --focus) \
    || die "workspace create failed: $(jq -r '.error.message // .' <<<"$created")"
ws_id=$(jq -r '.result.workspace.workspace_id' <<<"$created")
code_tab=$(jq -r '.result.tab.tab_id' <<<"$created")
code_pane=$(jq -r '.result.root_pane.pane_id' <<<"$created")

# herdr agent names: lowercase letter first, then [a-z0-9_-], max 32 chars.
agent_name() {
    local n
    n=$(tr "[:upper:]" "[:lower:]" <<<"$1" | sed -E "s/[^a-z0-9_-]+/-/g; s/^[^a-z]+//")
    n="${n:0:32}"
    echo "${n:-agent}"
}

# A fresh tab's shell takes a moment to reach its prompt, and `herdr agent
# start` refuses a pane that isn't at one. Wait up to 30s.
wait_for_shell() {
    local info
    for _ in $(seq 60); do
        info=$(herdr pane process-info --pane "$1" | jq -c '.result.process_info')
        [[ "$(jq -r '.foreground_processes[].pid' <<<"$info")" == "$(jq -r '.shell_pid' <<<"$info")" ]] && return 0
        sleep 0.5
    done
    return 1
}

pane_for_tab() {
    herdr pane list --workspace "$ws_id" | jq -r --arg t "$1" '.result.panes[] | select(.tab_id==$t) | .pane_id'
}

# workspace create opens with one default tab; claim it as "code" and open the editor.
herdr tab rename "$code_tab" code >/dev/null
herdr pane run "$code_pane" nvim .

# Base-branch workspaces are named after the repo, since "main" clashes across repos.
agent_tab=$(herdr tab create --workspace "$ws_id" --cwd "$repo_root" --label agent --focus | jq -r '.result.tab.tab_id')
agent_pane=$(pane_for_tab "$agent_tab")
wait_for_shell "$agent_pane" || echo "agent tab shell not ready after 30s, trying anyway"
herdr agent start "$(agent_name "$repo_name")" --kind "$agent_kind" --pane "$agent_pane" >/dev/null </dev/null \
    || echo "agent start failed in $agent_pane"

herdr tab create --workspace "$ws_id" --cwd "$repo_root" --label terminal --no-focus >/dev/null

herdr tab focus "$code_tab" >/dev/null
