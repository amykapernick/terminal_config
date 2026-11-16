# -----------------------------
# PATH setup
# -----------------------------
export PATH=/bin:/usr/bin:/usr/local/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"        # for zoxide
export PATH="$HOME/.local/bin:$PATH"        # for op CLI
export PATH="/home/linuxbrew/.linuxbrew/opt/mongodb-community@4.4/bin:$PATH"
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)  # must come last so brew's bin wins over /usr/local/bin

# fnm (Node version manager)
eval "$(fnm env --use-on-cd --shell zsh)"

# -----------------------------
# oh-my-zsh base
# -----------------------------
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# -----------------------------
# zplug plugin manager
# -----------------------------
source ~/.zplug/init.zsh

# oh-my-zsh built-in plugins via zplug
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh
zplug "plugins/ssh-agent", from:oh-my-zsh

# third-party plugins via zplug
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions"
zplug "TamCore/autoupdate-oh-my-zsh-plugins"

# install/load plugins
if ! zplug check; then
  zplug install
fi
zplug load

# -----------------------------
# Prompt & helpers
# -----------------------------
STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init zsh)"

eval "$(zoxide init zsh)"
fuck() { eval $(thefuck --alias); fuck "$@"; unfunction fuck; }
# eval "$(fzf --zsh)"   # uncomment if you want fzf integration

# -----------------------------
# Misc configs
# -----------------------------
. ~/.bash_func

# export DISPLAY=$(ip route ...) # WSL only
# export BROWSER=none # WSL only
export BAT_THEME="Catppuccin Mocha"

# zsh modules
zmodload zsh/mapfile

# Default 1Password CLI account (aimhigherweb inside ~/web, personal elsewhere)
_op_account() {
  case $PWD/ in
    ~/web/*) export OP_ACCOUNT=aimhigherweb.1password.com ;;
    *)       export OP_ACCOUNT=my.1password.com ;;
  esac
}
autoload -U add-zsh-hook
add-zsh-hook chpwd _op_account
_op_account

# Browser for opened links (Chrome in ~/makerx, Firefox in ~/web, system default elsewhere)
_browser_by_dir() {
  local wrap=~/.local/bin/browser-by-dir
  path=(${path:#$wrap})
  case $PWD/ in
    ~/makerx/*) export BROWSER=google-chrome ;;
    ~/web/*)    export BROWSER=firefox ;;
    *)          unset BROWSER; return ;;
  esac
  path=($wrap $path)
}
add-zsh-hook chpwd _browser_by_dir
_browser_by_dir

# 1Password CLI
# Requires: 1Password for Windows running + Settings > Developer > "Integrate with 1Password CLI" enabled
export OP_BIOMETRIC_UNLOCK_ENABLED=true
# No eager signin: op prompts for authorisation lazily on first use in each terminal

# pnpm
export PNPM_HOME="/home/amy/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# Claude Code: use the work account (separate config dir) inside ~/makerx
claude() {
  if [[ "$PWD" == "$HOME/makerx" || "$PWD" == "$HOME/makerx/"* ]]; then
    CLAUDE_CONFIG_DIR="$HOME/.claude-work" command claude "$@"
  else
    command claude "$@"
  fi
}

# bun completions
[ -s "/home/amy/.bun/_bun" ] && source "/home/amy/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
