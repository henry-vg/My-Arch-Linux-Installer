#!/usr/bin/env bash

set -euo pipefail

trap '' INT

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_DIR

source "$PROJECT_DIR/src/console.sh"
source "$PROJECT_DIR/src/requirements.sh"
source "$PROJECT_DIR/src/installation_details.sh"
source "$PROJECT_DIR/src/disk.sh"
source "$PROJECT_DIR/src/system.sh"
source "$PROJECT_DIR/src/graphical_environment.sh"
source "$PROJECT_DIR/src/cursor_theme.sh"
source "$PROJECT_DIR/src/general_programs.sh"

main() {
    local hostname username root_password user_password installation_disk
    local root_size_mib swap_size_mib efi_partition root_partition swap_partition home_partition
    local terminal_settings

    if [[ -t 0 ]]; then
        terminal_settings="$(stty -g)"
        trap 'reset_output; stty "$terminal_settings"' EXIT
        stty intr undef
    fi

    require_root
    require_uefi

    pause "[1/15] Check internet connection"
    check_internet_connection

    pause "[2/15] Collect installation details"
    collect_installation_details hostname username root_password user_password

    pause "[3/15] Select installation disk"
    select_disk installation_disk

    pause "[4/15] Choose partition sizes"
    select_partition_sizes "$installation_disk" root_size_mib swap_size_mib

    pause "[5/15] Partition disk"
    partition_disk "$installation_disk" "$root_size_mib" "$swap_size_mib"

    efi_partition="$(partition_path "$installation_disk" 1)"
    root_partition="$(partition_path "$installation_disk" 2)"
    swap_partition="$(partition_path "$installation_disk" 3)"
    home_partition="$(partition_path "$installation_disk" 4)"

    pause "[6/15] Format partitions"
    format_partitions "$efi_partition" "$root_partition" "$swap_partition" "$home_partition"

    pause "[7/15] Mount filesystems"
    mount_partitions "$efi_partition" "$root_partition" "$swap_partition" "$home_partition"

    pause "[8/15] Install base system"
    install_base_system

    pause "[9/15] Generate /etc/fstab"
    generate_fstab

    pause "[10/15] Configure installed system"
    configure_system "$hostname" "$username" "$root_password" "$user_password"
    unset root_password user_password

    pause "[11/15] Install bootloader"
    install_bootloader

    pause "[12/15] Install and configure graphical environment"
    install_and_configure_graphical_environment

    pause "[13/15] Install cursor theme"
    install_cursor_theme

    pause "[14/15] Install general programs"
    install_general_programs

    pause "[15/15] Unmount and reboot"
    unmount_and_reboot
}

main "$@"
