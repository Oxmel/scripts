#!/bin/bash

# This script clones a github repo containing config files and
# copies them in the home of the current user.


# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "This script requires git"
    exit 1
fi

repo_url="https://github.com/Oxmel/dotfiles.git"
dotfiles="/tmp/dotfiles"

# Construct path to the user's home
if [[ $EUID -ne 0 ]]; then
    home="/home/$(whoami)"
else
    home="/root"
fi

echo "Cloning config files from $repo_url"
git clone --quiet $repo_url $dotfiles

# Back up the original bashrc
mv $home/.bashrc $home/bashrc.bak

echo "Copying config files to $home"
cp $dotfiles/bashrc $home/.bashrc
cp $dotfiles/vimrc $home/.vimrc
cp -r $dotfiles/vim $home/.vim

# Clean up
rm -rf $dotfiles

echo "Done"
