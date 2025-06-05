#!/bin/zsh

# Setup rosetta
if /usr/bin/pgrep oahd &>/dev/null; then
    echo "Rosetta is already installed."
else
    echo "Installing Rosetta..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

# Install command-line tools if not already installed
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait until the tools are installed
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "Xcode Command Line Tools installed."
fi