#!/usr/bin/env bash
# Volume: mute toggle, common levels and pavucontrol. Hidden without an audio output.

sink=@DEFAULT_AUDIO_SINK@

read_volume() {
    local out
    out=$(wpctl get-volume "$sink" 2>/dev/null) || return 1
    # Output looks like "Volume: 0.45" or "Volume: 0.45 [MUTED]".
    volume=$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<< "$out")
    [[ "$out" == *MUTED* ]] && muted=1 || muted=0
}

volume=0
muted=0
read_volume || exit 0

case "${1:-run}" in
    label)
        if (( muted )); then echo "󰝟  Volume  muted"; else echo "󰕾  Volume  ${volume}%"; fi
        ;;
    *)
        if (( muted )); then rows=("󰕾  Unmute"); else rows=("󰝟  Mute"); fi
        values=(100 80 60 40 20 10)
        for v in "${values[@]}"; do rows+=("${v}%"); done
        rows+=("󰒓  Sound settings…")

        if (( muted )); then prompt="Volume (muted)"; else prompt="Volume (${volume}%)"; fi
        choice=$(printf '%s\n' "${rows[@]}" | rofi -dmenu -i -no-custom -format i -p "$prompt" \
            -theme-str "listview { lines: ${#rows[@]}; } window { height: 0; }") || exit 0
        [[ "$choice" =~ ^[0-9]+$ ]] || exit 0

        if (( choice == 0 )); then
            wpctl set-mute "$sink" toggle
        elif (( choice == ${#rows[@]} - 1 )); then
            setsid -f pavucontrol >/dev/null 2>&1
        else
            wpctl set-mute "$sink" 0
            wpctl set-volume "$sink" "${values[$(( choice - 1 ))]}%"
        fi
        ;;
esac
