#!/bin/zsh

MACHINEPATH=$1

echo "Setting up Homebrew"

if test ! "$(command -v brew)"; then
    info "Homebrew not installed. Installing."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Launch Homebrew
[ -s "/opt/homebrew/bin/brew" ] && eval "$(/opt/homebrew/bin/brew shellenv)"

brew analytics off

# install brew dependencies from Brewfile
brew bundle --file=${MACHINEPATH}/Brewfile

# Cleanup all leftovers from the installation.
rm -f ${MACHINEPATH}/Brewfile.lock.json
brew cleanup --prune=all --quiet