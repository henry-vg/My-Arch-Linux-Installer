partition_path() {
    case "$1" in
        *nvme*|*mmcblk*|*loop*) printf '%sp%s\n' "$1" "$2" ;;
        *) printf '%s%s\n' "$1" "$2" ;;
    esac
}

select_disk() {
    echo "Available disks:"
    lsblk -d -n -p -o NAME,SIZE,TYPE

    while true; do
        read -rp "Enter the disk name (e.g., /dev/sda): " DISK
        if [[ $(lsblk -d -n -o TYPE "$DISK" 2>/dev/null) != disk ]]; then
            echo "[ERROR] Invalid disk. Try again."
            continue
        fi
        break
    done

    echo "[OK] Selected disk: $DISK"
    echo "A 512 MiB EFI (boot) partition will be created automatically."
}

select_partition_sizes() {
    local disk_size_bytes disk_size_mib disk_size_gib root_size swap_size free_space_mib

    disk_size_bytes=$(lsblk -b -dn -o SIZE "$DISK")
    disk_size_mib=$((disk_size_bytes / 1024 / 1024))
    disk_size_gib=$((disk_size_mib / 1024))

    while true; do
        echo "Disk size is approximately ${disk_size_gib} GiB."
        read -rp "Size (GiB) for root (/) partition: " root_size
        read -rp "Size (GiB) for swap partition: " swap_size

        if [[ ! "$root_size" =~ ^[1-9][0-9]*$ || ! "$swap_size" =~ ^[1-9][0-9]*$ ]]; then
            echo "[ERROR] Sizes must be positive integers."
            continue
        fi

        if (( ${#root_size} > ${#disk_size_gib} || ${#swap_size} > ${#disk_size_gib} )); then
            echo "[ERROR] Not enough space. Adjust partition sizes."
            continue
        fi

        ROOT_SIZE_MIB=$((root_size * 1024))
        SWAP_SIZE_MIB=$((swap_size * 1024))
        free_space_mib=$((disk_size_mib - 512 - ROOT_SIZE_MIB - SWAP_SIZE_MIB))

        if (( free_space_mib < 1024 )); then
            echo "[ERROR] Not enough space. Adjust partition sizes."
            continue
        fi
        break
    done

    echo "[OK] $((free_space_mib / 1024)) GiB will be allocated to /home."
}

partition_disk() {
    local root_end_mib swap_end_mib partition filesystem mountpoint

    EFI_PART=$(partition_path "$DISK" 1)
    ROOT_PART=$(partition_path "$DISK" 2)
    SWAP_PART=$(partition_path "$DISK" 3)
    HOME_PART=$(partition_path "$DISK" 4)
    root_end_mib=$((513 + ROOT_SIZE_MIB))
    swap_end_mib=$((root_end_mib + SWAP_SIZE_MIB))

    while read -r partition filesystem; do
        if [[ "$filesystem" == swap ]]; then
            swapoff "$partition" 2>/dev/null || true
        fi
    done < <(lsblk -nr -p -o NAME,FSTYPE "$DISK")

    while IFS= read -r mountpoint; do
        if [[ "$mountpoint" == /* ]]; then
            umount -R "$mountpoint"
        fi
    done < <(lsblk -nr -o MOUNTPOINT "$DISK" | sort -r)

    wipefs --all "$DISK"
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart primary ext4 513MiB "${root_end_mib}MiB"
    parted -s "$DISK" mkpart primary linux-swap "${root_end_mib}MiB" "${swap_end_mib}MiB"
    parted -s "$DISK" mkpart primary ext4 "${swap_end_mib}MiB" 100%

    echo "[OK] Disk partitioned."
}

format_partitions() {
    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 "$ROOT_PART"
    mkswap "$SWAP_PART"
    mkfs.ext4 "$HOME_PART"
    echo "[OK] Partitions formatted."
}

mount_partitions() {
    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi /mnt/home
    mount "$EFI_PART" /mnt/boot/efi
    mount "$HOME_PART" /mnt/home
    swapon "$SWAP_PART"
    echo "[OK] Partitions mounted."
}
