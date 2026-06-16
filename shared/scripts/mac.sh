#!/bin/sh

# Ensure the default login shell matches macOS default
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Setting default shell to /bin/zsh..."
    chsh -s /bin/zsh
fi

# Install command-line tools if not already installed
if ! xcode-select -p &>/dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait until the tools are installed
    until xcode-select -p &>/dev/null; do
        sleep 3
    done
    echo "Xcode Command Line Tools installed."
fi
