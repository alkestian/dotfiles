#!/usr/bin/env bash
# After a herdr server restart, relaunch nvim (restoring its persistence.nvim
# session, else opening the cwd) in every "code" tab and resume
# the last claude conversation in every "agent" tab. Only touches panes sitting
# at an idle shell prompt; agent tabs with no saved conversation are skipped.
# Usage: herdr_restore_panes.sh
set -uo pipefail

# Load the persistence.nvim session for the cwd (branch-specific first, then
# branchless, same as persistence.load()), falling back to the cwd itself.
nvim_cmd="nvim -c \"lua local p = require('persistence') if vim.fn.filereadable(p.current()) + vim.fn.filereadable(p.current({ branch = false })) > 0 then p.load() else vim.cmd('edit .') end\""

tabs=$(herdr tab list | jq -c '[.result.tabs[] | {(.tab_id): .label}] | add')

# herdr agent names: lowercase letter first, then [a-z0-9_-], max 32 chars.
agent_name() {
    local n
    n=$(tr "[:upper:]" "[:lower:]" <<<"$1" | sed -E "s/[^a-z0-9_-]+/-/g; s/^[^a-z]+//")
    n="${n:0:32}"
    echo "${n:-agent}"
}

# Start an agent named after the branch; herdr names are global, so fall back
# to "<repo>-<branch>" when another repo's worktree already holds that name.
# Usage: start_agent <name> <repo> <kind> <pane> [agent-args...]
start_agent() {
    local name=$1 repo=$2 kind=$3 pane=$4
    shift 4
    herdr agent start "$(agent_name "$name")" --kind "$kind" --pane "$pane" ${1:+-- "$@"} >/dev/null 2>&1 </dev/null \
        || herdr agent start "$(agent_name "$repo-$name")" --kind "$kind" --pane "$pane" ${1:+-- "$@"} </dev/null
}

idle() {
    local info
    info=$(herdr pane process-info --pane "$1" | jq -c '.result.process_info')
    [[ "$(jq -r '.foreground_processes[].pid' <<<"$info")" == "$(jq -r '.shell_pid' <<<"$info")" ]]
}

herdr pane list | jq -r '.result.panes[] | [.pane_id, .tab_id, .cwd] | @tsv' |
while IFS=$'\t' read -r pane tab cwd; do
    label=$(jq -r --arg t "$tab" '.[$t] // empty' <<<"$tabs")
    case "$label" in
        code)
            idle "$pane" || continue
            herdr pane run "$pane" "$nvim_cmd" >/dev/null && echo "nvim    $pane $cwd"
            ;;
        agent)
            idle "$pane" || continue
            # Claude stores conversations per cwd, with / and . replaced by -.
            project_dir="$HOME/.claude/projects/$(sed 's|[/.]|-|g' <<<"$cwd")"
            if ! compgen -G "$project_dir/*.jsonl" >/dev/null; then
                echo "skip    $pane $cwd (no saved conversation)"
                continue
            fi
            name=$(git -C "$cwd" branch --show-current 2>/dev/null)
            start_agent "${name:-$(basename "$cwd")}" "$(basename "$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)")" claude "$pane" --continue >/dev/null \
                && echo "claude  $pane $cwd" || echo "failed  $pane $cwd"
            ;;
    esac
done
