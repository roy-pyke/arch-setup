#!/usr/bin/env bash
# Keyboard backlight helper (used by the toolbox). Changes the level through
# logind, so no root access is needed.
#
#   keyboard-backlight.sh [show]      print the level in percent
#   keyboard-backlight.sh info        print "<current> <max>" hardware levels
#   keyboard-backlight.sh set <level> set a hardware level
#   keyboard-backlight.sh next|up|down

led_root=${KEYBOARD_BACKLIGHT_ROOT:-/sys/class/leds}

for led in "$led_root"/*kbd_backlight; do
    if [[ -r "$led/brightness" && -r "$led/max_brightness" ]]; then
        read -r current < "$led/brightness"
        read -r maximum < "$led/max_brightness"
        if [[ "$current" =~ ^[0-9]+$ && "$maximum" =~ ^[1-9][0-9]*$ ]]; then
            break
        fi
    fi
    led=
done

# Print nothing on machines without a keyboard backlight.
[[ -n "$led" ]] || exit 0

case "${1:-show}" in
    show)
        printf '%s\n' "$(( (current * 100 + maximum / 2) / maximum ))"
        ;;
    info)
        printf '%s %s\n' "$current" "$maximum"
        ;;
    set)
        target=${2:-}
        [[ "$target" =~ ^[0-9]+$ ]] || exit 1
        (( target > maximum )) && target=$maximum
        (( target == current )) && exit 0
        if ! busctl --system call org.freedesktop.login1 \
            /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
            SetBrightness ssu leds "${led##*/}" "$target" >/dev/null 2>&1; then
            notify-send -u normal "Keyboard backlight" "This session is not allowed to change the keyboard backlight."
            exit 1
        fi
        ;;
    next|up|down)
        # A step is at least one hardware level, or about 10% for finer devices.
        step=$(( (maximum + 9) / 10 ))
        case "$1" in
            next)
                if (( current >= maximum )); then
                    target=0
                else
                    target=$(( current + step ))
                fi
                ;;
            up) target=$(( current + step )) ;;
            down) target=$(( current - step )) ;;
        esac
        (( target > maximum )) && target=$maximum
        (( target < 0 )) && target=0
        (( target == current )) && exit 0

        if ! busctl --system call org.freedesktop.login1 \
            /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
            SetBrightness ssu leds "${led##*/}" "$target" >/dev/null 2>&1; then
            notify-send -u normal "Keyboard backlight" "This session is not allowed to change the keyboard backlight."
            exit 1
        fi
        ;;
    *)
        exit 1
        ;;
esac
