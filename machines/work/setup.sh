#!/bin/zsh
MACHINEPATH=$1

echo "Setting up shared config files"

CONFIG_DIR=$MACHINEPATH/configs

# Setup SSH config
if [ ! -d $HOME/.ssh ]; then
    mkdir -p $HOME/.ssh;
fi

rm -f $HOME/.ssh/config
ln -s $CONFIG_DIR/.ssh/config $HOME/.ssh/config
chmod 0700 $HOME/.ssh
chmod 0600 $HOME/.ssh/config

# Setup Git configs
if [ ! -f $HOME/.gitconfig ] || [ ! $(grep -q "signingkey" "$HOME/.gitconfig") ]; then
  rm -f $HOME/.gitconfig
  cp $CONFIG_DIR/.gitconfig $HOME/.gitconfig
  echo "\n\n\nDon't forget to manually add the signingkey to ~.gitconfig per 1Password's instructions"
fi