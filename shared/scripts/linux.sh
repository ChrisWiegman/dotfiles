#!/bin/sh

SHAREDPATH=$1

CONFIG_DIR=$SHAREDPATH/configs

sudo apt-get update -y
sudo apt-get dist-upgrade -y
sudo apt-get autoremove --purge -y
sudo snap refresh   
sudo apt-get install -y \
    curl \
    git \
    zsh \
    wget \
    gpg \
    apt-transport-https \
    flatpak \
    build-essential
sudo apt-get clean

# Install VSCode
echo "code code/add-microsoft-repo boolean true" | sudo debconf-set-selections
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg
rm -f microsoft.gpg

sudo cp $CONFIG_DIR/vscode.sources /etc/apt/sources.list.d

sudo apt-get update
sudo apt-get install -y code

# Setup Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt install -f -y
rm google-chrome-stable_current_amd64.deb

# Setup Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Remove Firefox
sudo snap remove --purge firefox

set -eu

LANG=C snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        snap remove "$snapname" --revision="$revision"
    done
