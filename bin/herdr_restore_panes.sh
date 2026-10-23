#!/usr/bin/env bash
# After a herdr server restart, relaunch nvim (restoring its persistence.nvim
# session, else opening the cwd) in every "code" tab and resume
# the last claude conversation in every "agent" tab. Only touches panes sitting
# at an idle shell prompt; agent tabs with no saved conversation are skipped.
# --wait: give each pane up to 60s to reach its prompt first, for right after a
# server start when every shell is still initialising at once.
# Usage: herdr_restore_panes.sh [--wait]
set -uo pipefail

wait_secs=0
[[ "${1:-}" == "--wait" ]] && wait_secs=60

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

# `herdr agent start` once, retried while the pane is still starting up: a
# pane can look idle while zsh is still loading, and herdr only accepts it once
# the prompt is up (agent_pane_busy until then). Gives up after 30s.
# Prints the last error. Usage: try_start <name> <kind> <pane> [agent-args...]
try_start() {
    local name=$1 kind=$2 pane=$3 out
    shift 3
    for _ in $(seq 60); do
        out=$(herdr agent start "$name" --kind "$kind" --pane "$pane" ${1:+-- "$@"} 2>&1 </dev/null) && return 0
        [[ "$out" == *agent_pane_busy* ]] || break
        sleep 0.5
    done
    echo "$out"
    return 1
}

# Start an agent named after the branch; herdr names are global, so fall back
# to "<repo>-<branch>" when another repo's worktree already holds that name.
# Usage: start_agent <name> <repo> <kind> <pane> [agent-args...]
start_agent() {
    local name=$1 repo=$2 kind=$3 pane=$4 err
    shift 4
    err=$(try_start "$(agent_name "$name")" "$kind" "$pane" "$@") && return 0
    if [[ "$err" == *agent_name_taken* ]]; then
        err=$(try_start "$(agent_name "$repo-$name")" "$kind" "$pane" "$@") && return 0
    fi
    echo "agent start failed in $pane: $(jq -r '.error.message // .' <<<"$err" 2>/dev/null || echo "$err")"
    return 1
}

idle() {
    local info
    info=$(herdr pane process-info --pane "$1" | jq -c '.result.process_info')
    [[ "$(jq -r '.foreground_processes[].pid' <<<"$info")" == "$(jq -r '.shell_pid' <<<"$info")" ]]
}

# Idle now, or within wait_secs. Logs busy panes so a skip is never silent.
wait_idle() {
    local deadline=$((SECONDS + wait_secs))
    until idle "$1"; do
        if ((SECONDS >= deadline)); then
            echo "busy    $1 $2 (not at a shell prompt, skipped)"
            return 1
        fi
        sleep 1
    done
}

herdr pane list | jq -r '.result.panes[] | [.pane_id, .tab_id, .cwd] | @tsv' |
while IFS=$'\t' read -r pane tab cwd; do
    label=$(jq -r --arg t "$tab" '.[$t] // empty' <<<"$tabs")
    case "$label" in
        code)
            wait_idle "$pane" "$cwd" || continue
            herdr pane run "$pane" "$nvim_cmd" >/dev/null && echo "nvim    $pane $cwd"
            ;;
        agent)
            wait_idle "$pane" "$cwd" || continue
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
