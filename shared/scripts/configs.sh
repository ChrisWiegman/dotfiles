#!/bin/zsh

SHAREDPATH=$1
MACHINEPATH=$2

echo "Setting up shared config files"

CONFIG_DIR=$SHAREDPATH/configs

# Setup SSH config
if [ ! -d $HOME/.ssh ]; then
    mkdir -p $HOME/.ssh;
fi

rm -f $HOME/.ssh/config
ln -s $CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0700 $HOME/.ssh
chmod 0600 $HOME/.ssh/config

# Setup Tmux configs
rm -f $HOME/.tmux.conf
ln -s $CONFIG_DIR/.tmux.conf $HOME/.tmux.conf

# Hush the login message
rm -f $HOME/.hushlogin
ln -s $CONFIG_DIR/.hushlogin $HOME/.hushlogin

tmux source-file ~/.tmux.conf

# Setting up machine-specific configs
M_CONFIG_DIR=$MACHINEPATH/configs

# Setup ZSH Config
rm -f $HOME/.zshrc
rm -f $HOME/.zshrc.pre-oh-my-zsh
ln -s $M_CONFIG_DIR/.zshrc $HOME/.zshrc
chmod 0600 $HOME/.zshrc

# Load ZSH config
source $HOME/.zshrc

# Setup Git configs
rm -f $HOME/.gitconfig
ln -s $M_CONFIG_DIR/.gitconfig $HOME/.gitconfig