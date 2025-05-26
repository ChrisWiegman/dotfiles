#!/bin/zsh

SHAREDPATH=$1
MACHINEPATH=$2

# Setup rosetta
/usr/sbin/softwareupdate --install-rosetta --agree-to-license

zsh $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
zsh $SHAREDPATH/scripts/oh-my-z.sh
zsh $SHAREDPATH/scripts/configs.sh $SHAREDPATH $MACHINEPATH

# Run the local config if its available
[ -s "$MACHINEPATH/setup.sh" ] && zsh $MACHINEPATH/setup.sh $MACHINEPATH