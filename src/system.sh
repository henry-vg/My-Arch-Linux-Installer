install_base_system() {
    pacstrap -K /mnt base linux linux-firmware networkmanager sudo
    log "[INFO] Base system installed."
}

generate_fstab() {
    genfstab -U /mnt > /mnt/etc/fstab
    log "[INFO] fstab generated."
}

configure_system() {
    local hostname="$1" username="$2" root_password="$3" user_password="$4"

    arch-chroot /mnt /bin/bash -s -- "$hostname" "$username" <<'CHROOT'
set -euo pipefail

hostname="$1"
username="$2"

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || printf 'en_US.UTF-8 UTF-8\n' >> /etc/locale.gen
grep -qxF 'pt_BR.UTF-8 UTF-8' /etc/locale.gen || printf 'pt_BR.UTF-8 UTF-8\n' >> /etc/locale.gen
locale-gen
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=br-abnt2\n' > /etc/vconsole.conf
printf '%s\n' "$hostname" > /etc/hostname
printf '127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost\n127.0.1.1   %s.localdomain %s\n' "$hostname" "$hostname" > /etc/hosts
id -u "$username" >/dev/null 2>&1 || useradd -m -g users -G wheel "$username"
printf '%s ALL=(ALL) ALL\n' "$username" > "/etc/sudoers.d/10-$username"
chmod 440 "/etc/sudoers.d/10-$username"
visudo -c
systemctl enable NetworkManager systemd-timesyncd
CHROOT

    printf 'root:%s\n' "$root_password" | arch-chroot /mnt chpasswd
    printf '%s:%s\n' "$username" "$user_password" | arch-chroot /mnt chpasswd

    log "[INFO] System configured."
}

install_bootloader() {
    arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -euo pipefail

pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT

    log "[INFO] Bootloader installed."
}

unmount_and_reboot() {
    local seconds_remaining

    log "Unmounting and rebooting..."
    umount -lR /mnt
    swapoff -a

    for seconds_remaining in {5..1}; do
        log "Rebooting in $seconds_remaining second(s)..."
        sleep 1
    done

    reboot
}
