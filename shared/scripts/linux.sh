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

# Setup Flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

