#!/usr/bin/env bash
# Bluetooth headphones: connect (and switch audio to them) or disconnect.
#
# Set HEADPHONES_MAC (and optionally HEADPHONES_NAME) in ../local.conf or the
# environment; without an address the tool is hidden.
#
# Usage:
#   50-headphones.sh                     toggle: connect when disconnected, disconnect when connected
#   50-headphones.sh connect|disconnect
#   50-headphones.sh label               toolbox menu line

conf="$(dirname "$(readlink -f "$0")")/../local.conf"
# shellcheck source=/dev/null
[[ -r "$conf" ]] && source "$conf"

MAC=${HEADPHONES_MAC:-}
NAME=${HEADPHONES_NAME:-Headphones}
LOCK="${XDG_RUNTIME_DIR:-/tmp}/toolbox-headphones.lock"

[[ "$MAC" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]] || exit 0

is_connected() {
    bluetoothctl info "$MAC" 2>/dev/null | grep -q 'Connected: yes'
}

notify() {
    # In the background with a 2 s limit, so a missing notification daemon cannot block.
    ( timeout 2 notify-send -a "$NAME" -i audio-headphones "$NAME" "$1" >/dev/null 2>&1 & )
}

set_default_sink() {
    local sink
    # Wait up to ~8 s for PipeWire to create the Bluetooth output.
    for _ in $(seq 1 16); do
        sink=$(pactl list short sinks 2>/dev/null | awk -v m="bluez_output.${MAC//:/_}" '$2 ~ m {print $2; exit}')
        if [[ -n "$sink" ]]; then
            pactl set-default-sink "$sink"
            return 0
        fi
        sleep 0.5
    done
    return 1
}

do_connect() {
    bluetoothctl power on >/dev/null 2>&1
    # Connect in the background and return as soon as it is up (max 15 s).
    ( bluetoothctl connect "$MAC" >/dev/null 2>&1 & )
    for _ in $(seq 1 30); do is_connected && break; sleep 0.5; done
    if is_connected; then
        if set_default_sink; then
            notify "Connected. Audio switched to $NAME."
        else
            notify "Connected, but no audio output was found."
        fi
    else
        notify "Could not connect. Make sure they are out of the case and not connected to another device."
    fi
}

do_disconnect() {
    bluetoothctl disconnect "$MAC" >/dev/null 2>&1
    notify "Disconnected."
}

run_locked() {
    # Ignore repeated clicks while a connection attempt is running.
    mkdir "$LOCK" 2>/dev/null || exit 0
    trap 'rmdir "$LOCK" 2>/dev/null' EXIT
    "$@"
}

case "${1:-toggle}" in
    label)
        if [[ -e "$LOCK" ]]; then
            echo "󰋋  $NAME: switching…"
        elif is_connected; then
            battery=$(bluetoothctl info "$MAC" 2>/dev/null | sed -n 's/.*Battery Percentage: 0x[0-9a-fA-F]* (\([0-9]*\)).*/\1/p')
            echo "󰋋  Disconnect $NAME${battery:+  ${battery}%}"
        else
            echo "󰟎  Connect $NAME"
        fi
        ;;
    toggle)     if is_connected; then run_locked do_disconnect; else run_locked do_connect; fi ;;
    connect)    run_locked do_connect ;;
    disconnect) run_locked do_disconnect ;;
    *)          echo "usage: $0 [toggle|connect|disconnect|label]" >&2; exit 2 ;;
esac
