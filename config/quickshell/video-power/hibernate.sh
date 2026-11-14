#!/usr/bin/env bash

if ! systemctl hibernate; then
    notify-send -u critical "Hibernate failed" "Check the hibernation setup (see system/hibernation.sh), swap space and the journal."
    exit 1
fi
