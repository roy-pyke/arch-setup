#!/usr/bin/env bash
# Toolbox: a rofi menu that lists every tool in tools/ and runs the one you pick.
#
# Adding a tool: drop an executable script into tools/. The number at the start
# of the file name sets the order. Each tool must support:
#   <tool> label   print the menu line (icon, name, current state);
#                  print nothing to hide the tool
#   <tool>         run the tool
#
# Machine-specific settings for tools go in local.conf (see local.example.conf).

dir=$(dirname "$(readlink -f "$0")")
tools_dir="$dir/tools"

# Pressing the shortcut again closes an open menu.
if pgrep -x rofi >/dev/null; then
    pkill -x rofi
    exit 0
fi

tools=()
labels=()
for tool in "$tools_dir"/*; do
    [[ -f "$tool" && -x "$tool" ]] || continue
    label=$(timeout 2 "$tool" label 2>/dev/null | head -n 1)
    [[ -n "$label" ]] || continue
    tools+=("$tool")
    labels+=("$label")
done

(( ${#tools[@]} )) || exit 0

index=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -no-custom -format i \
    -p "󰦬" -theme-str "listview { lines: ${#tools[@]}; } window { height: 0; }") || exit 0
[[ "$index" =~ ^[0-9]+$ ]] || exit 0

exec "${tools[$index]}"
