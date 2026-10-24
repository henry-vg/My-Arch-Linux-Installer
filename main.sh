#!/usr/bin/env bash

set -euo pipefail

trap '' INT

readonly PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$PROJECT_DIR/src/common.sh"
source "$PROJECT_DIR/src/configuration.sh"
source "$PROJECT_DIR/src/disk.sh"
source "$PROJECT_DIR/src/system.sh"
source "$PROJECT_DIR/src/desktop.sh"

main() {
    local hostname username root_password user_password disk
    local root_size_mib swap_size_mib efi_partition root_partition swap_partition home_partition
    local terminal_settings

    if [[ -t 0 ]]; then
        terminal_settings=$(stty -g)
        trap 'reset_output; stty "$terminal_settings"' EXIT
        stty intr undef
    fi

    require_root
    require_uefi

    pause "[1/16] Internet connection check"
    check_internet_connection

    pause "[2/16] Initial configuration"
    collect_system_configuration hostname username root_password user_password

    pause "[3/16] Disk selection"
    select_disk disk

    pause "[4/16] Disk sizing"
    select_partition_sizes "$disk" root_size_mib swap_size_mib

    pause "[5/16] Disk partitioning"
    partition_disk "$disk" "$root_size_mib" "$swap_size_mib"

    efi_partition=$(partition_path "$disk" 1)
    root_partition=$(partition_path "$disk" 2)
    swap_partition=$(partition_path "$disk" 3)
    home_partition=$(partition_path "$disk" 4)

    pause "[6/16] Formatting partitions"
    format_partitions "$efi_partition" "$root_partition" "$swap_partition" "$home_partition"

    pause "[7/16] Mounting partitions"
    mount_partitions "$efi_partition" "$root_partition" "$swap_partition" "$home_partition"

    pause "[8/16] Installing base system"
    install_base_system

    pause "[9/16] Generating fstab"
    generate_fstab

    pause "[10/16] System configuration"
    configure_system "$hostname" "$username" "$root_password" "$user_password"
    unset root_password user_password

    pause "[11/16] Installing bootloader"
    install_bootloader

    pause "[12/16] Installing graphical environment"
    install_graphical_environment

    pause "[13/16] Installing cursor theme"
    install_cursor_theme

    pause "[14/16] Configuring graphical environment"
    configure_graphical_environment "$username"

    pause "[15/16] Installing general programs"
    install_general_programs

    pause "[16/16] Finalizing installation"
    finalize_installation
}

main "$@"
