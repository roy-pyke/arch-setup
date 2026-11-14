#!/usr/bin/env bash
# Countdown timer
#
# Usage:
#   10-countdown.sh            ask for a duration and start a new timer
#   10-countdown.sh manage     pause, resume or cancel running timers
#   10-countdown.sh status     Waybar JSON
#   10-countdown.sh label      toolbox menu line
#   10-countdown.sh start <seconds> [note]
#   10-countdown.sh parse <text>
#
# Each timer is a file in $state_dir with three lines:
#   end time (epoch seconds)   seconds left while paused (- when running)   note

state_dir="${XDG_RUNTIME_DIR:-/tmp}/toolbox-countdown"
signal=10   # must match "signal" of custom/countdown in the Waybar config
self=$(readlink -f "$0")

refresh_bar() {
    pkill -RTMIN+"$signal" waybar 2>/dev/null
}

notify() {
    # Silent, and -t 0 keeps it on screen until dismissed.
    notify-send -a "Countdown" -u normal -t 0 -i alarm-symbolic \
        -h boolean:suppress-sound:true "$@" >/dev/null 2>&1
}

fmt() {
    local s=$1
    (( s < 0 )) && s=0
    if (( s >= 3600 )); then
        printf '%d:%02d:%02d' $(( s / 3600 )) $(( s % 3600 / 60 )) $(( s % 60 ))
    else
        printf '%02d:%02d' $(( s / 60 )) $(( s % 60 ))
    fi
}

# Turn input such as "25m write report" into "<seconds><TAB><note>".
# Accepts 25 (minutes), 90s, 25m, 1h30m, 1h 30m, 10:00, 1:00:00, long unit
# names (min, hours, ...) and Chinese units (小时/分钟/秒).
parse() {
    local input rest="" total=0 matched=0 n unit
    input=$(printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
    [[ -n "$input" ]] || return 1

    if [[ "$input" =~ ^([0-9]+):([0-9]{1,2}):([0-9]{1,2})([[:space:]]+(.*))?$ ]]; then
        total=$(( 10#${BASH_REMATCH[1]} * 3600 + 10#${BASH_REMATCH[2]} * 60 + 10#${BASH_REMATCH[3]} ))
        rest=${BASH_REMATCH[5]}
    elif [[ "$input" =~ ^([0-9]+):([0-9]{1,2})([[:space:]]+(.*))?$ ]]; then
        total=$(( 10#${BASH_REMATCH[1]} * 60 + 10#${BASH_REMATCH[2]} ))
        rest=${BASH_REMATCH[4]}
    else
        local gap after
        rest=$input
        while [[ "$rest" =~ ^([0-9]+)[[:space:]]*(小时|时|hours|hour|hrs|hr|h|分钟|分|minutes|minute|mins|min|m|秒钟|秒|seconds|second|secs|sec|s)([[:space:]]*)(.*)$ ]]; do
            n=$(( 10#${BASH_REMATCH[1]} ))
            unit=${BASH_REMATCH[2]}
            gap=${BASH_REMATCH[3]}
            after=${BASH_REMATCH[4]}
            # A letter right after the unit means it was not a unit ("5mango").
            [[ -z "$gap" && "$after" =~ ^[A-Za-z] ]] && break
            case "$unit" in
                小时|时|h*) total=$(( total + n * 3600 )) ;;
                分钟|分|m*) total=$(( total + n * 60 )) ;;
                *)          total=$(( total + n )) ;;
            esac
            matched=1
            rest=$after
        done
        if (( ! matched )); then
            # A bare number means minutes, e.g. "25 write report".
            [[ "$input" =~ ^([0-9]+)([[:space:]]+(.*))?$ ]] || return 1
            total=$(( 10#${BASH_REMATCH[1]} * 60 ))
            rest=${BASH_REMATCH[3]}
        fi
    fi

    (( total > 0 )) || return 1
    printf '%s\t%s\n' "$total" "$rest"
}

# Read a timer file into end / paused / label / remaining.
load() {
    local file=$1 lines=()
    mapfile -t lines < "$file" 2>/dev/null || return 1
    [[ "${lines[0]}" =~ ^[0-9]+$ ]] || return 1
    end=${lines[0]}
    paused=${lines[1]:--}
    label=${lines[2]}
    if [[ "$paused" =~ ^[0-9]+$ ]]; then
        remaining=$paused
    else
        paused=-
        remaining=$(( end - $(date +%s) ))
    fi
}

save() {
    local file=$1 tmp
    tmp=$(mktemp "$state_dir/.tmp.XXXXXX") || return 1
    printf '%s\n%s\n%s\n' "$2" "$3" "$4" > "$tmp" && mv -f "$tmp" "$file"
}

# List timers sorted by time left, one "<seconds left><TAB><file>" per line.
list_timers() {
    local file
    for file in "$state_dir"/timer.*; do
        [[ -f "$file" ]] || continue
        load "$file" || continue
        printf '%s\t%s\n' "$remaining" "$file"
    done | sort -n
}

do_start() {
    local seconds=$1 note=$2 file
    mkdir -p "$state_dir"
    file=$(mktemp "$state_dir/timer.XXXXXX") || exit 1
    save "$file" $(( $(date +%s) + seconds )) - "$note"
    setsid -f "$self" worker "$file" >/dev/null 2>&1 < /dev/null
    refresh_bar
}

# Background process: checks once a second, notifies and removes the file when done.
do_worker() {
    local file=$1 end paused label remaining
    while [[ -f "$file" ]]; do
        load "$file" || break
        if [[ "$paused" == - ]] && (( remaining <= 0 )); then
            rm -f "$file"
            refresh_bar
            if [[ -n "$label" ]]; then
                notify "Time's up" "$label"
            else
                notify "Time's up" "Your countdown has finished."
            fi
            exit 0
        fi
        sleep 1
    done
}

do_new() {
    local input parsed
    input=$(rofi -dmenu -p "󰔛" \
        -mesg "Enter a duration such as 25m, 1h30m, 90s or 10:00, optionally followed by a note" \
        -theme-str 'listview { enabled: false; } window { height: 0; } entry { placeholder: "25m write report"; }' \
        < /dev/null) || exit 0
    if ! parsed=$(parse "$input"); then
        [[ -n "${input// }" ]] && notify-send -a "Countdown" -u low -h boolean:suppress-sound:true \
            "Unknown duration" "\"$input\": use a duration such as 25m, 1h30m, 90s or 10:00."
        exit 0
    fi
    do_start "${parsed%%$'\t'*}" "${parsed#*$'\t'}"
}

menu() {
    # menu <prompt> <entries...>: prints the index of the chosen entry.
    local prompt=$1; shift
    printf '%s\n' "$@" | rofi -dmenu -i -no-custom -format i -p "$prompt" \
        -theme-str "listview { lines: $#; } window { height: 0; }"
}

do_manage() {
    local rows=() files=() remaining file end paused label line choice action
    while IFS=$'\t' read -r remaining file; do
        load "$file" || continue
        if [[ "$paused" == - ]]; then line="󰔛  $(fmt "$remaining")"; else line="󰏤  $(fmt "$remaining")  paused"; fi
        [[ -n "$label" ]] && line+="  ·  $label"
        rows+=("$line")
        files+=("$file")
    done < <(list_timers)

    (( ${#rows[@]} )) || { do_new; exit; }

    choice=$(menu "󰔛" "󰐕  New countdown" "${rows[@]}") || exit 0
    [[ "$choice" =~ ^[0-9]+$ ]] || exit 0
    (( choice == 0 )) && { do_new; exit; }

    file=${files[$(( choice - 1 ))]}
    load "$file" || exit 0
    if [[ "$paused" == - ]]; then
        action=$(menu "${rows[$(( choice - 1 ))]}" "󰏤  Pause" "󰅖  Cancel") || exit 0
        case "$action" in
            0) save "$file" "$end" "$remaining" "$label" ;;
            1) rm -f "$file" ;;
        esac
    else
        action=$(menu "${rows[$(( choice - 1 ))]}" "󰐊  Resume" "󰅖  Cancel") || exit 0
        case "$action" in
            0) save "$file" $(( $(date +%s) + remaining )) - "$label" ;;
            1) rm -f "$file" ;;
        esac
    fi
    refresh_bar
}

json_escape() {
    local s=$1
    s=${s//\\/\\\\}; s=${s//\"/\\\"}; s=${s//$'\n'/\\n}; s=${s//$'\t'/ }
    printf '%s' "$s"
}

do_status() {
    local timers=() row line remaining file end paused label text class tooltip="" first=1 count
    mapfile -t timers < <(list_timers)
    count=${#timers[@]}
    if (( count == 0 )); then
        printf '{"text":"","class":"idle"}\n'
        return
    fi
    for row in "${timers[@]}"; do
        file=${row#*$'\t'}
        load "$file" || continue
        line="$(fmt "$remaining")"
        [[ "$paused" != - ]] && line+=" (paused)"
        [[ -n "$label" ]] && line+="  $label"
        if (( first )); then
            if [[ "$paused" == - ]]; then text="󰔛 $(fmt "$remaining")"; class=running; else text="󰏤 $(fmt "$remaining")"; class=paused; fi
            (( count > 1 )) && text+=" +$(( count - 1 ))"
            tooltip=$line
            first=0
        else
            tooltip+=$'\n'$line
        fi
    done
    tooltip+=$'\n'"Click to pause, resume or cancel"
    printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$(json_escape "$text")" "$class" "$(json_escape "$tooltip")"
}

case "${1:-new}" in
    new)    do_new ;;
    manage) do_manage ;;
    status) do_status ;;
    label)
        count=$(list_timers | wc -l)
        if (( count )); then echo "󰔛  Countdown ($count running)"; else echo "󰔛  Countdown"; fi
        ;;
    start)
        [[ "$2" =~ ^[1-9][0-9]*$ ]] || { echo "usage: $0 start <seconds> [note]" >&2; exit 2; }
        do_start "$2" "${*:3}"
        ;;
    parse)  parse "$2" ;;
    worker) do_worker "$2" ;;
    *)      echo "usage: $0 [new|manage|status|label|start <seconds> [note]|parse <text>]" >&2; exit 2 ;;
esac
