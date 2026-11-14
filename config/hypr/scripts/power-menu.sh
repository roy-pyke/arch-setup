#!/usr/bin/env bash

# Fall back to the installed launcher if the graphical menu cannot start.
if quickshell --no-duplicate -c video-power; then
    exit 0
fi

choice=$(printf 'Shutdown\nRestart\nHibernate\nLog out\n' | rofi -dmenu -p Power -no-custom) || exit 0
case "$choice" in
    Shutdown) systemctl poweroff ;;
    Restart) systemctl reboot ;;
    Hibernate) bash "${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/video-power/hibernate.sh" ;;
    'Log out') hyprctl dispatch exit ;;
esac
