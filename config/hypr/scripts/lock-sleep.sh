#!/usr/bin/env bash

set -eu

state_file="${XDG_RUNTIME_DIR:?}/hyprlock-sleep.state"

case "${1:-}" in
    start)
        # Each lock gets a new token, so an earlier timer cannot put a later
        # lock session to sleep after the user has unlocked and locked again.
        token=$(cat /proc/sys/kernel/random/uuid)
        umask 077
        printf '%s\n' "$token" > "$state_file"
        (
            sleep "${LOCK_SLEEP_DELAY:-120}"
            [[ -r "$state_file" ]] || exit 0
            [[ $(cat "$state_file") == "$token" ]] || exit 0
            pgrep -u "$UID" -x hyprlock >/dev/null || exit 0
            if ! systemctl suspend; then
                notify-send -u critical "Suspend failed" "Check the system sleep state and the journal."
            fi
        ) </dev/null >/dev/null 2>&1 &
        ;;
    stop)
        rm -f -- "$state_file"
        ;;
    *)
        printf 'Usage: %s {start|stop}\n' "$0" >&2
        exit 2
        ;;
esac
