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

export DISPLAY=$(ip route | awk '/^default/{print $3}'):0.0
export BROWSER=none
export BAT_THEME="Catppuccin Mocha"

# zsh modules
zmodload zsh/mapfile

# 1Password CLI
# Requires: 1Password for Windows running + Settings > Developer > "Integrate with 1Password CLI" enabled
export OP_BIOMETRIC_UNLOCK_ENABLED=true
if ! op whoami &>/dev/null; then
    OP_BIOMETRIC_UNLOCK_ENABLED=true op signin --raw &>/dev/null \
        || eval $(op signin) 2>/dev/null \
        || true
fi

# pnpm
export PNPM_HOME="/home/amy/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
