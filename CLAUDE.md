# Home folder = terminal_config repo

`~` is the git working tree of github.com/amykapernick/terminal_config (branch `prod`, **public**).
Read `README.md` for the full layout, every function/script, and the TODO list.

This file is loaded for every Claude session started anywhere under `~`, including project
folders like `~/makerx` or `~/web`. Those projects have their own repos and rules; this file only
matters when the task is about the terminal setup itself.

## Rules

- **Public repo.** Never commit secrets, IPs, private hostnames, tokens or email addresses.
  - Emails live in `~/.gitconfig.local`; read them with `git config user.email` or `git config email.<name>`.
  - SSH hosts live in `~/.ssh/config`, private helpers in `~/.zsh/conf/ssh.zsh`, secrets in
    `~/.env` (WSL) and `~/.env.op` (Linux, 1Password refs). None of those are tracked.
- **Allow-list `.gitignore`:** everything in `~` is ignored unless it has a `!/path` line.
  - To track something, add that line, with any comment on its own line (git doesn't support
    comments at the end of a pattern line).
  - Never force-add (`git add -f`) to get around it.
  - Check `git status` before committing.
- **Where new things go:** follow README › "Adding scripts".
  - Interactive commands are zsh functions in `~/.zsh/conf/<topic>.zsh`, with a comment and a
    `# usage:` line above each one.
  - Standalone executables go in `~/bin`, never `~/.local/bin`.
  - Helper scripts (Python etc.) go in `~/functions/<area>/`.
  - Update the README tables when you add or remove any of these.
- **Must work on native Linux and WSL.** Shared code goes in `.zshrc` / the topic files.
  - Platform-only code goes in `~/.zsh/conf/linux.zsh` or `wsl.zsh`; check `$IS_WSL` (zsh) or
    `_is_wsl` (packages.zsh).
  - Guard optional tools with `(( $+commands[tool] ))`.
- **`refresh` re-sources `.zshrc` from inside a function**, where a plain `typeset` makes a
  local variable. Use `typeset -g` for anything top-level in `.zshrc` and `~/.zsh/conf/*.zsh`.
- **`packages.zsh` must stay bash-compatible:** `setup_terminal.sh` sources it with bash.
- **Interactive shells alias** `ls cat find grep curl rm` to `eza bat fd rg curlie rip`.
  - Inside functions and scripts the real commands are used, so write standard syntax.
  - In a shell you're driving, use `command grep …` etc. if you need the originals.
- Don't commit or push unless asked. Commit messages end with the attribution line from the
  session instructions.

## Checking changes

```sh
for f in ~/.zshrc ~/.zsh/conf/*.zsh; do zsh -n "$f"; done           # syntax
bash -n ~/.zsh/conf/packages.zsh                                     # stays bash-compatible
zsh -i -c 'echo READY'                                               # loads without errors (native)
WSL_DISTRO_NAME=Ubuntu zsh -i -c 'echo READY'                        # WSL path
zsh -i -c 'refresh; refresh; command -v brew grep'                   # re-sourcing from a function works
STARSHIP_LOG=warn starship prompt >/dev/null                         # prompt config has no warnings
for i in 1 2 3; do /usr/bin/time -f %es zsh -i -c exit; done         # startup time (~0.13s)
```
