# Terminal config TODO

Left over from the Linux/WSL cleanup (Nov 2026).

## This machine (native Linux)

- [ ] **Import SSH keys into 1Password** (New Item › SSH Key › Import) so the 1Password agent serves them.
      It only has `remarkable` so far. `makerx` matters most: it has a passphrase, so until it's imported
      you get asked for it every time.
- [ ] **Copy the missing server keys** onto this machine: `yow`, `do_strapi`, `flywheelGithubAction`
      (the `yow`/`strapi`/`flywheel` hosts in `~/.ssh/config` won't connect without them).
- [ ] **Move secrets to 1Password:** fill in `~/.env.op.example` with `op://` references
      (right-click a field › Copy Secret Reference), rename it to `~/.env.op`, then run scripts with
      `withenv <cmd>`. Once that works, `~/.env` can be deleted on Linux.

## Repo

- [ ] **`gen_fonts` is broken:** `functions/project_styles/gen_fonts.py` isn't in the repo or on this
      machine. Find it on another machine and commit it, or remove `gen_fonts` from `.zsh/conf/utils.zsh`.
- [ ] **`utils` alias** points to `~/dev/terminal_utils`, which doesn't exist here. Clone it or remove
      the alias from `.zsh/conf/aliases.zsh`.
- [ ] **Push** the restructure commits to GitHub.

## Each WSL machine (after `git pull` in `~`)

- [ ] `git submodule update --init` (zsh plugins + git-summary)
- [ ] Delete `~/.zplug` (replaced by `~/.zsh/plugins`)
- [ ] If `~/.oh-my-zsh/oh-my-zsh.sh` is missing (the pull stops tracking oh-my-zsh), reinstall it:
      `RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- [ ] Copy over the new `~/.ssh/config` (host entries replace the old `ssh_*` IPs). Also copy
      `~/.zsh/conf/ssh.zsh` if you want the old command names. Neither is in git.
- [ ] Run `install_pay_respects`, and `install_utilities` for `wslu` and the updated Chrome libraries
