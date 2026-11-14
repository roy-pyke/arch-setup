#!/usr/bin/env bash

set -o pipefail

case "${1:-area}" in
    area)
        # Cancelling the selection must leave the existing clipboard untouched.
        geometry=$(slurp) || exit 0
        [[ -n "$geometry" ]] || exit 0
        screenshot=$(grim -t png -g "$geometry" - | base64 -w 0) || exit 1
        ;;
    full)
        screenshot=$(grim -t png - | base64 -w 0) || exit 1
        ;;
    *)
        printf 'Usage: %s [area|full]\n' "$0" >&2
        exit 2
        ;;
esac

# Wait for a successful capture before replacing the clipboard, without
# writing the screenshot to a file. Base64 keeps the PNG safe in a shell value.
[[ -n "$screenshot" ]] || exit 1
# The sensitive hint also keeps cliphist from storing screenshots on disk.
printf '%s' "$screenshot" | base64 --decode | wl-copy --sensitive --type image/png
