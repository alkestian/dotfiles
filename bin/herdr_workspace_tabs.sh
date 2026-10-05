#!/usr/bin/env bash
# Set up the current herdr workspace with 3 tabs: code, agent, terminal.
# Usage: herdr_workspace_tabs.sh [workspace-id] [agent-kind]
set -uo pipefail

die() {
    echo "$1"
    read -r -p "press enter to close" _
    exit 1
}

ws_id="${1:-${HERDR_WORKSPACE_ID:-}}"
agent_kind="${2:-claude}"

if [[ -z "$ws_id" ]]; then
    ws_id=$(herdr workspace list | jq -r '.result.workspaces[] | select(.focused==true) | .workspace_id')
fi
[[ -z "$ws_id" ]] && die "no workspace found"

info=$(herdr workspace get "$ws_id") || die "workspace $ws_id not found"
cwd=$(jq -r '.result.workspace.worktree.checkout_path // empty' <<<"$info")
cwd="${cwd:-$PWD}"

tabs=$(herdr tab list --workspace "$ws_id")
if [[ "$(jq -r '.result.tabs | length' <<<"$tabs")" -gt 1 ]]; then
    read -r -p "workspace $ws_id already has multiple tabs. Add anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

pane_for_tab() {
    herdr pane list --workspace "$ws_id" | jq -r --arg t "$1" '.result.panes[] | select(.tab_id==$t) | .pane_id'
}

# Claim the existing first tab as "code" and open the editor.
code_tab=$(jq -r '.result.tabs[0].tab_id' <<<"$tabs")
herdr tab rename "$code_tab" code
herdr pane run "$(pane_for_tab "$code_tab")" nvim .

name=$(git -C "$cwd" branch --show-current 2>/dev/null)
name="${name:-$(basename "$cwd")}"

agent_tab=$(herdr tab create --workspace "$ws_id" --cwd "$cwd" --label agent --focus | jq -r '.result.tab.tab_id')
herdr agent start "$name" --kind "$agent_kind" --pane "$(pane_for_tab "$agent_tab")"

herdr tab create --workspace "$ws_id" --cwd "$cwd" --label terminal --no-focus >/dev/null

herdr tab focus "$code_tab"
