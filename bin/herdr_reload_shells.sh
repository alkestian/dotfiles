#!/usr/bin/env bash
# Reload the herdr config, then reload zsh in every herdr pane that is sitting
# at an idle shell prompt. Panes running something else (nvim, agents, servers)
# are skipped and listed.
# Usage: herdr_reload_shells.sh
set -uo pipefail

herdr server reload-config >/dev/null && echo "reloaded herdr config"

reloaded=0
skipped=()

for pane in $(herdr pane list | jq -r '.result.panes[].pane_id'); do
    info=$(herdr pane process-info --pane "$pane" | jq -c '.result.process_info')
    shell_pid=$(jq -r '.shell_pid' <<<"$info")
    fg_pids=$(jq -r '.foreground_processes[].pid' <<<"$info")

    if [[ "$fg_pids" == "$shell_pid" ]]; then
        herdr pane run "$pane" "exec zsh" >/dev/null
        reloaded=$((reloaded + 1))
    else
        skipped+=("$pane ($(jq -r '.foreground_processes[0].name' <<<"$info"))")
    fi
done

echo "reloaded $reloaded pane(s)"
if ((${#skipped[@]})); then
    echo "skipped (busy): ${skipped[*]}"
    echo "restart those by hand (exec zsh) once they are idle"
fi
