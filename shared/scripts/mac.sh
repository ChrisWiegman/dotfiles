#!/bin/sh

# Ensure the default login shell matches macOS default
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Setting default shell to /bin/zsh..."
    chsh -s /bin/zsh
fi

# Install command-line tools if not already installed
# (`&>` is a bashism; under a POSIX sh it backgrounds the command instead.)
if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    # Wait until the tools are installed
    until xcode-select -p >/dev/null 2>&1; do
        sleep 3
    done
    echo "Xcode Command Line Tools installed."
fi
