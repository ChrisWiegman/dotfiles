#!/bin/sh

set -e
trap 'echo "work/setup.sh failed at line $LINENO" >&2' ERR

SHAREDPATH="$1"
MACHINEPATH="$2"

M_CONFIG_DIR="$MACHINEPATH/configs"

# Set up SSH configs
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
fi
chmod 0700 "$HOME/.ssh"

rm -f "$HOME/.ssh/config"
ln -s "$M_CONFIG_DIR/.ssh/config" "$HOME/.ssh/config"
chmod 0600 "$HOME/.ssh/config"

# Make sure Geekbot CLI and its dependencies are present
echo "Setting up Geekbot CLI"

if ! command -v npm >/dev/null 2>&1; then
    echo "Error: npm not found on PATH — install Node (or load nvm) before running" >&2
    exit 1
fi

command -v bun >/dev/null 2>&1 || npm -g install bun
command -v geekbot >/dev/null 2>&1 || npm -g install geekbot-cli
