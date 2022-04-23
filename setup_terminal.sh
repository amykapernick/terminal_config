#!/bin/bash

## Get Info
read -p "What do you want to call this terminal?" terminal_name
read -p "What email address do you want to use?" email
read -p "What is your tunnelto auth key?" tunnelto_key

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
sudo apt-get install build-essential
brew install gcc

# Setup Base Utilities
sudo apt install zip

# Update Terminal
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install git

# Setup Git
git config --global init.defaultBranch prod
git config --global user.name "Amy Kapernick"
git config --global user.email $email

# Use GitHub CLI to generate and add SSH keys
brew install gh
ssh-keygen -t ed25519 -C $email -f ~/.ssh/id_default
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_default
gh ssh-key add ~/.ssh/id_default.pub --title $terminal_name

# Clone terminal config file and add to user folder
cd ~
git clone git@github.com:amykapernick/terminal_config.git
cp -r ~/terminal_config/. ~
rm -rf ~/terminal_config
# read -p "Press enter to continue"
cd ~
git submodule update --init --recursive
git pull

# Install Node
curl -fsSL https://fnm.vercel.app/install | bash
fnm install latest
fnm use latest

# Setup Node Init
npm set init.author.name "Amy Kapernick"
npm set init.author.email $email
npm set init.author.url "https://amyskapers.dev"
npm set init.license "MIT"
npm set init.version "1.0.0"

# Install and Setup ZSH and theme
sudo apt install zsh
curl -sS https://starship.rs/install.sh | sh

## ZSH Plugins and Utils
git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git
source zsh-snap/install.zsh

## Tunnelto
sudo wget https://github.com/agrinman/tunnelto/releases/download/0.1.18/tunnelto-linux.tar.gz
tar xvzf tunnelto-linux.tar.gz
sudo mv tunnelto /usr/local/bin/tunnelto
tunnelto set-auth --key $tunnelto_key

# Python Utilities
sudo apt update
sudo apt install python3-pip
pip install pyperclip
pip install pyhumps
pip install fire
pip install tldr

# Other Utilities
npm install -g npm-check azure-functions-core-tools license netlify-cli spaceship-prompt
brew install thefuck
sudo apt install zoxide
brew install dog
brew install fzf
brew install xh
brew install rs/tap/curlie
sudo apt install exa