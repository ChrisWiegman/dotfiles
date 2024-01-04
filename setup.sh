#!/bin/sh

OURPWD=$PWD
MACHINEPATH="$OURPWD/machines/$(basename "$1")"
SHAREDPATH="$OURPWD/shared"

die () {
    echo >&2 "$@"
    exit 1
}

[ "$#" -eq 1 ] || die "Please invoke script with either "mac," "linux," or "work" as argument"
echo $1 | grep -E -q '^(mac|linux|work)$' || die "Please invoke script with either "mac," "linux," or "work" as argument"

# Setup rosetta if we're on Mac
if [ "$(uname)" = "Darwin" ]; then
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

bash $SHAREDPATH/setup.sh $SHAREDPATH $MACHINEPATH

bash $MACHINEPATH/setup.sh $SHAREDPATH $MACHINEPATH
