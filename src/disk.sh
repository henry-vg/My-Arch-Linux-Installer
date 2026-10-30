partition_path() {
    case "$1" in
        *nvme*|*mmcblk*|*loop*) printf '%sp%s\n' "$1" "$2" ;;
        *) printf '%s%s\n' "$1" "$2" ;;
    esac
}

select_disk() {
    local -n selected_disk="$1"

    log "Available disks:"
    lsblk -d -n -p -o NAME,SIZE,TYPE

    while true; do
        read -rp "$(input_prompt 'Enter the disk name (e.g., /dev/sda): ')" selected_disk
        if [[ "$(lsblk -d -n -o TYPE "$selected_disk" 2>/dev/null)" != disk ]]; then
            log "[ERROR] Invalid disk. Try again."
            continue
        fi
        break
    done

    log "[INFO] Selected disk: $selected_disk"
    log "A 512 MiB EFI (boot) partition will be created automatically."
}

select_partition_sizes() {
    local disk="$1"
    local -n root_size_mib_output="$2" swap_size_mib_output="$3"
    local disk_size_bytes disk_size_mib disk_size_gib root_size swap_size free_space_mib
    local minimum_root_size_gib="32"

    disk_size_bytes="$(lsblk -b -d -n -o SIZE "$disk")"
    disk_size_mib=$((disk_size_bytes / 1024 / 1024))
    disk_size_gib=$((disk_size_mib / 1024))

    while true; do
        log "Disk size is approximately ${disk_size_gib} GiB."
        read -rp "$(input_prompt 'Size (GiB) for root (/) partition: ')" root_size
        read -rp "$(input_prompt 'Size (GiB) for swap partition: ')" swap_size

        if [[ ! "$root_size" =~ ^[1-9][0-9]*$ || ! "$swap_size" =~ ^[1-9][0-9]*$ ]]; then
            log "[ERROR] Sizes must be positive integers."
            continue
        fi

        if (( root_size < minimum_root_size_gib )); then
            log "[ERROR] Root must be at least $minimum_root_size_gib GiB."
            continue
        fi

        if (( ${#root_size} > ${#disk_size_gib} || ${#swap_size} > ${#disk_size_gib} )); then
            log "[ERROR] Not enough space. Adjust partition sizes."
            continue
        fi

        root_size_mib_output=$((root_size * 1024))
        swap_size_mib_output=$((swap_size * 1024))
        free_space_mib=$((disk_size_mib - 512 - root_size_mib_output - swap_size_mib_output))

        if (( free_space_mib < 1024 )); then
            log "[ERROR] Not enough space. Adjust partition sizes."
            continue
        fi
        break
    done

    log "[INFO] /home will use the remaining disk space (about $((free_space_mib / 1024)) GiB)."
}

partition_disk() {
    local disk="$1" root_size_mib="$2" swap_size_mib="$3"
    local root_end_mib swap_end_mib partition filesystem mountpoint partition_number

    log "Disk to erase: $disk ($(lsblk -d -n -o SIZE "$disk"))"
    log "[WARNING] All data on $disk will be permanently erased."
    if ! confirm_action "Erase $disk?" no; then
        log "[INFO] Disk partitioning canceled."
        return 1
    fi

    root_end_mib=$((513 + root_size_mib))
    swap_end_mib=$((root_end_mib + swap_size_mib))

    while read -r partition filesystem; do
        if [[ "$filesystem" == swap ]]; then
            swapoff "$partition" 2>/dev/null || true
        fi
    done < <(lsblk -n -r -p -o NAME,FSTYPE "$disk")

    while IFS= read -r mountpoint; do
        if [[ "$mountpoint" == /* ]]; then
            umount -R "$mountpoint"
        fi
    done < <(lsblk -n -r -o MOUNTPOINT "$disk" | sort -r)

    wipefs --all "$disk"
    parted -s "$disk" mklabel gpt
    parted -s "$disk" mkpart ESP fat32 1MiB 513MiB
    parted -s "$disk" set 1 esp on
    parted -s "$disk" mkpart primary ext4 513MiB "${root_end_mib}MiB"
    parted -s "$disk" mkpart primary linux-swap "${root_end_mib}MiB" "${swap_end_mib}MiB"
    parted -s "$disk" mkpart primary ext4 "${swap_end_mib}MiB" 100%
    partprobe "$disk"
    udevadm settle

    for partition_number in {1..4}; do
        if [[ ! -b "$(partition_path "$disk" "$partition_number")" ]]; then
            log "[ERROR] Partition $partition_number is not available."
            return 1
        fi
    done

    log "[INFO] Disk partitioned."
}

format_partitions() {
    local efi_partition="$1" root_partition="$2" swap_partition="$3" home_partition="$4"

    mkfs.fat -F32 "$efi_partition"
    mkfs.ext4 "$root_partition"
    mkswap "$swap_partition"
    mkfs.ext4 "$home_partition"
    log "[INFO] Partitions formatted."
}

mount_partitions() {
    local efi_partition="$1" root_partition="$2" swap_partition="$3" home_partition="$4"

    mount "$root_partition" /mnt
    mkdir -p /mnt/boot/efi /mnt/home
    mount "$efi_partition" /mnt/boot/efi
    mount "$home_partition" /mnt/home
    swapon "$swap_partition"
    log "[INFO] Partitions mounted."
}
