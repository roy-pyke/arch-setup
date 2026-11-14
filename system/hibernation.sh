#!/usr/bin/env bash
# Set up hibernation with a swap file on an ext4 root file system.
#
#   sudo bash system/hibernation.sh
#
# Requirements (checked before anything is changed):
#   - UEFI boot with writable EFI variables, kernel lockdown off
#   - mkinitcpio initramfs built with the `systemd` hook, so systemd can resume
#     from the location it stores in an EFI variable (no resume= parameter needed)
#   - ext4 root, no swap configured yet, enough free space
#
# Environment:
#   SWAP_SIZE_GIB  swap file size (default: RAM rounded up to a whole GiB)
#   INITRAMFS      initramfs to inspect (default: /boot/initramfs-linux.img)
#
# Changes: creates /swapfile, enables it and adds it to /etc/fstab
# (a backup of /etc/fstab is kept next to it).

set -euo pipefail

fail() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

(( EUID == 0 )) || fail 'run as root: sudo bash system/hibernation.sh'
[[ $(ps -p 1 -o comm= | tr -d ' ') == systemd ]] || fail 'run this on the machine itself, not in a container.'
[[ $(findmnt -n -o FSTYPE -T /) == ext4 ]] || fail 'the root file system is not ext4; nothing was changed.'
[[ -r /sys/power/state ]] && grep -qw disk /sys/power/state || fail 'the kernel does not support hibernation.'
[[ -d /sys/firmware/efi/efivars ]] || fail 'no EFI variables found (UEFI boot is required); nothing was changed.'

efi_options=$(findmnt -n -o OPTIONS -T /sys/firmware/efi/efivars)
[[ ",$efi_options," == *,rw,* ]] || fail 'EFI variables are read-only, so systemd cannot store the resume location.'

if [[ -r /sys/kernel/security/lockdown ]] && ! grep -Fq '[none]' /sys/kernel/security/lockdown; then
    fail 'kernel lockdown is enabled and may block hibernation; nothing was changed.'
fi

cmdline=" $(cat /proc/cmdline) "
if [[ "$cmdline" =~ [[:space:]](noresume|hibernate=no|hibernate=noresume)([[:space:]]|$) ]] ||
   [[ "$cmdline" =~ [[:space:]]resume(_offset)?= ]]; then
    fail 'the kernel command line already sets or disables resume; nothing was changed.'
fi
[[ $(cat /sys/power/resume) == 0:0 && $(cat /sys/power/resume_offset) == 0 ]] ||
    fail 'a resume location is already configured; nothing was changed.'

initramfs=${INITRAMFS:-/boot/initramfs-linux.img}
[[ -r "$initramfs" ]] || fail "cannot read $initramfs (set INITRAMFS); nothing was changed."
initramfs_files=$(lsinitcpio --list "$initramfs") || fail "cannot inspect $initramfs; nothing was changed."
for required in \
    usr/lib/systemd/systemd-hibernate-resume \
    usr/lib/systemd/system-generators/systemd-hibernate-resume-generator \
    usr/lib/systemd/system/systemd-hibernate-resume.service; do
    grep -Fxq "$required" <<< "$initramfs_files" ||
        fail "$initramfs is missing $required; add the systemd hook in /etc/mkinitcpio.conf and run mkinitcpio -P."
done

memory_kib=$(awk '/^MemTotal:/ { print $2 }' /proc/meminfo)
memory_gib=$(( (memory_kib + 1024 * 1024 - 1) / (1024 * 1024) ))
swap_gib=${SWAP_SIZE_GIB:-$memory_gib}
[[ "$swap_gib" =~ ^[1-9][0-9]*$ ]] || fail "invalid SWAP_SIZE_GIB: $swap_gib"
(( swap_gib >= memory_gib )) || fail "a ${swap_gib} GiB swap file is smaller than RAM (${memory_gib} GiB); nothing was changed."

free_bytes=$(df -B1 --output=avail / | tail -n 1 | tr -d ' ')
(( free_bytes >= (swap_gib + 2) * 1024 * 1024 * 1024 )) ||
    fail "less than $(( swap_gib + 2 )) GiB free on the root file system; nothing was changed."
[[ ! -e /swapfile && ! -L /swapfile ]] || fail '/swapfile already exists; check the existing setup.'
[[ $(wc -l < /proc/swaps) -eq 1 ]] || fail 'swap is already enabled; check the existing setup first.'
if awk '$1 == "/swapfile" && $3 == "swap" { found=1 } END { exit !found }' /etc/fstab; then
    fail '/etc/fstab already has a /swapfile entry; check the existing setup first.'
fi

backup="/etc/fstab.backup-before-hibernation-$(date +%Y%m%d-%H%M%S)"
[[ ! -e "$backup" ]] || fail "backup file $backup already exists."
cp -p /etc/fstab "$backup"
printf 'Backed up /etc/fstab to %s\n' "$backup"
printf 'Creating a %s GiB swap file, please wait...\n' "$swap_gib"

if ! mkswap --file --size "${swap_gib}GiB" /swapfile; then
    rm -f /swapfile
    fail 'could not create the swap file.'
fi

if ! swapon /swapfile; then
    rm -f /swapfile
    fail 'could not enable the swap file.'
fi

if ! printf '\n/swapfile none swap defaults 0 0\n' >> /etc/fstab; then
    if swapoff /swapfile; then
        rm -f /swapfile
    else
        printf 'Swap is still in use, so /swapfile was kept; check the system state.\n' >&2
    fi
    fail "could not update /etc/fstab; the original is backed up at $backup."
fi

if ! systemctl daemon-reload; then
    printf 'warning: could not reload systemd; the swap file is enabled and in /etc/fstab.\n' >&2
fi

printf '\nSwap enabled:\n'
swapon --show
printf '\nsystemd hibernation check:\n'
if ! capability=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager CanHibernate); then
    fail 'swap is configured, but the hibernation capability could not be queried; check the journal.'
fi
printf '%s\n' "$capability"
case "$capability" in
    's "yes"'|'s "challenge"') ;;
    *) fail 'swap is configured, but systemd does not report hibernation as available yet; check the output above and the journal.' ;;
esac
printf '\nDone. Save your work, then test "Hibernate" from the power menu (Super+Esc).\n'
