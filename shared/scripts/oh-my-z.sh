#!/bin/sh

set -e
trap 'echo "oh-my-z.sh failed at line $LINENO" >&2' ERR

echo "Setting up Oh My Zsh"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
