pause() {
    printf '\n%s\n' "$1"
    read -rp "Press Enter to continue..."
    echo
}

require_root() {
    if (( EUID != 0 )); then
        echo "[ERROR] This script must be run as root."
        exit 1
    fi
}

require_uefi() {
    if [[ ! -d /sys/firmware/efi ]]; then
        echo "[ERROR] System not booted in UEFI mode. GRUB install will fail."
        exit 1
    fi
}

check_internet_connection() {
    if ! ping -c 4 8.8.8.8 > /dev/null 2>&1; then
        echo "[ERROR] No internet connection. Exiting..."
        exit 1
    fi
    echo "[OK] Connected."
}
