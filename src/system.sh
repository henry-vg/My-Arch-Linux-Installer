install_base_system() {
    pacstrap /mnt base linux linux-firmware networkmanager sudo reflector
    log "[OK] Base system installed."
}

generate_fstab() {
    genfstab -U /mnt > /mnt/etc/fstab
    log "[OK] fstab generated."
}

configure_system() {
    local hostname=$1 username=$2 root_password=$3 user_password=$4

    arch-chroot /mnt /bin/bash -s -- "$hostname" "$username" <<'CHROOT'
set -e

hostname="$1"
username="$2"

pacman -Syu --noconfirm
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
grep -qxF 'pt_BR.UTF-8 UTF-8' /etc/locale.gen || echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf
echo "$hostname" > /etc/hostname
printf '127.0.0.1   localhost.localdomain localhost\n::1         localhost.localdomain localhost\n127.0.1.1   %s.localdomain %s\n' "$hostname" "$hostname" > /etc/hosts
id -u "$username" >/dev/null 2>&1 || useradd -m -g users -G wheel "$username"
printf '%s ALL=(ALL) ALL\n' "$username" > "/etc/sudoers.d/10-$username"
chmod 440 "/etc/sudoers.d/10-$username"
systemctl enable NetworkManager
reflector --verbose --country Brazil --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
CHROOT

    printf 'root:%s\n' "$root_password" | arch-chroot /mnt chpasswd
    printf '%s:%s\n' "$username" "$user_password" | arch-chroot /mnt chpasswd

    log "[OK] System configured."
}

install_bootloader() {
    arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -e

pacman -S grub efibootmgr os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grep -qxF 'GRUB_DISABLE_OS_PROBER=false' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
CHROOT

    log "[OK] Bootloader installed."
}

install_general_programs() {
    arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -e

pacman -S --noconfirm firefox locate
updatedb
CHROOT

    log "[OK] General programs installed."
}

finalize_installation() {
    log "Unmounting and rebooting..."
    umount -lR /mnt
    swapoff -a

    for seconds_remaining in {5..1}; do
        log "Rebooting in $seconds_remaining second(s)..."
        sleep 1
    done

    reboot
}
