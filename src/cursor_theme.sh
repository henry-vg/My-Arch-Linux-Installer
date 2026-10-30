install_cursor_theme() {
    local theme_name="henry-cursors-high-contrast"
    local theme_directory="/mnt/usr/share/icons/$theme_name"

    install -d -m 755 "$theme_directory" /mnt/usr/share/icons/default
    cp -a "$PROJECT_DIR/assets/cursors/$theme_name/." "$theme_directory/"
    printf '[Icon Theme]\nInherits=%s\n' "$theme_name" > /mnt/usr/share/icons/default/index.theme

    log "[INFO] High-contrast cursor theme installed as the system default."
}
