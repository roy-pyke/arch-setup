# arch-setup

A ready-to-use Hyprland desktop for Arch Linux: a clean translucent look, a
Waybar top bar, a keyboard-driven rofi toolbox, lock-and-sleep handling, a
wallpaper picker, a power menu and sensible window management, installed with
one command and easy to undo.

```bash
git clone https://github.com/roy-pyke/arch-setup.git ~/arch-setup
cd ~/arch-setup
./install.sh
```

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configure it for your machine](#configure-it-for-your-machine)
- [Keybindings](#keybindings)
- [The top bar](#the-top-bar)
- [The toolbox](#the-toolbox)
- [Lock, sleep and power](#lock-sleep-and-power)
- [Windows and look](#windows-and-look)
- [Optional system setup: lid sleep and hibernation](#optional-system-setup-lid-sleep-and-hibernation)
- [Updating, customizing and uninstalling](#updating-customizing-and-uninstalling)
- [Repository layout](#repository-layout)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

---

## Features

- **Hyprland with the new Lua config**: rounded, blurred, slightly translucent
  windows with a silver-blue gradient border. New windows open floating at 70%
  of the screen and centered; `Super + A` tiles everything on the workspace.
- **Waybar top bar**: CPU, memory and CPU temperature on the left; clock and
  any running countdown in the middle; toolbox, media, battery and power on the
  right.
- **Toolbox** (`Super + X`): countdown timer, screen brightness, keyboard
  backlight, volume and Bluetooth headphones in one rofi menu. Adding your own
  tool takes one small script.
- **Lock and sleep**: the session starts locked, suspends after 2 minutes
  locked, and always locks before sleeping.
- **Power menu** (`Super + Esc`): full-screen Quickshell menu to shut down,
  restart, hibernate or log out.
- **Wallpaper picker** (`Super + W`): Quickshell carousel with thumbnails;
  each monitor remembers its wallpaper.
- **Screenshots straight to the clipboard** (never written to disk) and
  **clipboard history** (`Super + V`).
- **macOS-style shortcuts**: `Alt + C / V / A / Z` copy, paste, select all and
  undo in ordinary apps; `Alt + T / W` open and close tabs in Chrome.
- **Light/dark preference**: apps that follow the system theme switch to light
  at 07:00 and dark at 19:00.
- **Machine-specific settings stay separate** in two small local files, so you
  can pull updates without merge conflicts.
- **Safe install**: your existing configs are moved to a backup, and
  `./uninstall.sh` puts them back.

---

## Requirements

- Arch Linux (or an Arch-based distribution using pacman)
- **Hyprland with Lua configuration support** (tested with Hyprland 0.57.0).
  Older releases only read `hyprland.conf` and will not load this config.
- A user with `sudo` rights to install packages

Everything else is installed from the official repositories by `install.sh`
(see [`packages/core.txt`](packages/core.txt)); no AUR helper is needed.

---

## Installation

```bash
git clone https://github.com/roy-pyke/arch-setup.git ~/arch-setup
cd ~/arch-setup
./install.sh
```

Then log in to the **Hyprland** session from your display manager (or run
`Hyprland` from a TTY). If you are already in Hyprland, the installer reloads it
for you.

### Installer options

| Option | Effect |
| --- | --- |
| *(none)* | Install packages, **symlink** every config directory to this repository |
| `--copy` | Copy the configs instead of symlinking them |
| `--skip-packages` | Do not install packages or enable system services |
| `--with-optional` | Also install [`packages/optional.txt`](packages/optional.txt): Chinese Pinyin input (fcitx5) and Firefox |
| `--with-claude-usage` | Download the [Claude Code usage](https://github.com/Janicklin/claude-usage-waybar) Waybar module |

### What the installer does

1. Installs the packages in `packages/core.txt` with `pacman --needed`
   (safe to run again).
2. Moves each existing `~/.config/<dir>` that this repository provides
   (`hypr`, `waybar`, `rofi`, `dunst`, `kitty`, `quickshell`, `toolbox`,
   `fcitx5`, `gtk-3.0`, `gtk-4.0`, `btop`, `Thunar`) to
   `~/.config-backups/arch-setup-<time>/`.
3. Symlinks (default) or copies `config/<dir>` to `~/.config/<dir>`, and the
   systemd user units into `~/.config/systemd/user/`.
4. Creates your machine-specific files `~/.config/hypr/local.lua` and
   `~/.config/toolbox/local.conf` from their examples (an existing
   `hypr/local.lua` from your previous config is kept).
5. Copies the wallpapers to `~/Pictures/Wallpapers` (existing files are not
   overwritten).
6. Enables PipeWire, Bluetooth, NetworkManager and the light/dark timer.

It never modifies `/etc`. Lid sleep and hibernation are separate, optional
scripts; see [below](#optional-system-setup-lid-sleep-and-hibernation).

**Symlink or copy?** With symlinks (the default), `git pull` updates your
desktop immediately and anything you change in `~/.config` shows up in
`git diff`. Choose `--copy` if you want to delete the repository afterwards or
keep your configs independent of it.

---

## Configure it for your machine

The shared config works on any machine: monitors use their preferred mode with
automatic scaling, and the backlight, battery and CPU temperature sensors are
detected automatically. Settings that only make sense for your hardware go into
two local files, which git ignores:

### `~/.config/hypr/local.lua`

Loaded after the defaults in `hyprland.lua`, so anything here overrides them.
Find names with `hyprctl monitors` and `hyprctl devices`.

```lua
-- Monitors: name, mode, position, scale
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.5 })
hl.monitor({ output = "HDMI-A-1", mode = "3840x2160@60", position = "auto", scale = 1.5 })

-- Pin workspaces 1-5 to the external monitor and 6-10 to the laptop
for i = 1, 10 do
    hl.workspace_rule({
        workspace = tostring(i),
        monitor = i <= 5 and "HDMI-A-1" or "eDP-1",
        default = i == 1 or i == 6,
    })
end

-- Keyboard layouts (Super+Z cycles through them)
hl.config({ input = { kb_layout = "us,de", kb_options = "caps:ctrl_shifted_capslock" } })

-- Per-device pointer speed
hl.device({ name = "your-touchpad-name", sensitivity = 0.0 })

-- Opacity of ordinary application windows (Super+O updates this line)
window_opacity = 0.8
```

### `~/.config/toolbox/local.conf`

```bash
# Bluetooth headphones for the toolbox (find the address with `bluetoothctl devices`)
HEADPHONES_MAC="AA:BB:CC:DD:EE:FF"
HEADPHONES_NAME="AirPods"
```

Without an address, the headphones entry is simply hidden.

### Other things you may want to change

| What | Where |
| --- | --- |
| Light/dark switch times (07:00 / 19:00) | `hypr/scripts/auto-color-scheme.sh` and `systemd/user/auto-color-scheme.timer`, then `systemctl --user daemon-reload` |
| Minutes locked before suspending | `LOCK_SLEEP_DELAY` (seconds, default 120) in `hypr/scripts/lock-sleep.sh` |
| Wallpaper folder | `quickshell/hyprquickpaper/config.json` |
| Default apps (terminal, launcher, file manager) | top of `hypr/hyprland.lua` |
| Browser for `Super + B` | `hypr/scripts/preferred-browser.sh` (Google Chrome if installed, else Firefox) |
| Backlight device | set `BACKLIGHT_DEVICE` if the first one found is not your screen |

---

## Keybindings

`Super` is the Windows key. All bindings live in
[`config/hypr/keybinds.lua`](config/hypr/keybinds.lua).

### Apps and menus

| Keys | Action |
| --- | --- |
| `Super + T` | Terminal (kitty) |
| `Super + D` | App launcher (rofi) |
| `Super + E` | File manager (Thunar) |
| `Super + B` | Browser |
| `Super + M` | Resource monitor (btop) |
| `Super + X` | **Toolbox** (press again to close) |
| `Super + W` | Wallpaper picker |
| `Super + V` | Clipboard history |
| `Super + O` | Window opacity |
| `Super + Esc` | Power menu |
| `Super + Tab` | Lock screen |
| `Super + Shift + W` | Show / hide the top bar |
| `Super + Shift + E` | Exit Hyprland |

### Screenshots

| Keys | Action |
| --- | --- |
| `Delete` | Screenshot of a selected area to the clipboard |
| `Super + Delete` | Full-screen screenshot to the clipboard |

Screenshots are never saved to disk and are kept out of the clipboard history.
Cancelling the selection leaves the clipboard untouched.

### Windows

| Keys | Action |
| --- | --- |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + Space` | Toggle floating (a window that becomes floating is resized to 60% and centered) |
| `Super + A` | Tile every window on the current workspace (leaves fullscreen and floating) |
| `Super + H / J / K / L` | Focus left / down / up / right |
| `Super + Shift + H / J / K / L` | Move window |
| `Super + Ctrl + H / J / K / L` | Resize window (hold to repeat) |
| `Super + left drag` | Move window |
| `Super + right drag` | Resize window |

### Workspaces

| Keys | Action |
| --- | --- |
| `Super + 1 … 0` | Go to workspace 1–10 |
| `Super + Shift + 1 … 0` | Move window to workspace 1–10 |
| `Super + U / I` | Previous / next workspace on this monitor |

### macOS-style

| Keys | Action |
| --- | --- |
| `Alt + C / V / A / Z` | Copy / paste / select all / undo (sent as `Ctrl + …`) |
| `Alt + Shift + Z` | Redo |
| `Alt + T / W` | New / close tab (Google Chrome only) |

kitty and VS Code receive these keys unchanged, since they have their own
clipboard shortcuts. In kitty, `Alt + C / V` copy and paste and `Ctrl + Esc`
sends `Ctrl + C`.

### Other

| Keys | Action |
| --- | --- |
| `Super + Z` | Next keyboard layout |
| `Ctrl + Space` | Switch input method (with the optional fcitx5 packages) |
| Media keys | Volume, mute, play/pause, next / previous (also on the lock screen) |

---

## The top bar

```
[ CPU · RAM · temp · Claude usage ]     [ date time · 󰔛 countdown ]     [ 󰦬 toolbox · media · battery · ⏻ ]
```

- **Left**: CPU, memory (hover for used/total), CPU temperature (red from
  80 °C), and the optional Claude Code usage module.
- **Center**: clock (hover for a calendar). While a countdown runs, its time
  left appears next to the clock; click it to pause, resume or cancel.
- **Right**: toolbox button, now playing, battery (yellow at 20%, red at 10%,
  with a notification), power menu.

Modules that have nothing to show (no battery, no temperature sensor, no Claude
usage module) hide themselves.

---

## The toolbox

Press `Super + X` or click `󰦬` in the bar. Every entry shows its current state:

| Tool | What it does |
| --- | --- |
| 󰔛 Countdown | Asks for a duration and starts. Accepts `25` (minutes), `25m`, `90s`, `1h30m`, `1h 30m`, `10:00`, `1:00:00`; add a note after the time, e.g. `25m write report`. Several can run at once. When one ends you get a **silent** notification that stays until you dismiss it. |
| 󰃠 Brightness | 100% to 10%, through logind, so no root or udev rule is needed |
| 󰌌 Keyboard backlight | Lists the hardware levels (e.g. Off / 50% / 100%) |
| 󰕾 Volume | Mute, 100% to 10%, or open pavucontrol |
| 󰋋 Headphones | Connects your Bluetooth headphones and switches audio to them, or disconnects them (shows the battery level when available) |

Entries hide themselves when the hardware is missing (no backlight, no keyboard
backlight, no headphones configured).

### Add your own tool

Drop an executable script into `config/toolbox/tools/`. The number in the file
name sets its position. A tool answers two calls:

```bash
#!/usr/bin/env bash
case "${1:-run}" in
    label) echo "󰆍  My tool" ;;        # the menu line; print nothing to hide it
    *)     notify-send "Hello" ;;       # what happens when you pick it
esac
```

---

## Lock, sleep and power

| When | What happens |
| --- | --- |
| You log in | The session locks immediately (hyprlock, over a blurred screenshot) |
| The screen is locked | After 2 minutes the machine suspends; unlocking cancels it, and every new lock starts a fresh timer |
| The machine is about to sleep | It locks first and waits until the lock screen is visible |
| You close the lid | Suspend (after running `system/lid-sleep.sh`) |
| `Super + Esc` or `⏻` | Shut down / restart / hibernate / log out (falls back to a rofi menu if Quickshell fails) |

Hibernate works once hibernation is set up; see the next section.

---

## Windows and look

- Gaps 3 / 5 px, rounding 8, 3 px silver-blue gradient border, blur and shadow.
- New ordinary windows float at 70% of the monitor, centered. Dialogs keep the
  size their application asks for, and windows that open fullscreen are brought
  back to a normal size.
- Opacity: kitty, Thunar, Firefox, Discord, Spotify, pavucontrol and similar
  apps use `window_opacity` (`Super + O`, 100%–40%). Chrome, Obsidian, Sioyek
  and VS Code are 0.9 active / 0.85 inactive, and fully opaque in fullscreen.
- Always floating: pavucontrol, the network connection editor, the Bluetooth
  manager, and open/save file dialogs.
- Per-app scroll speed: faster mouse wheel in Chrome and VS Code, tuned
  touchpad scrolling in Chrome, VS Code, kitty and Obsidian.
- GTK apps use Breeze Dark with Breeze icons and cursors; rofi and dunst are
  blurred, translucent dark panels.
- Apps that follow the system color scheme get `prefer-light` from 07:00 to
  19:00 and `prefer-dark` otherwise. The desktop theme itself does not change.

---

## Optional system setup: lid sleep and hibernation

These scripts change files in `/etc`, so they are not part of `install.sh`.
Read them first; both check their requirements and change nothing if a check
fails.

### Suspend on lid close

```bash
bash system/lid-sleep.sh        # from a terminal inside Hyprland, without sudo
```

Installs [`system/etc/systemd/logind.conf.d/95-lid-sleep.conf`](system/etc/systemd/logind.conf.d/95-lid-sleep.conf):
closing the lid suspends on battery, on AC power and when docked, and suspend
becomes the default sleep operation. The script then verifies the settings took
effect.

### Hibernation

```bash
sudo bash system/hibernation.sh
```

Creates a swap file at `/swapfile` (as large as your RAM, or `SWAP_SIZE_GIB`)
and adds it to `/etc/fstab` (backed up first). systemd stores the resume
location in an EFI variable, so no kernel parameters are needed. Requirements,
all checked by the script:

- UEFI boot with writable EFI variables and kernel lockdown off
- an initramfs built with the mkinitcpio `systemd` hook
  (set `INITRAMFS` if yours is not `/boot/initramfs-linux.img`)
- an ext4 root file system with enough free space, and no swap configured yet

---

## Updating, customizing and uninstalling

**Update** (symlink install):

```bash
cd ~/arch-setup && git pull && hyprctl reload
```

Restart Waybar with `Super + Shift + W` twice if the bar changed. With a
`--copy` install, run `./install.sh --copy --skip-packages` again after pulling;
your previous configs and local files are kept.

**Customize**: with a symlink install, edit files in `~/.config` as usual. The
changes are in the repository, so `git diff` shows them and you can commit them
to your own fork. Keep hardware-specific tweaks in the two local files.

**Uninstall**:

```bash
./uninstall.sh
```

Removes the installed configs (symlinks are deleted, copies are moved to
`~/.config-backups/arch-setup-removed-<time>/`) and restores the configs the
installer backed up. Packages, services and wallpapers are left in place.

---

## Repository layout

```
arch-setup/
├── install.sh / uninstall.sh
├── packages/
│   ├── core.txt               # required packages
│   └── optional.txt           # Chinese input, Firefox
├── config/                    # becomes ~/.config/<dir>
│   ├── hypr/                  # hyprland.lua, keybinds.lua, rules.lua, local.example.lua,
│   │   └── scripts/           #   hypridle.conf, hyprlock.conf; helper scripts
│   ├── waybar/                # bar config and style; scripts/ (brightness, keyboard backlight,
│   │                          #   CPU temperature, Claude usage)
│   ├── toolbox/               # toolbox.sh, local.example.conf, tools/
│   ├── quickshell/            # hyprquickpaper (wallpaper picker), video-power (power menu)
│   ├── rofi/ dunst/ kitty/ btop/ Thunar/ fcitx5/ gtk-3.0/ gtk-4.0/
│   └── systemd/user/          # light/dark preference timer
├── system/                    # optional /etc changes: lid sleep, hibernation
└── wallpapers/
```

---

## Troubleshooting

- **No notifications**: check that dunst is running (`pgrep dunst`); start it
  with `dunst &` or log in again.
- **Hyprland shows a config error after install**: make sure your Hyprland
  is a release with Lua config support (`hyprctl version`; tested with 0.57.0), then check
  `~/.config/hypr/local.lua`.
- **Wrong monitor scaling or layout**: set your monitors in
  `~/.config/hypr/local.lua` (`hyprctl monitors` lists their names).
- **Brightness cannot be changed**: brightness goes through logind, which only
  allows the active local session; run it from inside Hyprland. If you have
  several backlight devices, set `BACKLIGHT_DEVICE`.
- **Headphones do not connect**: make sure they are paired once with
  `bluetoothctl` (`pair`, `trust`), out of the case, and not connected to
  another device.
- **Hibernate fails**: run `system/hibernation.sh` first, and check
  `journalctl -b -1` after a failed resume.

---

## Credits

- Started from 43PR's Hyprland dotfiles
  ([video](https://www.youtube.com/watch?v=kYZ5mkGuQEg)); the wallpapers come
  from that collection.
- Wallpaper picker based on [hyprquickpaper](https://github.com/iamsurjog/hyprquickpaper).
- Optional Claude Code usage module: [claude-usage-waybar](https://github.com/Janicklin/claude-usage-waybar).
