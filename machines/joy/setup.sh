#!/bin/sh

set -e
trap 'echo "joy/setup.sh failed at line $LINENO" >&2' ERR

# Install Rosetta 2 for the few Intel-only apps on this machine.
if /usr/bin/pgrep -q oahd; then
    echo "Rosetta is already installed."
else
    echo "Installing Rosetta..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi
