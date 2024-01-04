#!/bin/sh

SHAREDPATH=$1

echo "Setting up shared config files"

CONFIG_DIR=$SHAREDPATH/configs

# Setup SSH config
if [ ! -d $HOME/.ssh ]; then
    mkdir -p $HOME/.ssh;
fi

rm -f $HOME/.ssh/config
ln -s $CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0700 $HOME/.ssh

# Setup GPG configs
if [ ! -d $HOME/.gnupg ]; then
    mkdir -p $HOME/.gnupg;
fi

rm -f $HOME/.gnupg/gpg.conf
ln -s $CONFIG_DIR/.gnupg/gpg.conf $HOME/.gnupg/gpg.conf
chmod 0700 $HOME/.gnupg

    rm -f $HOME/.gnupg/scdaemon.conf
ln -s $CONFIG_DIR/.gnupg/scdaemon.conf $HOME/.gnupg/scdaemon.conf

# Setup Tmux configs
rm -f $HOME/.tmux.conf
ln -s $CONFIG_DIR/.tmux.conf $HOME/.tmux.conf

# Hush the login message
rm -f $HOME/.hushlogin
ln -s $CONFIG_DIR/.hushlogin $HOME/.hushlogin

tmux source-file ~/.tmux.conf
