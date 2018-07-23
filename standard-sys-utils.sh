#!/bin/bash

# List of packages to add on a fresh debian install
# The aim of this script is to replace the 'standard system utilities' option
# provided by the installer. To get the list of packages flagged as 'standard'
# one can use this command : aptitude search ~pstandard -F"%p"


# Checking if superuser
if [[ $EUID -ne 0 ]]; then
    echo "Run it as root"
    exit 1
fi

pkList=(
    apt-listchanges
    aptitude
    bash-completion
    bzip2
    curl
    dnsutils
    git
    htop
    info
    lsof
    sudo
    telnet
    time
    unzip
    resolvconf
    vim
    whois
)

echo "Updating packages list"
apt-get update > /dev/null

for item in ${pkList[@]}; do
    if dpkg -s $item >/dev/null 2>&1; then
        echo "Package '${item}' is already installed, skipping"
    else
        echo "Installing '${item}'"
        apt-get install -y $item > /dev/null
    fi
done
