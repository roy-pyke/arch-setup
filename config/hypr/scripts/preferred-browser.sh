#!/usr/bin/env bash

# Use Chrome once installed, while keeping Firefox available during migration.
if command -v google-chrome-stable >/dev/null 2>&1; then
    exec google-chrome-stable "$@"
elif command -v google-chrome >/dev/null 2>&1; then
    exec google-chrome "$@"
elif command -v flatpak >/dev/null 2>&1 && flatpak info com.google.Chrome >/dev/null 2>&1; then
    exec flatpak run com.google.Chrome "$@"
elif command -v firefox >/dev/null 2>&1; then
    exec firefox "$@"
fi

printf '%s\n' 'No supported browser is installed.' >&2
exit 127
