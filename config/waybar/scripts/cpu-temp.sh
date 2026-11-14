#!/usr/bin/env bash
# CPU temperature for Waybar, found automatically:
# Intel coretemp / AMD k10temp or zenpower hwmon, then the x86_pkg_temp
# thermal zone. Prints nothing (module hidden) when no sensor is found.

critical=80

read_temp() {
    local millideg
    read -r millideg < "$1" 2>/dev/null || return 1
    [[ "$millideg" =~ ^[0-9]+$ ]] || return 1
    echo $(( (millideg + 500) / 1000 ))
}

temp=""
for hwmon in /sys/class/hwmon/hwmon*; do
    case "$(cat "$hwmon/name" 2>/dev/null)" in
        coretemp|k10temp|zenpower)
            # temp1 is the package (Intel) or Tctl (AMD) sensor.
            temp=$(read_temp "$hwmon/temp1_input") && break ;;
    esac
done

if [[ -z "$temp" ]]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        if [[ "$(cat "$zone/type" 2>/dev/null)" == x86_pkg_temp ]]; then
            temp=$(read_temp "$zone/temp") && break
        fi
    done
fi

[[ -n "$temp" ]] || exit 0

class=normal
(( temp >= critical )) && class=critical
printf '{"text":" %s°C","class":"%s","tooltip":"CPU temperature: %s°C"}\n' "$temp" "$class" "$temp"
