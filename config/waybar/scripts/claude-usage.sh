#!/usr/bin/env bash
# Optional Claude Code usage module (https://github.com/Janicklin/claude-usage-waybar).
# Looks for the project in $CLAUDE_USAGE_WAYBAR_DIR, ~/.local/share/claude-usage-waybar
# or ~/Projects/claude-usage-waybar. Prints nothing (module hidden) when it is
# not installed. `./install.sh --with-claude-usage` downloads it.

for dir in "${CLAUDE_USAGE_WAYBAR_DIR:-}" \
           "${XDG_DATA_HOME:-$HOME/.local/share}/claude-usage-waybar" \
           "$HOME/Projects/claude-usage-waybar"; do
    if [[ -n "$dir" && -f "$dir/claude-usage-waybar.py" ]]; then
        exec python3 "$dir/claude-usage-waybar.py" --icon 󰚩
    fi
done
exit 0
