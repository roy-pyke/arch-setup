# arch-setup

Installable Hyprland desktop for Arch Linux. No build system and no test suite.
README.md is the user documentation; keep it in sync when behaviour changes.

## Layout

- `config/<dir>`: installed as `~/.config/<dir>` by `install.sh` (symlinked by default, `--copy` copies). Every top-level directory here is installed automatically; `config/systemd/user/*` units are linked one by one.
- `config/hypr/`: Hyprland Lua config (`hyprland.lua` defaults, `keybinds.lua`, `rules.lua`), `hypridle.conf`, `hyprlock.conf`, `scripts/`
- `config/waybar/`: bar; `scripts/` holds the brightness menu, keyboard-backlight helper, CPU temperature and optional Claude usage wrapper
- `config/toolbox/`: rofi toolbox; one script per tool in `tools/`, each supporting `label` and run
- `config/quickshell/`: `hyprquickpaper` wallpaper picker, `video-power` power menu
- `packages/core.txt`, `packages/optional.txt`: pacman packages
- `system/`: optional `/etc` changes (lid sleep, hibernation); never run by `install.sh`
- `install.sh` / `uninstall.sh`: install with backup, and restore

## Machine-specific settings

Shared files must work on any machine: no absolute paths (use `~` or `$HOME`), no hard-coded
hardware names, no personal data. Per-machine settings go in the gitignored local files:
`config/hypr/local.lua` (loaded after the defaults; monitors, devices, layouts, `window_opacity`)
and `config/toolbox/local.conf` (headphones). Document new settings in the matching
`local.example.*` file and the README.

On the maintainer's machine `~/.config/<dir>` are symlinks into this repo, so editing
`~/.config` edits the repo, and `hyprctl reload` picks it up.

## Checks

- Shell: `bash -n <script>`
- Lua: `luac -p config/hypr/*.lua`
- JSON: `python3 -m json.tool config/waybar/config.jsonc > /dev/null`
- After a Hyprland change: `hyprctl reload && hyprctl configerrors`

Keybindings, Waybar modules and menus must also be tested in a live session.

## Conventions

- Four-space indentation (Lua, QML, shell, CSS, JSONC); otherwise follow the surrounding file.
- Keybindings go in `keybinds.lua`, window rules in `rules.lua`.
- Keep executable bits on scripts.
- All user-facing text (menus, notifications, docs) is in English.
- Commits carry no AI co-author trailer.
