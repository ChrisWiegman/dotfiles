#!/bin/zsh

OURPWD=$PWD
MACHINEPATH="$OURPWD/machines/$(basename "$1")"
SHAREDPATH="$OURPWD/shared"

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "Please invoke script with either "mac," "linux," "work" or "joy" as argument"
echo $1 | grep -E -q '^(mac|linux|work|joy)$' || die "Please invoke script with either "mac," "linux," "work" or "joy" as argument"

zsh $SHAREDPATH/setup.sh $SHAREDPATH $MACHINEPATH

zsh $MACHINEPATH/setup.sh $SHAREDPATH $MACHINEPATH
