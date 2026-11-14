#!/usr/bin/env bash
# Undo install.sh: remove the configs it installed and restore the backup it made.
#
#   ./uninstall.sh
#
# Installed configs are moved to ~/.config-backups/arch-setup-removed-<time>/
# rather than deleted (symlinks to this repo are simply removed). Packages,
# services and wallpapers are left as they are.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/arch-setup"
REMOVED_DIR="$HOME/.config-backups/arch-setup-removed-$(date '+%Y%m%d-%H%M%S')"
# Backups made by install.sh, oldest first; the oldest copy of a path is the original.
mapfile -t BACKUPS < "$STATE_DIR/backups" 2>/dev/null || BACKUPS=()

remove() {
    # remove <path relative to CONFIG_DIR>
    local target="$CONFIG_DIR/$1"
    if [[ -L "$target" && "$(readlink -f "$target")" == "$REPO_DIR/"* ]]; then
        rm "$target"
    elif [[ -e "$target" ]]; then
        mkdir -p "$(dirname "$REMOVED_DIR/$1")"
        mv "$target" "$REMOVED_DIR/$1"
    fi
}

systemctl --user disable auto-color-scheme.timer >/dev/null 2>&1 || true

paths=()
for src in "$REPO_DIR/config/"*/; do
    name=$(basename "$src")
    [[ "$name" == systemd ]] && continue
    paths+=("$name")
done
for src in "$REPO_DIR/config/systemd/user/"*; do
    paths+=("systemd/user/$(basename "$src")")
done

for path in "${paths[@]}"; do
    remove "$path"
    restored=0
    for backup in "${BACKUPS[@]}"; do
        if [[ -e "$backup/$path" || -L "$backup/$path" ]]; then
            mkdir -p "$(dirname "$CONFIG_DIR/$path")"
            mv "$backup/$path" "$CONFIG_DIR/$path"
            restored=1
            break
        fi
    done
    if (( restored )); then printf 'restored  %s\n' "$path"; else printf 'removed   %s\n' "$path"; fi
done
systemctl --user daemon-reload || true

rm -f "$STATE_DIR/backups" "$STATE_DIR/mode"
[[ -d "$REMOVED_DIR" ]] && printf '\nInstalled copies were moved to %s\n' "$REMOVED_DIR"
printf 'Log out and back in (or run hyprctl reload) to finish.\n'
