#!/bin/zsh

SHAREDPATH=$1
MACHINEPATH=$2

if [[ $OSTYPE == darwin* ]]; then
    zsh $SHAREDPATH/scripts/mac.sh
fi

if [[ $OSTYPE == linux* ]]; then
    zsh $SHAREDPATH/scripts/linux.sh $SHAREDPATH
fi

zsh $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
zsh $SHAREDPATH/scripts/oh-my-z.sh
zsh $SHAREDPATH/scripts/configs.sh $SHAREDPATH $MACHINEPATH

# Run the local config if its available
[ -s "$MACHINEPATH/setup.sh" ] && zsh $MACHINEPATH/setup.sh $MACHINEPATH

# Create the code folder if we don't have it
if [ ! -d $HOME/Code ]; then
    mkdir -p $HOME/Code;
fi
