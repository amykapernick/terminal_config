# Package install/update functions. Loaded by zsh, but also sourced by
# setup_terminal.sh (bash), so keep this file bash-compatible: no zsh-only syntax.

# True when running under WSL
_is_wsl () {
	[ -n "$WSL_DISTRO_NAME" ] || command grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

# Pick the Ubuntu 24.04+ "t64" package name when it exists, so the same list works on older WSL distros
_apt_name () {
	if apt-cache show "${1}t64" >/dev/null 2>&1; then echo "${1}t64"; else echo "$1"; fi
}

# Install stylelint SMACSS/SCSS/order configs as dev dependencies
install_stylelint () {
	npm install --save-dev stylelint-config-property-sort-order-smacss stylelint-scss stylelint-order
}

# Install eslint with airbnb-base, import and react plugins
install_eslint () {
	npm install eslint eslint-config-airbnb-base eslint-plugin-import eslint-plugin-react
}

# Install/upgrade the Doppler CLI with brew
update_doppler () {
	brew install dopplerhq/cli/doppler
}

# Install the global npm tools
install_global () {
	npm install -g npm-check license netlify-cli qnm @azure/static-web-apps-cli linkinator concurrently
}

# Install the Homebrew tools
install_brew () {
	brew tap azure/functions
	brew tap charmbracelet/tap
	brew install \
		gh starship fnm zoxide fzf python \
		eza bat fd ripgrep rm-improved curlie xh tldr jq git-delta glow \
		gnupg ffmpeg \
		dopplerhq/cli/doppler azure-functions-core-tools@4 \
		charmbracelet/tap/gum ngrok/ngrok/ngrok
}

# Install the apt packages (plus the WSL-only extras when run under WSL)
install_utilities () {
	local pkgs="ca-certificates wget unzip zip gawk lsb-release xdg-utils php-cli zsh python3-pip pipx fonts-powerline fonts-liberation"

	if _is_wsl
	then
		# wslu provides wslview (open links/files in Windows)
		pkgs="$pkgs wslu"
		# Libraries headless Chrome/Puppeteer needs, which a WSL install doesn't ship with
		local lib
		for lib in libasound2 libatk-bridge2.0-0 libatk1.0-0 libcups2 libgtk-3-0 libglib2.0-0
		do
			pkgs="$pkgs $(_apt_name $lib)"
		done
		pkgs="$pkgs libgbm1 libnss3 libnspr4 libdrm2 libxkbcommon0 libpango-1.0-0 libcairo2 libx11-xcb1 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libxss1 libxtst6"
	fi

	sudo apt-get update
	sudo apt-get install -y $pkgs
}

# Install the global Python packages (gen_colours needs pyperclip, pyhumps and fire)
install_pip () {
	pip3 install --user --break-system-packages requests python-dotenv pyperclip pyhumps fire
}

# Install pay-respects (replacement for thefuck) from its GitHub release into ~/.local/bin
# Skips the optional AI module, which sends failed commands to an online service.
install_pay_respects () {
	local tmp
	tmp=$(mktemp -d) || return
	gh release download -R iffse/pay-respects -p '*-x86_64-unknown-linux-musl.tar.zst' -D "$tmp" &&
		tar --zstd -xf "$tmp"/*.tar.zst -C "$tmp" &&
		install -m755 "$tmp/pay-respects" "$tmp/_pay-respects-module-100-runtime-rules" ~/.local/bin/ &&
		pay-respects --version
	command rm -rf "$tmp"
}

# Install rclone and pay-respects
install_other () {
	sudo -v ; command curl https://rclone.org/install.sh | sudo bash
	install_pay_respects
}

# Update everything: Ubuntu, brew, oh-my-zsh + plugins, Node LTS and all packages
update () {
	update_ubuntu
	brew update && brew upgrade
	update_plugins
	fnm install --lts
	fnm use --lts
	fnm default lts-latest
	install_utilities
	install_brew
	install_global
	install_pip
	install_other
	npm-check -gu
}

# apt update/upgrade (release upgrades are separate: upgrade_ubuntu_release)
update_ubuntu () {
	sudo apt update
	sudo apt upgrade -y
	sudo apt autoremove -y
}

# Upgrade to the next Ubuntu release (stable releases only, asks before doing anything)
upgrade_ubuntu_release () {
	sudo apt install -y update-manager-core
	sudo do-release-upgrade
}

# Show the Ubuntu version
check_ubuntu () {
	lsb_release -a
}

# Install and switch to a Node version with fnm, then reinstall global tools
# usage: update_node [version=lts]
update_node () {
	local version=${1:-lts}
	fnm install "$version"
	fnm use "$version"
	fnm default "$version"
	install_global
}

# Update oh-my-zsh and the zsh plugin submodules in ~/.zsh/plugins
update_plugins () {
	zsh "$ZSH/tools/upgrade.sh"
	git -C ~ submodule update --init --remote --merge .zsh/plugins
	echo "Plugins updated - commit the new submodule versions in ~ when you're happy"
}
