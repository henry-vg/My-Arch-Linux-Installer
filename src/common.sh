if [[ -t 1 && -t 2 && ${TERM:-dumb} != dumb ]]; then
    readonly COLOR_ENABLED=true
else
    readonly COLOR_ENABLED=false
fi

colors_enabled() {
    [[ $COLOR_ENABLED == true ]]
}

dim_output() {
    if colors_enabled; then printf '\e[2m'; fi
}

reset_output() {
    if colors_enabled; then printf '\e[0m'; fi
}

log() {
    local color=37

    case "$1" in
        '[OK]'*) color=32 ;;
        '[ERROR]'*) color=31 ;;
    esac

    if colors_enabled; then
        printf '\e[0;%sm%s\e[2m\n' "$color" "$1"
    else
        printf '%s\n' "$1"
    fi
}

input_prompt() {
    if colors_enabled; then
        printf '\e[0;36m%s\e[2m' "$1"
    else
        printf '%s' "$1"
    fi
}

pause() {
    if colors_enabled; then
        printf '\n\e[0;1;36m%s\e[0m\n' "$1"
    else
        printf '\n%s\n' "$1"
    fi
    if [[ -t 0 ]]; then stty intr '^C'; fi
    trap 'exit 130' INT
    read -rp "$(input_prompt 'Press Enter to continue...')"
    trap '' INT
    if [[ -t 0 ]]; then stty intr undef; fi
    printf '\n'
    dim_output
}

require_root() {
    if (( EUID != 0 )); then
        log "[ERROR] This script must be run as root."
        exit 1
    fi
}

require_uefi() {
    if [[ ! -d /sys/firmware/efi ]]; then
        log "[ERROR] System not booted in UEFI mode. GRUB install will fail."
        exit 1
    fi
}

check_internet_connection() {
    if ! ping -c 4 8.8.8.8 > /dev/null 2>&1; then
        log "[ERROR] No internet connection. Exiting..."
        exit 1
    fi
    log "[OK] Connected."
}
