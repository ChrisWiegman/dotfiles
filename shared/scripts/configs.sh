#!/bin/sh

set -e
trap 'echo "configs.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

echo "Setting up shared config files"

. "$SHAREDPATH/scripts/lib.sh"

CONFIG_DIR="$SHAREDPATH/configs"

# Set up SSH config
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi
chmod 0700 "$HOME/.ssh"

link_config "$CONFIG_DIR/.ssh/config" "$HOME/.ssh/config"
chmod 0600 "$HOME/.ssh/config"

# Set up Tmux configs
link_config "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Hush the login message
link_config "$CONFIG_DIR/.hushlogin" "$HOME/.hushlogin"

tmux source-file ~/.tmux.conf 2>/dev/null || true

# Setting up machine-specific configs
M_CONFIG_DIR="$MACHINEPATH/configs"

# Setup Mise if it is configured
if [ -f "$M_CONFIG_DIR/.config/mise/config.toml" ]; then
    link_config "$M_CONFIG_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
    mise install
fi

# Set up Git configs
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "signingkey" "$HOME/.gitconfig" 2>/dev/null; then
    link_config "$M_CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Set up shell config
link_config "$M_CONFIG_DIR/.zshrc" "$HOME/.zshrc"
chmod 0600 "$HOME/.zshrc"
