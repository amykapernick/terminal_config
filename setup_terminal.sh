#!/bin/bash

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
sudo apt-get install build-essential
brew install gcc

# Setup Base Utilities
sudo apt install zip

# Setup Git
git config --global init.defaultBranch prod
git config --global user.name "Amy Kapernick"
git config --global user.email "amy@kapers.dev"

# Use GitHub CLI to generate and add SSH keys
brew install gh
ssh-keygen -t ed25519 -C "amy@kapers.dev" -f ~/.ssh/id_default
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_default
read -p "What do you want to call this terminal?" terminal_name
echo $terminal_name
gh ssh-key add ~/.ssh/id_default.pub --title "$terminal_name"

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
npm set init.author.email "amy@kapers.dev"
npm set init.author.url "https://amyskapers.dev"
npm set init.license "MIT"
npm set init.version "1.0.0"

# Install and Setup ZSH and theme
sudo apt install zsh
curl -sS https://starship.rs/install.sh | sh

# Other Utilities
brew install exa
npm install -g npm-check azure-functions-core-tools license netlify-cli spaceship-prompt