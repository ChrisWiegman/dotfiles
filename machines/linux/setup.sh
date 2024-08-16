#!/bin/bash

SHAREDPATH=$1
MACHINEPATH=$2

echo "Setup additional apps"

sudo apt-get install -y \
    tmux \
    zsh \
    libpam-fprintd \
    projecteur

echo "Enable fingerprint sensor"
sudo pam-auth-update

echo "Setting up linux config files"

CONFIG_DIR=$MACHINEPATH/configs

# Setup ZSH Config
rm -f $HOME/.zshrc
rm -f $HOME/.zshrc.pre-oh-my-zsh
ln -s $CONFIG_DIR/.zshrc $HOME/.zshrc
chmod 0600 $HOME/.zshrc

# Setup Git configs
rm -f $HOME/.gitconfig
ln -s $CONFIG_DIR/.gitconfig $HOME/.gitconfig
