#!/usr/bin/env bash

set -euo pipefail

# Light from LIGHT_START to LIGHT_END (local time, 24-hour clock).
# Keep these hours in sync with the OnCalendar lines in auto-color-scheme.timer.
LIGHT_START=7
LIGHT_END=19

hour=$(date +%H)
if (( 10#$hour >= LIGHT_START && 10#$hour < LIGHT_END )); then
    scheme=prefer-light
else
    scheme=prefer-dark
fi

# Only set the preference consumed by applications; leave desktop themes alone.
current=$(gsettings get org.gnome.desktop.interface color-scheme)
if [[ "$current" != "'$scheme'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme "$scheme"
fi
