#!/bin/sh

SHAREDPATH=$1
MACHINEPATH=$2

CONFIG_DIR=$SHAREDPATH/configs

echo "Setting up a local SSH config file."
rm -f $HOME/.ssh/config
mv $CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0700 $HOME/.ssh
chmod 0600 $HOME/.ssh/config

# Load ZSH and its config
zsh
source $HOME/.zshrc