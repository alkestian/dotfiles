#!/usr/bin/env bash
# Installs mise, neovim, and herdr if missing. Idempotent, safe to re-run.
# macOS/Linux/WSL go through mise. Native Windows (Git Bash/MSYS) shells out
# to winget/powershell since mise's unix installer and herdr's mise registry
# entry don't cover that platform.
set -uo pipefail

os_kind() {
    case "$(uname -s)" in
        Darwin) echo mac ;;
        Linux) echo linux ;;
        MINGW*|MSYS*|CYGWIN*) echo windows ;;
        *) echo unknown ;;
    esac
}

kind=$(os_kind)
[[ "$kind" == unknown ]] && { echo "unrecognized OS, skipping"; exit 1; }

ensure_mise() {
    command -v mise >/dev/null 2>&1 && return
    case "$kind" in
        mac|linux)
            curl -fsSL https://mise.run | sh
            export PATH="$HOME/.local/bin:$PATH"
            ;;
        windows)
            winget.exe install -e --id jdx.mise
            ;;
    esac
}

ensure_neovim() {
    command -v nvim >/dev/null 2>&1 && return
    case "$kind" in
        mac|linux) mise use -g neovim ;;
        windows) winget.exe install -e --id Neovim.Neovim ;;
    esac
}

ensure_herdr() {
    command -v herdr >/dev/null 2>&1 && return
    case "$kind" in
        mac|linux)
            mise use -g herdr 2>/dev/null \
                || mise use -g github:herdrdev/herdr 2>/dev/null \
                || curl -fsSL https://herdr.dev/install.sh | sh
            ;;
        windows)
            powershell.exe -ExecutionPolicy Bypass -Command "irm https://herdr.dev/install.ps1 | iex"
            ;;
    esac
}

ensure_mise
ensure_neovim
ensure_herdr
