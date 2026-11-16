# Native Linux only - zsh. Sourced from ~/.zshrc when not running under WSL.

# 1Password desktop app: SSH agent (see ~/.ssh/config) and biometric unlock for the op CLI
# (needs Settings > Developer > "Integrate with 1Password CLI" and "Use the SSH agent")
export OP_BIOMETRIC_UNLOCK_ENABLED=true

# Secrets: prefer 1Password. If ~/.env.op exists (op:// references), nothing is loaded
# into the shell; run things that need secrets with `withenv <cmd>`.
# Until it exists, fall back to exporting ~/.env like WSL does.
if [[ ! -f ~/.env.op && -f ~/.env ]]; then
	set -a; source ~/.env; set +a
fi

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
