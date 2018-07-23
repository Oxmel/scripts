#!/bin/bash

# This script clones a github repo containing config files and
# copies them in the home of the current user.


# Checking if git is installed
if ! command -v git &> /dev/null; then
    echo "This script requires git"
    exit 1
fi

repo_url="https://github.com/Oxmel/dotfiles.git"
cur_user=$(whoami)

# Path aliases
home="/home/$cur_user"
dotfiles="/tmp/dotfiles"

echo "Importing config files and folders"
git clone --quiet $repo_url $dotfiles

# Backing up the original bashrc
mv $home/.bashrc $home/bashrc.bak

# Copying config files to the user's home
cp $dotfiles/bashrc $home/.bashrc
cp $dotfiles/vimrc $home/.vimrc
cp -r $dotfiles/vim $home/.vim

# Cleaning up
rm -rf $dotfiles

echo "Done"
