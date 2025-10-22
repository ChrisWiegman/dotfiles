#!/bin/sh

SHAREDPATH=$1
MACHINEPATH=$2

if [[ $OSTYPE == darwin* ]]; then
    sh $SHAREDPATH/scripts/mac.sh
fi

if [[ $OSTYPE == linux* ]]; then
    sh $SHAREDPATH/scripts/linux.sh $SHAREDPATH
fi

sh $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
sh $SHAREDPATH/scripts/oh-my-z.sh
sh $SHAREDPATH/scripts/configs.sh $SHAREDPATH $MACHINEPATH

# Run the local config if its available
[ -s "$MACHINEPATH/setup.sh" ] && sh $MACHINEPATH/setup.sh $MACHINEPATH

# Create the code folder if we don't have it
if [ ! -d $HOME/Code ]; then
    mkdir -p $HOME/Code;
fi
