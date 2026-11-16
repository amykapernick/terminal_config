# Aliases - zsh only. Sourced after all functions (see ~/.zshrc), so these only
# change what you type at the prompt; functions and scripts still get the real
# commands. Use `command <name>` (e.g. `command grep -E`) to skip an alias.

# Modern replacements for the standard tools
alias ls="eza"
alias cat="bat"
alias find="fd"
alias grep="rg"
alias curl="curlie"

# Moves files to the rip graveyard instead of deleting them (asks first).
# Accepts and ignores rm's -r/-f/-v flags so pasted `rm -rf` commands still work.
# Empty the graveyard with: empty_trash
alias rm="_rip_rm"
_rip_rm () {
	local -a targets
	local a
	for a in "$@"
	do
		case $a in
			--|-[rRfvdiI]*|--recursive|--force|--verbose|--dir|--interactive*) ;;
			*) targets+=("$a") ;;
		esac
	done
	(( $#targets )) || { print -u2 "rm: missing operand"; return 1 }
	rip -i "${targets[@]}"
}

unalias man 2>/dev/null
# man works as normal, then reminds you tldr has quick examples
# usage: man <page>
man () {
	command man "$@"
	local s=$?
	(( s == 0 && $+commands[tldr] )) && print -P "%F{8}tip: %Btldr ${@[-1]}%b%F{8} shows quick examples%f"
	return $s
}

alias git-check='~/git-summary/git-summary'
alias utils="node ~/dev/terminal_utils"
