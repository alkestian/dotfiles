#!/usr/bin/env bash
# Restart herdr from scratch: quit nvim cleanly (so persistence.nvim saves its
# sessions), stop the server, relaunch herdr (fresh config + fresh shells), then
# reopen nvim and claude in every code/agent tab via herdr_restore_panes.sh.
# Must run outside herdr, since stopping the server kills every pane in it.
# Usage: herdr_restart.sh
set -uo pipefail

if [[ -n "${HERDR_ENV:-}" ]]; then
    echo "run this from a terminal outside herdr: detach first, then run it again"
    exit 1
fi

if ! herdr status server >/dev/null 2>&1; then
    echo "herdr server not running, starting fresh"
    exec herdr
fi

state_dir="$HOME/.config/herdr"
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

for pane in $(nvim_panes); do
    herdr pane send-keys "$pane" esc >/dev/null
    herdr pane run "$pane" ":qa" >/dev/null
done
sleep 2

left=$(nvim_panes)
if [[ -n "$left" ]]; then
    echo "nvim did not quit in (unsaved changes?):" $left
    echo "save or discard them and run this again"
    exit 1
fi

herdr server stop >/dev/null
while herdr status server >/dev/null 2>&1; do sleep 0.5; done

# The herdr client below owns the terminal, so restore panes from a background
# job once the new server is answering and its shells have had time to start.
(
    until herdr pane list >/dev/null 2>&1; do sleep 0.5; done
    sleep 3
    herdr_restore_panes.sh
) >"$state_dir/restore.log" 2>&1 &

exec herdr
