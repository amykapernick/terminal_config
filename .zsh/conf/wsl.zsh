# WSL only - zsh. Sourced from ~/.zshrc when running under WSL.
# SSH keys are loaded by the oh-my-zsh ssh-agent plugin (enabled in ~/.zshrc for WSL only).

# Open links in the Windows default browser (wslview comes from the wslu package)
(( $+commands[wslview] )) && export BROWSER=wslview

# Secrets: 1Password's WSL integration is unreliable, so export ~/.env into the shell
[[ -f ~/.env ]] && { set -a; source ~/.env; set +a }

# Re-add ~/.ssh/id_default to the ssh-agent (if the agent lost it)
fix_ssh () {
	ssh-add ~/.ssh/id_default
}
alias ssh_fix="fix_ssh"

# Delete Windows Zone.Identifier files under the current folder
del_zone () {
	find . -name '*:Zone.Identifier' -delete
}

# Go to a Local WP theme: ~/windows/<site>/app/public/wp-content/themes/<theme>
# usage: wp <site> [theme=<site>]
wp () {
	move_folder "windows" $1/app/public/wp-content/themes/${2:-$1}
}
