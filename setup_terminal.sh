#!/bin/bash

## Get Info
read -p "What do you want to call this terminal?" terminal_name
read -p "What email address do you want to use?" email

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
sudo apt-get install -y build-essential
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
brew install gcc

# Setup Base Utilities
sudo apt install -y zip

# Update Terminal
sudo add-apt-repository ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y git

# Setup Git
git config --global init.defaultBranch prod
git config --global user.name "Amy Kapernick"
git config --global user.email "$email"

# Use GitHub CLI to generate and add SSH keys
brew install gh
ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_default
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_default
gh auth login
gh ssh-key add ~/.ssh/id_default.pub --title "$terminal_name"

# Pull terminal config to user folder
cd ~
git submodule update --init --recursive
git pull

# Source package functions (defined in ~/bash_func/.packages)
source ~/bash_func/.packages

# Install and set default shell to ZSH
sudo apt install -y zsh
chsh -s $(which zsh)

# Install oh-my-zsh (non-interactive)
RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zplug
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh

# Install starship prompt
brew install starship

# Install Node via fnm
brew install fnm
eval "$(fnm env --use-on-cd --shell bash)"
fnm install --lts
fnm use --lts
fnm default lts-latest

# Setup Node Init
npm set init-author-name="Amy Kapernick"
npm set init-author-email="$email"
npm set init-author-url="https://amyskapers.dev"
npm set init-license="MIT"
npm set init-version="1.0.0"

# Python Utilities
sudo apt update
sudo apt install -y python3-pip pipx
pipx install pyperclip
pipx install pyhumps
pipx install fire

# Other Utilities
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

## npm
install_global

## apt
install_utilities

## brew
install_brew

install_pip

install_other

# 1Password CLI
# curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
#  sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

# echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
#  sudo tee /etc/apt/sources.list.d/1password.list

# sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
# curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
#  sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
# sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
# curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
#  sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

# sudo apt update && sudo apt install 1password-cli
