#!/bin/bash

MACHINEPATH=$1

echo "Setting up Homebrew"

if test ! "$(command -v brew)"; then
    info "Homebrew not installed. Installing."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ "$(uname)" = "Linux" ]; then
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
fi

brew analytics off

# install brew dependencies from Brewfile
brew bundle --file=${MACHINEPATH}/Brewfile

rm -f ${MACHINEPATH}/Brewfile.lock.json