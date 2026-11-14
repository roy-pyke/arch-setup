#!/usr/bin/env bash
# arch-setup installer (Arch Linux + Hyprland)
#
# Usage: ./install.sh [options]
#
#   --copy               copy the configs instead of symlinking them to this repo
#   --skip-packages      do not install packages
#   --with-optional      also install packages/optional.txt (Chinese input, Firefox)
#   --with-claude-usage  download the Claude Code usage module for Waybar
#   -h, --help           show this help
#
# What it does:
#   1. installs packages/core.txt with pacman (--needed, safe to re-run)
#   2. moves every ~/.config/<dir> that this repo provides to
#      ~/.config-backups/arch-setup-<time>/ (uninstall.sh restores it)
#   3. links (or copies) config/<dir> to ~/.config/<dir>, and the systemd user
#      units into ~/.config/systemd/user/
#   4. creates the machine-specific files hypr/local.lua and toolbox/local.conf
#      from their examples (kept across re-installs, never tracked by git)
#   5. copies the wallpapers to ~/Pictures/Wallpapers
#   6. enables PipeWire, Bluetooth, NetworkManager and the light/dark timer
#
# It never touches /etc; see system/ for lid sleep and hibernation.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/arch-setup"
BACKUP_DIR="$HOME/.config-backups/arch-setup-$(date '+%Y%m%d-%H%M%S')"

MODE=link
PACKAGES=1
OPTIONAL=0
CLAUDE_USAGE=0

for arg in "$@"; do
    case "$arg" in
        --copy)              MODE=copy ;;
        --skip-packages)     PACKAGES=0 ;;
        --with-optional)     OPTIONAL=1 ;;
        --with-claude-usage) CLAUDE_USAGE=1 ;;
        -h|--help)           sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) printf 'unknown option: %s (see --help)\n' "$arg" >&2; exit 2 ;;
    esac
done

info()    { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$1"; }
ok()      { printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
warn()    { printf '  \033[1;33m!\033[0m %s\n' "$1"; }
die()     { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

# --------------------------------------------------
# Checks
# --------------------------------------------------

(( EUID != 0 )) || die "do not run as root; the script calls sudo when it needs to."
[[ -f /etc/arch-release ]] || die "this installer is for Arch Linux."

# --------------------------------------------------
# Packages
# --------------------------------------------------

if (( PACKAGES )); then
    command -v sudo >/dev/null || die "sudo is required to install packages (or use --skip-packages)."
    lists=("$REPO_DIR/packages/core.txt")
    (( OPTIONAL )) && lists+=("$REPO_DIR/packages/optional.txt")
    mapfile -t pkgs < <(grep -hvE '^\s*(#|$)' "${lists[@]}")
    info "Installing ${#pkgs[@]} packages"
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    ok "packages installed"
fi

# --------------------------------------------------
# Configs
# --------------------------------------------------

backup() {
    # backup <path relative to CONFIG_DIR>: move it into BACKUP_DIR.
    mkdir -p "$(dirname "$BACKUP_DIR/$1")"
    mv "$CONFIG_DIR/$1" "$BACKUP_DIR/$1"
}

points_here() {
    [[ -L "$1" && "$(readlink -f "$1")" == "$(readlink -f "$2")" ]]
}

info "Installing configs ($MODE mode) into $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

for src in "$REPO_DIR/config/"*/; do
    src=${src%/}
    name=$(basename "$src")
    [[ "$name" == systemd ]] && continue
    target="$CONFIG_DIR/$name"

    if points_here "$target" "$src"; then
        ok "$name (already linked)"
        continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        backup "$name"
    fi
    if [[ "$MODE" == link ]]; then
        ln -s "$src" "$target"
    else
        cp -a "$src" "$target"
    fi
    ok "$name"
done

# systemd user units are linked or copied one by one, so units from other
# software in ~/.config/systemd/user stay where they are.
mkdir -p "$CONFIG_DIR/systemd/user"
for src in "$REPO_DIR/config/systemd/user/"*; do
    [[ -f "$src" ]] || continue
    rel="systemd/user/$(basename "$src")"
    target="$CONFIG_DIR/$rel"
    if points_here "$target" "$src" || { [[ "$MODE" == copy ]] && cmp -s "$src" "$target"; }; then
        continue
    fi
    [[ -e "$target" || -L "$target" ]] && backup "$rel"
    if [[ "$MODE" == link ]]; then ln -s "$src" "$target"; else cp -a "$src" "$target"; fi
done
ok "systemd user units"

# Machine-specific files: keep the ones from the backup, otherwise start from the examples.
for pair in "hypr/local.lua:hypr/local.example.lua" "toolbox/local.conf:toolbox/local.example.conf"; do
    file=${pair%%:*}
    example=${pair#*:}
    if [[ ! -e "$CONFIG_DIR/$file" ]]; then
        if [[ -e "$BACKUP_DIR/$file" ]]; then
            cp -a "$BACKUP_DIR/$file" "$CONFIG_DIR/$file"
            ok "$file (kept from your previous config)"
        else
            cp "$CONFIG_DIR/$example" "$CONFIG_DIR/$file"
            ok "$file (created from $(basename "$example"); edit it for this machine)"
        fi
    fi
done

find "$REPO_DIR/config" -type f -name '*.sh' -exec chmod +x {} +

if [[ -d "$BACKUP_DIR" ]]; then
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$BACKUP_DIR" >> "$STATE_DIR/backups"
    ok "previous configs moved to $BACKUP_DIR"
fi
mkdir -p "$STATE_DIR"
printf '%s\n' "$MODE" > "$STATE_DIR/mode"

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------

info "Wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers"
cp -n "$REPO_DIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true
ok "~/Pictures/Wallpapers"

# --------------------------------------------------
# Services
# --------------------------------------------------

info "Services"
systemctl --user daemon-reload
if systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service >/dev/null 2>&1; then
    ok "PipeWire"
else
    warn "could not enable PipeWire; run this again from a graphical session"
fi
if systemctl --user enable auto-color-scheme.timer >/dev/null 2>&1; then
    ok "auto-color-scheme.timer"
else
    warn "could not enable auto-color-scheme.timer"
fi
if (( PACKAGES )); then
    if sudo systemctl enable --now bluetooth.service NetworkManager.service >/dev/null 2>&1; then
        ok "Bluetooth and NetworkManager"
    else
        warn "could not enable bluetooth.service / NetworkManager.service"
    fi
else
    warn "skipped system services; enable them with: sudo systemctl enable --now bluetooth NetworkManager"
fi

# --------------------------------------------------
# Optional: Claude Code usage module
# --------------------------------------------------

if (( CLAUDE_USAGE )); then
    info "Claude Code usage module"
    dest="${XDG_DATA_HOME:-$HOME/.local/share}/claude-usage-waybar"
    if [[ -d "$dest" ]]; then
        ok "already installed in $dest"
    elif git clone --depth 1 https://github.com/Janicklin/claude-usage-waybar.git "$dest" >/dev/null 2>&1; then
        ok "installed in $dest"
    else
        warn "download failed; the module stays hidden"
    fi
fi

# --------------------------------------------------
# Reload a running session
# --------------------------------------------------

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null 2>&1 || true
    pkill -SIGUSR2 -x waybar 2>/dev/null || true
fi

info "Done"
cat <<EOF
  Next steps:
  - Edit ~/.config/hypr/local.lua for this machine (monitors, keyboard layout, devices).
  - Optional: set your headphones in ~/.config/toolbox/local.conf.
  - Optional: lid sleep and hibernation, see system/ and the README.
  - Log in to the Hyprland session (or it was just reloaded if already running).
  Undo everything with ./uninstall.sh
EOF
