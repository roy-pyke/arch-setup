#!/usr/bin/env bash
# Screen brightness menu. Changes the backlight through logind, so no root
# access or udev rule is needed.
#
#   brightness-menu.sh          open the menu
#   brightness-menu.sh percent  print the current brightness in percent

# Use $BACKLIGHT_DEVICE if set, otherwise the first backlight device found.
backlight=""
if [[ -n "${BACKLIGHT_DEVICE:-}" ]]; then
    backlight="/sys/class/backlight/$BACKLIGHT_DEVICE"
else
    for dev in /sys/class/backlight/*; do
        [[ -r "$dev/max_brightness" ]] && { backlight=$dev; break; }
    done
fi

if [[ -z "$backlight" || ! -r "$backlight/max_brightness" || ! -r "$backlight/actual_brightness" ]]; then
    [[ "${1:-}" == percent ]] && exit 1
    notify-send -u normal "Brightness" "No screen backlight device found."
    exit 1
fi
device=${backlight##*/}

read -r maximum < "$backlight/max_brightness"
read -r current < "$backlight/actual_brightness"
if [[ ! "$maximum" =~ ^[1-9][0-9]*$ || ! "$current" =~ ^[0-9]+$ ]]; then
    [[ "${1:-}" == percent ]] && exit 1
    notify-send -u normal "Brightness" "Cannot read the screen brightness."
    exit 1
fi

current_percent=$(( (current * 100 + maximum / 2) / maximum ))
if [[ "${1:-}" == percent ]]; then
    echo "$current_percent"
    exit 0
fi

levels=(100 80 60 40 20 10)
choice=$(printf '%s%%\n' "${levels[@]}" | \
    rofi -dmenu -i -no-custom -format i -p "Brightness ($current_percent%)" \
    -theme-str "listview { lines: ${#levels[@]}; } window { height: 0; }") || exit 0
[[ "$choice" =~ ^[0-9]+$ ]] || exit 0
percent=${levels[$choice]}

value=$(( (maximum * percent + 50) / 100 ))
if ! busctl --system call org.freedesktop.login1 \
    /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
    SetBrightness ssu backlight "$device" "$value" >/dev/null 2>&1; then
    notify-send -u normal "Brightness" "This session is not allowed to change the screen brightness."
    exit 1
fi
