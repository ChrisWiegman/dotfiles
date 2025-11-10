#!/bin/sh

SHAREDPATH=$1
MACHINEPATH=$2

M_CONFIG_DIR=$MACHINEPATH/configs

# Setup SSH configs
rm -f $HOME/.ssh/config
ln -s $M_CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0700 $HOME/.ssh
chmod 0600 $HOME/.ssh/config

# Setup Git configs
echo "Setting up a local GIT config file."
if [ ! -f $HOME/.gitconfig ] || [ ! $(grep -q "signingkey" "$HOME/.gitconfig") ]; then
    rm -f $HOME/.gitconfig
    cp $M_CONFIG_DIR/.gitconfig $HOME/.gitconfig
fi

# Load ZSH and its config
zsh
source $HOME/.zshrc