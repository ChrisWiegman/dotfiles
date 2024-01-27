#!/bin/bash

SHAREDPATH=$1
MACHINEPATH=$2

echo "Setting up work config files"

CONFIG_DIR=$MACHINEPATH/configs

# Setup ZSH Config
rm -f $HOME/.zshrc
rm -f $HOME/.zshrc.pre-oh-my-zsh
ln -s $CONFIG_DIR/.zshrc $HOME/.zshrc
chmod 0600 $HOME/.zshrc

# Setup SSH configs
if [ ! -d $HOME/.ssh ]; then
    mkdir -p $HOME/.ssh;
fi

rm -f $HOME/.ssh/config
ln -s $CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0600 $HOME/.ssh/config

# Setup Git configs
rm -f $HOME/.gitconfig
ln -s $CONFIG_DIR/.gitconfig $HOME/.gitconfig