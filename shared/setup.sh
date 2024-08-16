#!/bin/sh

SHAREDPATH=$1
MACHINEPATH=$2

bash $SHAREDPATH/scripts/homebrew.sh $MACHINEPATH
bash $SHAREDPATH/scripts/oh-my-z.sh
bash $SHAREDPATH/scripts/configs.sh $SHAREDPATH