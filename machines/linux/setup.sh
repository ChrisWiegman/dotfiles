#!/bin/bash

SHAREDPATH=$1
MACHINEPATH=$2

echo "Setup additional apps"

sudo apt-get install -y \
    tmux \
    zsh \
    gnupg2 \
    gnupg-agent \
    scdaemon \
    pcscd \
    libpam-fprintd

echo "Enable fingerprint sensor"
sudo pam-auth-update

echo "Setting up linux config files"

CONFIG_DIR=$MACHINEPATH/configs

# Setup ZSH Config
rm -f $HOME/.zshrc
rm -f $HOME/.zshrc.pre-oh-my-zsh
ln -s $CONFIG_DIR/.zshrc $HOME/.zshrc
chmod 0600 $HOME/.zshrc

# Setup GPG configs
if [ ! -d $HOME/.gnupg ]; then
    mkdir -p $HOME/.gnupg;
fi

rm -f $HOME/.gnupg/gpg-agent.conf
ln -s $CONFIG_DIR/.gnupg/gpg-agent.conf $HOME/.gnupg/gpg-agent.conf
chmod 0600 $HOME/.gnupg/gpg-agent.conf

# Setup Git configs
rm -f $HOME/.gitconfig
ln -s $CONFIG_DIR/.gitconfig $HOME/.gitconfig

# This allows me to keep the shared file and just delete on this one machine that needs it
rm $HOME/.gnupg/scdaemon.conf
