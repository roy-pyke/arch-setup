#!/usr/bin/env bash

# Give btop more terminal cells in a floating window without changing other
# Kitty windows. Its full dashboard needs at least 80 columns and 24 rows.
if command -v btop >/dev/null 2>&1; then
    exec kitty -o font_size=7.5 --title "System Monitor" btop
elif command -v htop >/dev/null 2>&1; then
    exec kitty --title "System Monitor" htop
else
    notify-send "System Monitor" "Install btop or htop to open the resource monitor."
    exit 1
fi
