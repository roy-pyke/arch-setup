#!/usr/bin/env bash
# Screen brightness: reuses the Waybar brightness menu. Hidden without a backlight.

menu="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/scripts/brightness-menu.sh"

case "${1:-run}" in
    label)
        percent=$("$menu" percent 2>/dev/null) || exit 0
        echo "󰃠  Brightness  ${percent}%"
        ;;
    *)
        exec "$menu"
        ;;
esac
