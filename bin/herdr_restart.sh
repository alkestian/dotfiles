#!/usr/bin/env bash
# Restart herdr from scratch: quit nvim cleanly (so persistence.nvim saves its
# sessions), stop the server, relaunch herdr (fresh config + fresh shells), then
# reopen nvim and claude in every code/agent tab via herdr_restore_panes.sh.
# If the server is already down, skips straight to relaunch + restore.
# Must run outside herdr, since stopping the server kills every pane in it.
# Usage: herdr_restart.sh
set -uo pipefail

if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "run this from a terminal outside herdr: detach first, then run it again"
    exit 1
fi

state_dir="$HOME/.config/herdr"

# `herdr status server` exits 0 either way, so read the status line instead.
server_running() {
    herdr status server 2>/dev/null | grep -q '^status: running'
}

launch_and_restore() {
    # The herdr client below owns the terminal, so restore panes from a background
    # job once the new server is answering and its shells have had time to start.
    (
        until herdr pane list >/dev/null 2>&1; do sleep 0.5; done
        sleep 3
        herdr_restore_panes.sh
    ) >"$state_dir/restore.log" 2>&1 &

    exec herdr
}

# Server already down (crash, manual stop): nothing to quit, just relaunch.
if ! server_running; then
    echo "herdr server not running, starting it and restoring panes"
    launch_and_restore
fi

cp "$state_dir/session.json" "$state_dir/session.json.bak-$(date +%Y%m%d-%H%M%S)"

working=$(herdr pane list | jq -r '.result.panes[] | select(.agent_status=="working") | "\(.pane_id) (\(.agent))"')
if [[ -n "$working" ]]; then
    echo "agents still working:"
    echo "$working"
    read -r -p "stop them mid-turn anyway? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || exit 0
fi

nvim_panes() {
    for pane in $(herdr pane list | jq -r '.result.panes[].pane_id'); do
        herdr pane process-info --pane "$pane" |
            jq -e '.result.process_info.foreground_processes[] | select(.name=="nvim")' >/dev/null && echo "$pane"
    done
}

# RPC socket of the nvim in a pane. The foreground pid is the TUI; the socket is
# named after its `--embed` child, so check both.
nvim_socket() {
    local tui pid sock
    tui=$(herdr pane process-info --pane "$1" |
        jq -r '.result.process_info.foreground_processes[] | select(.name=="nvim") | .pid' | head -1)
    for pid in $tui $(pgrep -P "$tui"); do
        for sock in "${TMPDIR%/}/nvim.$USER"/*/"nvim.$pid.0"; do
            [[ -S "$sock" ]] && { echo "$sock"; return; }
        done
    done
}

# Quit over RPC rather than typing into the pane: keystrokes sent as separate
# esc/":qa" writes can land as text in insert mode. <C-\><C-N> reaches normal
# mode from any mode, and :qa still refuses to drop unsaved changes.
for pane in $(nvim_panes); do
    sock=$(nvim_socket "$pane")
    if [[ -z "$sock" ]]; then
        echo "no nvim socket for $pane, skipping"
        continue
    fi
    nvim --server "$sock" --remote-send '<C-\><C-N>:qa<CR>' 2>/dev/null
done
sleep 2

left=$(nvim_panes)
if [[ -n "$left" ]]; then
    echo "nvim did not quit in (unsaved changes?):" $left
    echo "save or discard them and run this again"
    exit 1
fi

herdr server stop >/dev/null
for _ in $(seq 60); do
    server_running || break
    sleep 0.5
done
server_running && { echo "server still running after 30s, giving up"; exit 1; }

launch_and_restore
