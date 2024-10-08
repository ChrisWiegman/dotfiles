#!/bin/zsh

SHAREDPATH=$1
MACHINEPATH=$2

echo "Setting up mac config files"

CONFIG_DIR=$MACHINEPATH/configs

# Setup ZSH Config
rm -f $HOME/.zshrc
rm -f $HOME/.zshrc.pre-oh-my-zsh
ln -s $CONFIG_DIR/.zshrc $HOME/.zshrc
chmod 0600 $HOME/.zshrc

# Load ZSH config
source $HOME/.zshrc

# Setup Git configs
rm -f $HOME/.gitconfig
ln -s $CONFIG_DIR/.gitconfig $HOME/.gitconfig