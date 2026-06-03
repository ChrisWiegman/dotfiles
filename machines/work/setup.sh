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
