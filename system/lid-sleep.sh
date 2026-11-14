#!/usr/bin/env bash
# Suspend when the laptop lid is closed (on battery, on AC power and docked),
# and make suspend the default sleep operation.
#
#   bash system/lid-sleep.sh        (from a terminal inside Hyprland, without sudo)
#
# Installs system/etc/systemd/logind.conf.d/95-lid-sleep.conf into /etc and
# reloads systemd-logind. Suspending 2 minutes after locking is handled by
# hypridle + ~/.config/hypr/scripts/lock-sleep.sh and needs no setup.

set -euo pipefail

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source_file="$repo_dir/etc/systemd/logind.conf.d/95-lid-sleep.conf"
target=/etc/systemd/logind.conf.d/95-lid-sleep.conf

(( EUID != 0 )) || fail 'do not run the whole script with sudo; run: bash system/lid-sleep.sh'
[[ -n ${WAYLAND_DISPLAY:-} && -n ${XDG_RUNTIME_DIR:-} ]] || fail 'run this from a terminal inside the Hyprland session.'
[[ $(ps -p 1 -o comm= | tr -d ' ') == systemd ]] || fail 'run this on the machine itself, not in a container.'
[[ -r "$source_file" ]] || fail "missing $source_file"

for lid in /proc/acpi/button/lid/*/state; do
    if [[ -r "$lid" ]] && grep -qi closed "$lid"; then
        fail 'open the laptop lid first, then run this script again.'
    fi
done

if [[ -e "$target" ]] && ! cmp -s "$source_file" "$target"; then
    fail "$target already exists with different content; it was not overwritten."
fi

# Cancel any pending lock-to-sleep timer while logind is reloaded.
"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/lock-sleep.sh" stop || true

printf 'Updating the lid and sleep settings; you may be asked for your password...\n'
sudo -v
sudo install -Dm644 "$source_file" "$target"
sudo systemctl reload systemd-logind.service

for property in HandleLidSwitch HandleLidSwitchExternalPower HandleLidSwitchDocked; do
    value=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "$property") ||
        fail "settings written, but $property could not be checked."
    [[ "$value" == 's "suspend"' ]] || fail "$property is $value; another logind drop-in may override it."
    printf '%s: %s\n' "$property" "$value"
done

value=$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager SleepOperation) ||
    fail 'settings written, but the default sleep operation could not be checked.'
[[ "$value" == 'as 1 "suspend"' ]] || fail "the default sleep operation is $value; another logind drop-in may override it."
printf 'SleepOperation: %s\n' "$value"

printf '\nDone: closing the lid suspends, and so does staying locked for 2 minutes. Hibernate stays in the power menu.\n'
