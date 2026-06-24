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

if ! command -v brew > /dev/null 2>&1; then
    echo "Error: Homebrew installation failed" >&2
    exit 1
fi

brew analytics off

# If the Brewfile installs Mac App Store apps, make sure `mas` is present and the
# user is signed in to the App Store. A failed `mas` line aborts the whole bundle
# under `set -e`, so verify sign-in up front rather than failing midway.
if grep -q '^[[:space:]]*mas ' "${MACHINEPATH}/Brewfile"; then
    if ! command -v mas > /dev/null 2>&1; then
        brew install mas
    fi
fi

# install brew dependencies from Brewfile
brew bundle --file="${MACHINEPATH}/Brewfile"

# Cleanup all leftovers from the installation.
rm -f "${MACHINEPATH}/Brewfile.lock.json"
brew cleanup --prune=all --quiet
