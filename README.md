# terminal_config

My terminal setup. The repo **is the home folder**: `~` is the git working tree, and an
allow-list `.gitignore` means only the files listed there are tracked. Everything else in
`~` (app data, caches, secrets) is ignored by default.

It runs on **native Ubuntu** and on **WSL**. The shell is zsh: one `.zshrc` detects which
platform it's on and loads the right extras.

> ⚠️ This repo is **public**. Never commit secrets, IPs, private hostnames or `.env` files.
> Email addresses live in `~/.gitconfig.local` (read them with `git config email.<name>`).
> See [Secrets](#secrets) and [Adding scripts](#adding-scripts).

## Setting up a new machine

```sh
curl -fsSL https://raw.githubusercontent.com/amykapernick/terminal_config/prod/setup_terminal.sh | bash
```

This installs Homebrew and the base tools, turns `~` into a checkout of this repo (backing up
any existing dotfiles), pulls the submodules, creates an SSH key for GitHub, installs oh-my-zsh
(keeping this repo's `.zshrc`) and runs the package installers. It's safe to re-run.

Afterwards, copy these from another machine (they're deliberately not in git):

| File | What it's for |
|---|---|
| `~/.gitconfig.local` | Email addresses: `user.email` plus named ones like `email.ddd` (included by `.gitconfig`) |
| `~/.ssh/config` | SSH hosts (IPs, users, keys) |
| `~/.ssh/<keys>` | Private keys. On Linux, import them into 1Password instead |
| `~/.zsh/conf/ssh.zsh` | Private SSH helpers |
| `~/.env` (WSL) or `~/.env.op` (Linux) | Secrets for scripts |

## How it fits together

```
~/
├── .zshrc                  main config: PATH, oh-my-zsh, prompt, then loads ~/.zsh/conf
├── .zsh/
│   ├── conf/               zsh-only functions and aliases, one file per topic
│   │   ├── core.zsh        refresh, check, new_ssh, withenv
│   │   ├── git.zsh         git shortcuts
│   │   ├── init.zsh        new project / clone helpers
│   │   ├── nav.zsh         jump to project folders
│   │   ├── packages.zsh    install/update everything (bash-compatible, used by setup script)
│   │   ├── utils.zsh       misc utilities
│   │   ├── vscode.zsh      `code` picks a VS Code profile by folder
│   │   ├── hosts.zsh       SSH host shortcuts (no secrets)
│   │   ├── ssh.zsh         private SSH helpers (NOT in git)
│   │   ├── linux.zsh       native Linux only
│   │   ├── wsl.zsh         WSL only
│   │   ├── aliases.zsh     loaded after the functions
│   │   └── help.zsh        fhelp / Ctrl+G function finder, loaded last
│   └── plugins/            zsh plugins as git submodules
├── bin/                    own executables, on PATH
├── functions/              Python scripts the zsh functions call
├── .config/                only starship, ghostty, vicinae and modes are tracked
├── git-summary/            submodule, used by `git-check`
├── CLAUDE.md               context and rules for Claude sessions in ~
└── setup_terminal.sh
```

Load order in `.zshrc` matters:

1. Platform detection sets `IS_WSL`.
2. PATH, then oh-my-zsh, prompt and other tools.
3. The function files.
4. `linux.zsh` or `wsl.zsh`.
5. `aliases.zsh`. It comes after the functions, so functions always get the real `find`,
   `grep` and `rm`.
6. `help.zsh`, which indexes everything loaded above it.
7. zoxide, which must be last.

### Linux vs WSL

| | Native Linux | WSL |
|---|---|---|
| SSH keys | 1Password desktop app's agent (`~/.ssh/config`) | oh-my-zsh `ssh-agent` plugin loads `id_default` at startup |
| Secrets | 1Password (`~/.env.op` + `withenv`) | `~/.env`, exported into every shell |
| Links open in | Browser chosen by folder (`bin/browser-by-dir`) | Windows default browser (`wslview`) |
| Extra packages | — | `wslu`, headless Chrome/Puppeteer libraries |
| Extra functions | — | `wp`, `del_zone`, `fix_ssh` |

## Secrets

- **WSL:** `~/.env` is exported into every shell, because 1Password's WSL integration is unreliable.
- **Linux:** put `op://` references in `~/.env.op`. `~/.env.op.example` is a starting point;
  right-click a field in 1Password and choose Copy Secret Reference. Then run anything that
  needs secrets with `withenv <cmd>`. Until `~/.env.op` exists, Linux falls back to `~/.env`
  like WSL does.
- `withenv` works on both platforms, so scripts and docs can always use it.
- `.gitignore` blocks `.env` and `.env.*` everywhere. Only `.env.example` files can be committed.

## SSH

Hosts are defined in `~/.ssh/config`, which isn't in git. That means `ssh porygon`,
`scp file media:`, tab completion and VS Code Remote all work. `hosts.zsh` keeps the old
`ssh_*` command names as thin wrappers.

On Linux, keys are served by 1Password whenever the app is running. Otherwise, and on WSL,
ssh falls back to the normal agent and adds keys to it the first time they're used.

## Plugins and submodules

The zsh plugins (autosuggestions, syntax highlighting, completions) and `git-summary` are git
submodules. oh-my-zsh itself is *not* in the repo: `setup_terminal.sh` installs it.

- `update_plugins` updates oh-my-zsh and moves the plugin submodules to their latest versions.
  Commit the new versions in `~` afterwards.
- After cloning or pulling, run `git submodule update --init`.

## Functions and aliases

Type `fhelp` (or press **Ctrl+G**) to fuzzy-search everything below. While you type a
command, its usage shows under the prompt.

### Aliases (`aliases.zsh`)

| Alias | Does |
|---|---|
| `ls`, `cat`, `find`, `grep`, `curl` | `eza`, `bat`, `fd`, `rg`, `curlie`. Use `command grep …` for the original |
| `rm` | Moves files to the rip graveyard (asks first). Accepts `-rf` so pasted commands work. Empty it with `empty_trash` |
| `man <page>` | The real man, plus a reminder that `tldr` has quick examples |
| `git-check` | Summary of every git repo under the current folder (`git-summary`) |
| `utils` | `node ~/dev/terminal_utils` |

### Core (`core.zsh`)

| Function | Does |
|---|---|
| `refresh` | Reload `~/.zshrc` |
| `check` | `git-check` across `~`, then check global npm packages for updates |
| `new_ssh <name> [email]` | Create an ed25519 key (email defaults to `git config user.email`). Prints the 1Password import step on Linux; adds it to the agent on WSL |
| `withenv <cmd>` | Run a command with secrets from 1Password (Linux) or `~/.env` |

### Git (`git.zsh`)

| Function | Does |
|---|---|
| `pushit "<msg>"` / `commit "<msg>"` | Stage everything and commit (and push) |
| `branch <name>` | Create and switch to a branch |
| `upstream <branch>` | Track `origin/<branch>` |
| `main_branch` | Rename `master` to `prod` and push |
| `gh_ssh <key> <title>` | Upload a public key to GitHub |
| `ssh_clone <url> <key>` | Clone with a specific SSH key and keep using it for that repo |

### Projects and navigation (`init.zsh`, `nav.zsh`, `vscode.zsh`)

| Function | Does |
|---|---|
| `i_node <name>` | New Node project: folder, git, licence, .gitignore, CoC, GitHub remote, first commit |
| `i_doppler <project>` | Write `doppler.yaml` and run `doppler setup` |
| `clone <url>` | Clone, cd in, `npm install`, copy `.env.example` to `.env` |
| `web` / `dev` / `train` / `makerx [project]` | Jump to `~/web`, `~/dev`, `~/training`, `~/makerx` (or a project inside) |
| `code [args] [folder]` | VS Code with a profile picked by folder (`VSCODE_PROFILES`) |

### Utilities (`utils.zsh`)

| Function | Does |
|---|---|
| `gen_colours [--gutenberg]` | Colour styles from pasted Sass variables, copied to the clipboard |
| `gen_fonts [folder]` | Font CSS from a fonts folder (script currently missing, see TODO) |
| `del_files <ext>` | Delete every file with an extension under the current folder (asks first) |
| `start` | `npm start --if-present`, then `npm run dev` |
| `cleanup` | Prune Docker, apt, npm, pip and brew caches, and empty the rip trash |
| `sssh <user> <ip> [key]` | One-off SSH with `~/.ssh/<key>` |

### Packages (`packages.zsh`)

| Function | Does |
|---|---|
| `update` | Everything: apt, brew, oh-my-zsh + plugins, Node LTS, all package lists |
| `install_brew` / `install_utilities` / `install_global` / `install_pip` / `install_other` | Install the brew, apt, npm, pip and other tool lists. `install_utilities` adds the WSL extras on WSL |
| `install_pay_respects` | pay-respects (the `fuck` command) from GitHub releases, without its AI module |
| `update_ubuntu` / `upgrade_ubuntu_release` | apt upgrade / move to the next Ubuntu release |
| `update_node [version]` | Install and switch Node with fnm, then reinstall the global npm tools |
| `update_plugins` | oh-my-zsh and the plugin submodules |
| `install_eslint` / `install_stylelint` / `update_doppler` | Project and tool installers |

### SSH (`hosts.zsh`) and WSL-only (`wsl.zsh`)

- **`hosts.zsh`:** `porygon` and `ssh_media`, `ssh_hassio`, `ssh_pihole`, `ssh_ditto`,
  `ssh_rotom`, `ssh_jirachi`, `ssh_yow`, `ssh_flywheel`, `ssh_strapi`, `ssh_remarkable`
  connect to the matching `~/.ssh/config` host. `copy_remarkable` uploads `*.svg`/`*.png`
  templates to the reMarkable.
- **`wsl.zsh`:** `wp <site> [theme]` jumps to a Local WP theme under `~/windows`.
  `del_zone` deletes `Zone.Identifier` files. `fix_ssh` re-adds `id_default` to the agent.

## Custom scripts

### `~/bin` (on PATH)

| Script | Does |
|---|---|
| `browser-by-dir/xdg-open` | Sends web links to `$BROWSER`, which `linux.zsh` sets by folder (Chrome in `~/makerx`, Firefox in `~/web`). Only on PATH inside those folders |
| `open-sunsama-pwa` | Waits for the local Open Sunsama app (`localhost:3002`), then opens its Edge PWA. Started by `~/.config/autostart/open-sunsama.desktop` |
| `pika-backup-check` | Pika Backup's pre-backup check. Cancels the backup on low battery (≤20%) or a metered connection |
| `orca-captions` | Launcher for `~/dev/orca-captions` (Orca speech as OBS captions) |

### `~/functions` (called by functions or run directly)

| Script | Does |
|---|---|
| `project_styles/gen_colours.py` | Used by `gen_colours` |
| `gh-bulk-issues.py` | Create GitHub issues in bulk from a markdown file (see `bulk_issues.md`) |
| `transcribe_video.py` | Video to timestamped transcription |
| `mealie/import_notion.py` | Migrate recipes from a Notion database into Mealie (`withenv` for the tokens) |
| `mealie/import_from_media.py` | Recipe photos to Mealie via Azure OpenAI vision |

### App config (`~/.config`)

Only the folders and files listed in `.gitignore` are tracked. The rest of `~/.config` stays
ignored: it holds browser profiles, logins and tokens (`gh/`, `1Password/`, `Code/`, `dconf/`...).

| Path | What |
|---|---|
| `starship.toml` | Prompt |
| `ghostty/config` | Terminal: font, Catppuccin theme, keybinds |
| `vicinae/settings.json` | Launcher settings |
| `modes/` | Work modes (Default, MakerX, AimHigher, DDD Perth) for the `mode` command from `~/dev/linux-widgets`. Only used on this machine for now; may move to a separate Linux-specific package |

## Adding scripts

Where new things go. This applies to people and to AI coding agents.

1. **A command you type in the terminal** → a function in `~/.zsh/conf/<topic>.zsh`.
   - Use an existing topic file, or add a new one *and* add it to the `for _f in …` list in
     `.zshrc`.
   - Put a comment directly above the function, and a `# usage: name <required> [optional=default]`
     line, so `fhelp` and the live hints can find it.
   - Write it in zsh. The exception is `packages.zsh`, which must stay bash-compatible
     because `setup_terminal.sh` sources it.
   - Only for Linux or only for WSL? Put it in `linux.zsh` / `wsl.zsh` instead.
   - Don't rely on the aliases inside functions: functions get the real `find`/`grep`/`rm`.
2. **A standalone executable** (called by apps, autostart entries, other tools, or worth
   running outside zsh) → `~/bin/<name>`.
   - Give it a shebang, `chmod +x` and a comment at the top saying what it does.
   - Add it to the [`~/bin` table](#bin-on-path).
   - Reference it by full path (`/home/amy/bin/<name>`) from `.desktop` files and app settings.
   - Don't put your own scripts in `~/.local/bin`. That belongs to installers and isn't tracked.
3. **A longer script a function calls** (Python etc.) → `~/functions/<area>/`.
   - Read secrets from environment variables and run it with `withenv`. Never hardcode keys.
   - If it needs config, commit a `.env.example`, never a `.env`.
4. **Anything private** (IPs, internal hostnames, tokens, email addresses) → keep it out of git:
   `~/.gitconfig.local`, `~/.ssh/config`,
   `~/.zsh/conf/ssh.zsh`, `~/.env` / `~/.env.op`.
5. **New file or folder to track?** Add a `!/path` line to `.gitignore`, with any comment on
   *its own line* (git doesn't support comments at the end of a pattern line). Check with
   `git status` before committing.
6. **New package to install?** Add it to the right list in `packages.zsh`. Anything only WSL
   needs goes inside the `_is_wsl` block.

## TODO

Left over from the Linux/WSL cleanup (Nov 2026).

### This machine (native Linux)

- [ ] **Import SSH keys into 1Password** (New Item › SSH Key › Import) so the 1Password agent
      serves them. It only has `remarkable` so far. `makerx` matters most: it has a passphrase, so
      until it's imported you get asked for it every time.
- [ ] **Move secrets to 1Password:** fill in `~/.env.op.example`, rename it to `~/.env.op`, and
      run scripts with `withenv`. Once that works, `~/.env` can be deleted on Linux.

### Repo

- [ ] **`gen_fonts` is broken:** `functions/project_styles/gen_fonts.py` isn't in the repo or on
      this machine. Find it on another machine and commit it, or remove `gen_fonts` from `utils.zsh`.
- [ ] **`utils` alias** points to `~/dev/terminal_utils`, which doesn't exist here. Clone it or
      remove the alias from `aliases.zsh`.
- [ ] **Push** the restructure commits to GitHub.

### Each WSL machine (after `git pull` in `~`)

- [ ] `git submodule update --init` (zsh plugins + git-summary)
- [ ] Delete `~/.zplug` (replaced by `~/.zsh/plugins`)
- [ ] If `~/.oh-my-zsh/oh-my-zsh.sh` is missing (the pull stops tracking oh-my-zsh), reinstall it:
      `RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- [ ] Copy over the new `~/.ssh/config` (the host shortcuts in `hosts.zsh` need it). `ssh.zsh` is
      now only for private helpers, so copy it only if you've put something in it.
- [ ] Run `install_pay_respects`, and `install_utilities` for `wslu` and the updated Chrome libraries
