#!/bin/sh

set -e
trap 'echo "configs.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

echo "Setting up shared config files"

CONFIG_DIR="$SHAREDPATH/configs"

# Set up SSH config
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi
chmod 0700 "$HOME/.ssh"

rm -f "$HOME/.ssh/config"
ln -s "$CONFIG_DIR/.ssh/config" "$HOME/.ssh/config"
chmod 0600 "$HOME/.ssh/config"

# Set up Tmux configs
rm -f "$HOME/.tmux.conf"
ln -s "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Hush the login message
rm -f "$HOME/.hushlogin"
ln -s "$CONFIG_DIR/.hushlogin" "$HOME/.hushlogin"

tmux source-file ~/.tmux.conf

# Setting up machine-specific configs
M_CONFIG_DIR="$MACHINEPATH/configs"

# Set up Git configs
if [ ! -f "$HOME/.gitconfig" ] || ! grep -q "signingkey" "$HOME/.gitconfig" 2>/dev/null; then
    rm -f "$HOME/.gitconfig"
    ln -s "$M_CONFIG_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Set up shell config
rm -f "$HOME/.zshrc"
ln -s "$M_CONFIG_DIR/.zshrc" "$HOME/.zshrc"
chmod 0600 "$HOME/.zshrc"
