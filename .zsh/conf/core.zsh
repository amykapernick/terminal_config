# Core helpers - zsh only.

# Reload ~/.zshrc to pick up function/alias changes
refresh () {
	source ~/.zshrc
}

# Check git repos under ~ for uncommitted work and global npm packages for updates
check () {
	cd ~
	git-check -d
	npm-check -g
}

# Generate an ed25519 SSH key in ~/.ssh (Linux: import it into 1Password afterwards;
# WSL: it's added to the ssh-agent)
# usage: new_ssh <key-name> [email=git config user.email]
new_ssh () {
	[[ -z $1 ]] && { echo "usage: new_ssh <key-name> [email]"; return 1 }
	ssh-keygen -t ed25519 -C "${2:-$(git config user.email)}" -f ~/.ssh/$1 || return
	if (( IS_WSL ))
	then
		ssh-add ~/.ssh/$1
	else
		echo "Import ~/.ssh/$1 into 1Password (New Item > SSH Key > Import) so the 1Password agent can use it"
	fi
}

# Run a command with the secrets from ~/.env.op (Linux, via 1Password) or ~/.env (WSL / fallback)
# usage: withenv <command> [args...]
withenv () {
	if (( ! IS_WSL )) && [[ -f ~/.env.op ]] && (( $+commands[op] ))
	then
		op run --env-file="$HOME/.env.op" -- "$@"
	elif [[ -f ~/.env ]]
	then
		( set -a; source ~/.env; set +a; "$@" )
	else
		"$@"
	fi
}
