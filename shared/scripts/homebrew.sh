#!/bin/sh

set -e
trap 'echo "homebrew.sh failed at line $LINENO" >&2' ERR

MACHINEPATH="$1"

echo "Setting up Homebrew"

if test ! "$(command -v brew)"; then
    echo "Homebrew not installed. Installing."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Launch Homebrew
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -s "/home/linuxbrew/.linuxbrew/bin/brew" ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

if ! command -v brew > /dev/null 2>&1; then
    echo "Error: Homebrew installation failed" >&2
    exit 1
fi

brew analytics off

# install brew dependencies from Brewfile
brew bundle --file="${MACHINEPATH}/Brewfile"

# Cleanup all leftovers from the installation.
rm -f "${MACHINEPATH}/Brewfile.lock.json"
brew cleanup --prune=all --quiet
