#!/bin/sh

set -e
trap 'echo "mac.sh failed at line $LINENO" >&2' ERR

. "$(dirname "$0")/lib.sh"

# Ensure the default login shell matches macOS default
if [ "$SHELL" != "/bin/zsh" ]; then
    echo "Setting default shell to /bin/zsh..."
    chsh -s /bin/zsh || warn "Couldn't change your login shell to zsh. Run: chsh -s /bin/zsh"
fi

# Install command-line tools if not already installed. Setup can't go on
# without them (they provide git), so stop if they don't get installed.
# (`&>` is a bashism; under a POSIX sh it backgrounds the command instead.)
if ! xcode-select -p >/dev/null 2>&1; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "  Click Install in the dialog that opened. Setup continues when it's done."
    # Wait while the installer is open. Once it's gone, either the tools are
    # installed or the dialog was cancelled. The pause gives it time to launch.
    sleep 5
    until xcode-select -p >/dev/null 2>&1; do
        if ! pgrep -qf "Install Command Line Developer Tools"; then
            # It can close a moment before the tools register.
            sleep 5
            xcode-select -p >/dev/null 2>&1 && break
            echo "The Xcode Command Line Tools weren't installed. Run setup again to retry." >&2
            exit 1
        fi
        sleep 3
    done
    echo "Xcode Command Line Tools installed."
fi
