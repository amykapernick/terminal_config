# -----------------------------
# PATH setup
# -----------------------------
export PATH=/bin:/usr/bin:/usr/local/bin:$PATH
export PATH="$HOME/.cargo/bin:$PATH"        # for zoxide
export PATH="$PATH:/usr/local/bin"          # for op CLI
export PATH="/home/linuxbrew/.linuxbrew/opt/mongodb-community@4.4/bin:$PATH"

# fnm (Node version manager)
FNM_PATH="/home/amy/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env)"
fi

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
if ! zplug check --verbose; then
  zplug install
fi
zplug load

# -----------------------------
# Prompt & helpers
# -----------------------------
STARSHIP_CONFIG=~/.config/starship.toml
eval "$(starship init zsh)"

eval "$(zoxide init zsh)"
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
eval $(thefuck --alias fuck)
# eval "$(fzf --zsh)"   # uncomment if you want fzf integration

# -----------------------------
# Misc configs
# -----------------------------
. ~/.bash_func

export DISPLAY=$(ip route | awk '/^default/{print $3}'):0.0
export BROWSER=host_chrome

# zsh modules
zmodload -ap zsh/mapfile mapfile
zmodload zsh/mapfile

# 1Password CLI
# eval $(op signin)
