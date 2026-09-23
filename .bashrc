if [ -d "$HOME/repos/dotfiles/bin" ]; then
    export PATH="$HOME/repos/dotfiles/bin:$PATH"
fi

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# Source aliases for cross-OS support
if [ -f "$HOME/repos/dotfiles/.exports" ]; then
    source "$HOME/repos/dotfiles/.exports"
fi

if [ -f "$HOME/repos/dotfiles/.aliases" ]; then
    source "$HOME/repos/dotfiles/.aliases"
fi
