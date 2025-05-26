#!/bin/zsh

echo "Setting up Oh My Zsh"

# Setup oh-my-zsh
if [ ! -d $HOME/.oh-my-zsh ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh