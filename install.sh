#!/usr/bin/env bash
# Symlinks this repo's dotfiles/configs into their expected locations.
# Safe to re-run: skips pairs already linked correctly, backs up real files/dirs in the way.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# "repo-relative-path:target-path" pairs
PAIRS="
.zshrc:$HOME/.zshrc
.zshenv:$HOME/.zshenv
.bashrc:$HOME/.bashrc
.bash_env:$HOME/.bash_env
nvim:$HOME/.config/nvim
herdr/config.toml:$HOME/.config/herdr/config.toml
claude/skills/conventional-commit:$HOME/.claude/skills/conventional-commit
claude/skills/pr-creator:$HOME/.claude/skills/pr-creator
"

link_one() {
    src="$REPO_DIR/$1"
    target="$2"

    if [ ! -e "$src" ]; then
        echo "skip: $1 not found in repo"
        return
    fi

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        echo "ok:   $target already linked"
        return
    fi

    if [ -e "$target" ] || [ -L "$target" ]; then
        backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$target" "$backup"
        echo "back: $target -> $backup"
    fi

    mkdir -p "$(dirname "$target")"

    if ln -s "$src" "$target" 2>/dev/null; then
        echo "link: $target -> $src"
    else
        echo "WARN: failed to symlink $target (no symlink support here? try admin shell / enable Developer Mode on Windows)"
    fi
}

echo "$PAIRS" | while IFS=':' read -r rel target; do
    [ -z "$rel" ] && continue
    link_one "$rel" "$target"
done
