require_root() {
    if (( EUID != 0 )); then
        log "[ERROR] This script must be run as root."
        return 1
    fi
}

require_uefi() {
    if [[ ! -d /sys/firmware/efi ]]; then
        log "[ERROR] System not booted in UEFI mode. GRUB install will fail."
        return 1
    fi
}

check_internet_connection() {
    if ! ping -c 4 8.8.8.8 > /dev/null 2>&1; then
        log "[ERROR] Internet connection unavailable."
        return 1
    fi
    log "[INFO] Internet connection available."
}
