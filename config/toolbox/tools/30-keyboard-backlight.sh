#!/usr/bin/env bash
# Keyboard backlight: lists the hardware levels and sets the one you pick.
# Hidden on machines without a keyboard backlight.

script="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/scripts/keyboard-backlight.sh"

read -r current maximum < <("$script" info 2>/dev/null)
[[ "$current" =~ ^[0-9]+$ && "$maximum" =~ ^[1-9][0-9]*$ ]] || exit 0

percent() { echo $(( ($1 * 100 + maximum / 2) / maximum )); }

case "${1:-run}" in
    label)
        echo "󰌌  Keyboard backlight  $(percent "$current")%"
        ;;
    *)
        # Few levels (e.g. 0/1/2): list each one. Many levels: steps of 20%.
        levels=()
        if (( maximum <= 10 )); then
            for (( i = maximum; i >= 0; i-- )); do levels+=("$i"); done
        else
            for p in 100 80 60 40 20 10 0; do levels+=("$(( (maximum * p + 50) / 100 ))"); done
        fi

        rows=()
        selected=0
        for i in "${!levels[@]}"; do
            level=${levels[$i]}
            if (( level == 0 )); then rows+=("Off"); else rows+=("$(percent "$level")%"); fi
            (( level == current )) && selected=$i
        done

        choice=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -no-custom -format i -selected-row "$selected" \
            -p "Keyboard backlight ($(percent "$current")%)" \
            -theme-str "listview { lines: ${#rows[@]}; } window { height: 0; }") || exit 0
        [[ "$choice" =~ ^[0-9]+$ ]] || exit 0
        exec "$script" set "${levels[$choice]}"
        ;;
esac
