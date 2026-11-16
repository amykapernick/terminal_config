#!/bin/bash
# Set up a new machine (native Ubuntu or WSL) from this repo.
# Run it with: curl -fsSL https://raw.githubusercontent.com/amykapernick/terminal_config/prod/setup_terminal.sh | bash
# or from a copy of the file. Safe to re-run.
set -e

is_wsl () { [ -n "$WSL_DISTRO_NAME" ] || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }

## Get Info
read -p "What do you want to call this terminal? " terminal_name </dev/tty
read -p "What email address do you want to use? " email </dev/tty

# Base tools
sudo apt-get update
sudo apt-get install -y build-essential curl git zip zsh

# Install Homebrew
if [ ! -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install gcc gh

# Pull terminal config into the home folder (existing files are backed up first)
cd ~
if [ ! -d ~/.git ]; then
	backup=~/.dotfiles_backup_$(date +%Y%m%d%H%M%S)
	mkdir -p "$backup"
	for f in .zshrc .profile .bashrc .bash_logout .gitconfig; do
		[ -f "$f" ] && cp "$f" "$backup/"
	done
	git init -b prod
	git remote add origin https://github.com/amykapernick/terminal_config.git
	git fetch origin
	git checkout -f -B prod --track origin/prod
fi
git submodule update --init --recursive

# Package functions (bash-compatible)
source ~/.zsh/conf/packages.zsh

# Git
git config --global user.email "$email"

# SSH key for GitHub
if [ ! -f ~/.ssh/id_default ]; then
	ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_default
fi
gh auth status >/dev/null 2>&1 || gh auth login
gh ssh-key add ~/.ssh/id_default.pub --title "$terminal_name" || true
git remote set-url origin git@github.com:amykapernick/terminal_config.git

# zsh as the default shell
[ "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)" ] || chsh -s "$(command -v zsh)"

# oh-my-zsh (KEEP_ZSHRC stops the installer replacing the repo's .zshrc)
if [ ! -d ~/.oh-my-zsh ]; then
	RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Packages (install_utilities adds the WSL-only extras when run under WSL)
install_utilities
install_brew

# Node via fnm
eval "$(fnm env --use-on-cd --shell bash)"
fnm install --lts
fnm use --lts
fnm default lts-latest

npm set init-author-name="Amy Kapernick"
npm set init-author-email="$email"
npm set init-author-url="https://amyskapers.dev"
npm set init-license="MIT"
npm set init-version="1.0.0"

install_global
install_pip
install_other

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# 1Password CLI - native Linux only (on WSL, the 1Password connection is unreliable; use ~/.env)
if ! is_wsl && ! command -v op >/dev/null; then
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
		sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
		sudo tee /etc/apt/sources.list.d/1password.list
	sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
	curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
		sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
	sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
	curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
		sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
	sudo apt update && sudo apt install -y 1password-cli
fi

# WSL: link the Windows user folder to ~/windows (used by the wp function)
if is_wsl && [ ! -e ~/windows ]; then
	win_user=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
	[ -n "$win_user" ] && ln -s "/mnt/c/Users/$win_user/windows" ~/windows
fi

echo "Done. Copy ~/.ssh/config and ~/.env (WSL) or ~/.env.op (Linux) from another machine, then open a new terminal."
