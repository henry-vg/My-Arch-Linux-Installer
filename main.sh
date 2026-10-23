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
    require_root
    require_uefi

    pause "[1/16] Internet connection check"
    check_internet_connection

    pause "[2/16] Initial configuration"
    collect_system_configuration

    pause "[3/16] Disk selection"
    select_disk

    pause "[4/16] Disk sizing"
    select_partition_sizes

    pause "[5/16] Disk partitioning"
    partition_disk

    pause "[6/16] Formatting partitions"
    format_partitions

    pause "[7/16] Mounting partitions"
    mount_partitions

    pause "[8/16] Installing base system"
    install_base_system

    pause "[9/16] Generating fstab"
    generate_fstab

    pause "[10/16] System configuration"
    configure_system

    pause "[11/16] Installing bootloader"
    install_bootloader

    pause "[12/16] Installing graphical environment"
    install_graphical_environment

    pause "[13/16] Installing cursor theme"
    install_cursor_theme

    pause "[14/16] Configuring graphical environment"
    configure_graphical_environment

    pause "[15/16] Installing general programs"
    install_general_programs

    pause "[16/16] Finalizing installation"
    finalize_installation
}

main "$@"
