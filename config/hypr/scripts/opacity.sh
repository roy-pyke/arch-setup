#!/usr/bin/env bash
# Pick the opacity for ordinary application windows (Super+O).
# The value is stored in local.lua so the tracked config stays untouched.

local_lua="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/local.lua"

choice=$(printf '100%%\n90%%\n80%%\n70%%\n60%%\n50%%\n40%%\n' | rofi -dmenu -no-custom -p "Opacity") || exit 0

case "$choice" in
    100%) opacity=1.0 ;;
    90%)  opacity=0.9 ;;
    80%)  opacity=0.8 ;;
    70%)  opacity=0.7 ;;
    60%)  opacity=0.6 ;;
    50%)  opacity=0.5 ;;
    40%)  opacity=0.4 ;;
    *) exit 0 ;;
esac

touch "$local_lua"
if grep -q '^window_opacity = ' "$local_lua"; then
    sed -i "s/^window_opacity = .*/window_opacity = $opacity/" "$local_lua"
else
    printf '\n-- Set by Super+O.\nwindow_opacity = %s\n' "$opacity" >> "$local_lua"
fi

hyprctl reload >/dev/null
