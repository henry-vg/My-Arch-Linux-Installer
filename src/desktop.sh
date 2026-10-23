install_graphical_environment() {
    arch-chroot /mnt /bin/bash -s <<'CHROOT'
set -e

pacman -S --noconfirm xorg-server xorg-xinit i3-wm lightdm lightdm-gtk-greeter rofi kitty feh polybar
systemctl enable lightdm
CHROOT

    echo "[OK] Graphical environment installed."
}

install_cursor_theme() {
    local cursor_theme="henry-cursors-high-contrast"

    install -d -m 755 /mnt/usr/share/icons
    cp -a "$PROJECT_DIR/$cursor_theme" "/mnt/usr/share/icons/$cursor_theme"

    install -d -m 755 /mnt/usr/share/icons/default
    printf '[Icon Theme]\nInherits=%s\n' "$cursor_theme" > /mnt/usr/share/icons/default/index.theme

    echo "[OK] Cursor theme installed."
}

configure_graphical_environment() {
    local user_home="/mnt/home/$USERNAME"

    install -d -m 755 "$user_home/.config"
    cp -a "$PROJECT_DIR/dotfiles/.config/." "$user_home/.config/"
    chmod +x "$user_home/.config/polybar/launch.sh"

    install -d -m 755 "$user_home/documents/pictures/wallpapers"
    install -m 644 "$PROJECT_DIR/arch-linux-wallpaper.jpg" "$user_home/documents/pictures/wallpapers"

    arch-chroot /mnt chown -R "$USERNAME:users" "/home/$USERNAME/.config" "/home/$USERNAME/documents"

    echo "[OK] Graphical environment configured."
}
