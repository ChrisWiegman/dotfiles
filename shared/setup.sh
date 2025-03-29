#!/bin/zsh

SHAREDPATH=$1
MACHINEPATH=$2

# Setup rosetta if we're on Mac
if [ "$(uname)" = "Darwin" ]; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

zsh $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
zsh $SHAREDPATH/scripts/oh-my-z.sh
zsh $SHAREDPATH/scripts/configs.sh $SHAREDPATH $MACHINEPATH