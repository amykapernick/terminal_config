# ~/.zshrc - shared by native Linux and WSL.
# Anything that only applies to one of them lives in ~/.zsh/conf/linux.zsh or wsl.zsh.
#
# Layout:
#   ~/.zsh/conf/*.zsh   functions, aliases and per-OS config (zsh only)
#   ~/.zsh/plugins/     zsh plugins, as git submodules (update with: update_plugins)

# -----------------------------
# Platform
# -----------------------------
if [[ -n $WSL_DISTRO_NAME || $(</proc/sys/kernel/osrelease) == *[Mm]icrosoft* ]]; then
  export IS_WSL=1
else
  unset IS_WSL
fi

# -----------------------------
# PATH (typeset -U drops duplicates, so re-sourcing is safe)
# -----------------------------
typeset -U path fpath
[[ -x /home/linuxbrew/.linuxbrew/bin/brew ]] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
path=(
  $HOME/.local/bin
  $BUN_INSTALL/bin
  $PNPM_HOME/bin
  ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/opt/python/libexec/bin}  # unversioned `python`/`pip` -> brew's python3
  $path
)
path=($^path(N-/))  # drop folders that don't exist on this machine

# fnm (Node version manager)
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

# -----------------------------
# oh-my-zsh (custom plugins come from ~/.zsh/plugins)
# -----------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.zsh"
fpath+=($ZSH_CUSTOM/plugins/zsh-completions/src)

plugins=(git docker zsh-autosuggestions)
# WSL: the 1Password SSH agent isn't reliable there, so load keys into a normal ssh-agent on start
if (( IS_WSL )); then
  zstyle :omz:plugins:ssh-agent identities id_default
  plugins+=(ssh-agent)
fi
plugins+=(zsh-syntax-highlighting)  # must be the last plugin

[[ -r $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# -----------------------------
# Prompt & helpers
# -----------------------------
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[pay-respects] )) && eval "$(pay-respects zsh --alias fuck)"

export BAT_THEME="Catppuccin Mocha"
zmodload zsh/mapfile
autoload -U add-zsh-hook

# Default 1Password CLI account (aimhigherweb inside ~/web, personal elsewhere)
_op_account() {
  case $PWD/ in
    ~/web/*) export OP_ACCOUNT=aimhigherweb.1password.com ;;
    *)       export OP_ACCOUNT=my.1password.com ;;
  esac
}
add-zsh-hook chpwd _op_account
_op_account

# Claude Code: use the work account (separate config dir) inside ~/makerx
claude() {
  if [[ "$PWD" == "$HOME/makerx" || "$PWD" == "$HOME/makerx/"* ]]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"
  else
    command claude "$@"
  fi
}

# bun completions
[[ -s $BUN_INSTALL/_bun ]] && source $BUN_INSTALL/_bun

# -----------------------------
# Functions, per-OS config, aliases
# -----------------------------
for _f in ~/.zsh/conf/{core,init,git,nav,packages,utils,vscode,ssh}.zsh(N); do
  source $_f
done
unset _f

if (( IS_WSL )); then
  source ~/.zsh/conf/wsl.zsh
else
  source ~/.zsh/conf/linux.zsh
fi

# Aliases go after the functions, so functions always get the real commands
# (find, grep, rm...) and the alias only changes what you type at the prompt.
source ~/.zsh/conf/aliases.zsh
source ~/.zsh/conf/help.zsh  # indexes everything above, so keep it after them

# -----------------------------
# zoxide: must stay at the very end. `--cmd cd` makes cd itself zoxide-aware
# (cd foo jumps to the best match, cdi picks interactively).
# -----------------------------
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
