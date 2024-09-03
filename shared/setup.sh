#!/bin/sh

SHAREDPATH=$1
MACHINEPATH=$2

# Setup rosetta if we're on Mac
if [ "$(uname)" = "Darwin" ]; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

bash $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
bash $SHAREDPATH/scripts/oh-my-z.sh
bash $SHAREDPATH/scripts/configs.sh $SHAREDPATH