#!/bin/bash

set -e

trap '' INT

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run as root."
    exit 1
fi

pause() {
    echo
    if [ -n "$1" ]; then
        echo "$1"
    fi
    read -rp "Press Enter to continue..."
    echo
}

partition_path() {
    case "$1" in
        *nvme*|*mmcblk*|*loop*) printf '%sp%s\n' "$1" "$2" ;;
        *) printf '%s%s\n' "$1" "$2" ;;
    esac
}

if [ ! -d /sys/firmware/efi ]; then
    echo "[ERROR] System not booted in UEFI mode. GRUB install will fail."
    exit 1
fi

echo "[1/16] Internet connection check"
ping -c 4 8.8.8.8 > /dev/null 2>&1 || { echo "[ERROR] No internet connection. Exiting..."; exit 1; }

echo "[OK] Connected."

# --------------------------------
pause "[2/16] Initial configuration"
# --------------------------------

echo "Password Rules:"
echo "  - Must contain at least one letter, one digit, or one special character."
echo "  - Must be between 3 and 32 characters long."
echo
while true; do
    read -rsp "Insert root password: " ROOT_PASSWORD
    echo
    read -rsp "Confirm root password: " ROOT_PASSWORD_CONFIRM
    echo
    if [[ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]]; then
        echo "[ERROR] Passwords do not match. Try again."
        continue
    fi
    if [[ ${#ROOT_PASSWORD} -lt 3 || ${#ROOT_PASSWORD} -gt 32 || "$ROOT_PASSWORD" =~ [^a-zA-Z0-9[:punct:]] ]]; then
        echo "[ERROR] Invalid password. Follow the rules above and try again."
        continue
    fi
    break
done
echo "[OK] Root password set successfully."
echo

echo "Username Rules:"
echo "  - Must start with a lowercase letter."
echo "  - Can only contain lowercase letters, numbers, hyphens and underscores."
echo "  - Must be between 3 and 32 characters long."
echo "  - Cannot already exist on the system."
echo
while true; do
    read -rp "Insert the desired username: " USERNAME
    if [[ ! "$USERNAME" =~ ^[a-z][-a-z0-9_]{2,31}$ ]] || id "$USERNAME" &>/dev/null; then
        echo "[ERROR] Invalid or existing username. Try again."
        continue
    fi
    break
done
echo "[OK] Username set successfully."
echo

echo "Password Rules:"
echo "  - Must contain at least one letter, one digit, or one special character"
echo "  - Must be between 3 and 32 characters long."
echo
while true; do
    read -rsp "Insert $USERNAME's password: " USER_PASSWORD
    echo
    read -rsp "Confirm $USERNAME's password: " USER_PASSWORD_CONFIRM
    echo
    if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
        echo "[ERROR] Passwords do not match. Try again."
        continue
    fi
    if [[ ${#USER_PASSWORD} -lt 3 || ${#USER_PASSWORD} -gt 32 || "$USER_PASSWORD" =~ [^a-zA-Z0-9[:punct:]] ]]; then
        echo "[ERROR] Invalid password. Follow the rules above and try again."
        continue
    fi
    break
done
echo "[OK] $USERNAME's password set successfully."
echo

echo "Hostname Rules:"
echo "  - Only lowercase letters, numbers, hyphens, and dots."
echo "  - Cannot start or end with a hyphen."
echo "  - Max 253 characters total, and 63 per segment."
echo
while true; do
    read -rp "Insert the desired hostname: " HOSTNAME
    if [[ ! "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$ ]] || [[ ${#HOSTNAME} -gt 253 ]]; then
        echo "[ERROR] Invalid hostname. Try again."
        continue
    fi
    break
done
echo "[OK] Hostname set successfully."

# --------------------------------
pause "[3/16] Disk selection"
# --------------------------------

echo "Available disks:"
lsblk -d -n -p -o NAME,SIZE,TYPE
while true; do
    read -rp "Enter the disk name (e.g., /dev/sda): " DISK
    if ! lsblk -d -n -p -o NAME,TYPE | grep -Eq "^$DISK\s+disk$"; then
        echo "[ERROR] Invalid disk. Try again."
        continue
    fi
    echo "[OK] Selected disk: $DISK"
    break
done

echo "A 512 MiB EFI (boot) partition will be created automatically."

# --------------------------------
pause "[4/16] Disk sizing"
# --------------------------------

DISK_SIZE_BYTES=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_MIB=$((DISK_SIZE_BYTES / 1024 / 1024))
DISK_SIZE_GIB=$((DISK_SIZE_MIB / 1024))
EFI_SIZE_MIB=512
EFI_END_MIB=513

while true; do
    echo "Disk size is approximately ${DISK_SIZE_GIB} GiB."
    read -rp "Size (GiB) for root (/) partition: " ROOT_SIZE
    read -rp "Size (GiB) for swap partition: " SWAP_SIZE

    if ! [[ "$ROOT_SIZE" =~ ^[0-9]+$ && "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] Sizes must be positive integers."
        continue
    fi

    ROOT_SIZE_MIB=$((ROOT_SIZE * 1024))
    SWAP_SIZE_MIB=$((SWAP_SIZE * 1024))
    TOTAL_MIB=$((EFI_SIZE_MIB + ROOT_SIZE_MIB + SWAP_SIZE_MIB))
    FREE_LEFT_MIB=$((DISK_SIZE_MIB - TOTAL_MIB))

    if (( FREE_LEFT_MIB < 1024 )); then
        echo "[ERROR] Not enough space. Adjust partition sizes."
        continue
    fi

    FREE_LEFT=$((FREE_LEFT_MIB / 1024))
    break
done

echo "[OK] ${FREE_LEFT} GiB will be allocated to /home."

# --------------------------------
pause "[5/16] Disk partitioning"
# --------------------------------

EFI_PART=$(partition_path "$DISK" 1)
ROOT_PART=$(partition_path "$DISK" 2)
SWAP_PART=$(partition_path "$DISK" 3)
HOME_PART=$(partition_path "$DISK" 4)

ROOT_END_MIB=$((EFI_END_MIB + ROOT_SIZE_MIB))
SWAP_END_MIB=$((ROOT_END_MIB + SWAP_SIZE_MIB))

umount -R "$DISK"* 2>/dev/null || true
wipefs --all "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 513MiB ${ROOT_END_MIB}MiB
parted -s "$DISK" mkpart primary linux-swap ${ROOT_END_MIB}MiB ${SWAP_END_MIB}MiB
parted -s "$DISK" mkpart primary ext4 ${SWAP_END_MIB}MiB 100%

echo "[OK] Disk partitioned."

# --------------------------------
pause "[6/16] Formatting partitions"
# --------------------------------

mkfs.fat -F32 "$EFI_PART"
mkfs.ext4 "$ROOT_PART"
swapoff "$SWAP_PART" 2>/dev/null || true
mkswap "$SWAP_PART"
mkfs.ext4 "$HOME_PART"

echo "[OK] Partitions formatted."

# --------------------------------
pause "[7/16] Mounting partitions"
# --------------------------------

mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI_PART" /mnt/boot/efi
mkdir -p /mnt/home
mount "$HOME_PART" /mnt/home
swapon "$SWAP_PART"

echo "[OK] Partitions mounted."

# --------------------------------
pause "[8/16] Installing base system"
# --------------------------------

pacstrap /mnt base linux linux-firmware networkmanager sudo reflector

echo "[OK] Base system installed."

# --------------------------------
pause "[9/16] Generating fstab"
# --------------------------------

genfstab -U /mnt > /mnt/etc/fstab

echo "[OK] fstab generated."

# --------------------------------
pause "[10/16] System configuration"
# --------------------------------

arch-chroot /mnt /bin/bash -c "
pacman -Syu --noconfirm
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
grep -qxF 'en_US.UTF-8 UTF-8' /etc/locale.gen || echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
grep -qxF 'pt_BR.UTF-8 UTF-8' /etc/locale.gen || echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf
echo '$HOSTNAME' > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost.localdomain localhost
::1         localhost.localdomain localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT
echo 'root:$ROOT_PASSWORD' | chpasswd
id -u '$USERNAME' >/dev/null 2>&1 || useradd -m -g users -G wheel '$USERNAME'
echo '$USERNAME:$USER_PASSWORD' | chpasswd
printf '%s ALL=(ALL) ALL\n' '$USERNAME' > '/etc/sudoers.d/10-$USERNAME'
chmod 440 '/etc/sudoers.d/10-$USERNAME'
systemctl enable NetworkManager
reflector --verbose --country Brazil --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
"

unset ROOT_PASSWORD ROOT_PASSWORD_CONFIRM USER_PASSWORD USER_PASSWORD_CONFIRM

echo "[OK] System configured."

# --------------------------------
pause "[11/16] Installing bootloader"
# --------------------------------

arch-chroot /mnt /bin/bash -c "
pacman -S grub efibootmgr os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grep -qxF 'GRUB_DISABLE_OS_PROBER=false' /etc/default/grub || echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
"

echo "[OK] Bootloader installed."

# --------------------------------
pause "[12/16] Installing graphical environment"
# --------------------------------

arch-chroot /mnt /bin/bash -c "
pacman -S --noconfirm xorg-server xorg-xinit i3-wm lightdm lightdm-gtk-greeter rofi kitty feh polybar picom
systemctl enable lightdm
"

echo "[OK] Graphical environment installed."

# --------------------------------
pause "[13/16] Installing cursor theme"
# --------------------------------

CURSOR_THEME="henry-cursors-high-contrast"

install -d -m 755 "/mnt/usr/share/icons"
cp -a "$SCRIPT_DIR/$CURSOR_THEME" "/mnt/usr/share/icons/$CURSOR_THEME"

install -d -m 755 "/mnt/usr/share/icons/default"
cat > "/mnt/usr/share/icons/default/index.theme" <<EOF
[Icon Theme]
Inherits=$CURSOR_THEME
EOF

echo "[OK] Cursor theme installed."

# --------------------------------
pause "[14/16] Configuring graphical environment"
# --------------------------------

install -d -m 755 "/mnt/home/$USERNAME/.config/"
cp -a "$SCRIPT_DIR/dotfiles/.config/." "/mnt/home/$USERNAME/.config/"

install -d -m 755 "/mnt/home/$USERNAME/documents/pictures/wallpapers"
install -m 644 "$SCRIPT_DIR/arch-linux-wallpaper.jpg" "/mnt/home/$USERNAME/documents/pictures/wallpapers"

arch-chroot /mnt /bin/bash -c "
chown -R $USERNAME:users /home/$USERNAME/.config /home/$USERNAME/documents
"

echo "[OK] Graphical environment configured."

# --------------------------------
pause "[15/16] Installing general programs"
# --------------------------------

arch-chroot /mnt /bin/bash -c "
pacman -S --noconfirm firefox locate
updatedb
"

echo "[OK] General programs installed."

# --------------------------------
pause "[16/16] Finalizing installation"
# --------------------------------

echo "Unmounting and rebooting..."
umount -lR /mnt
swapoff -a

for i in {5..1}; do
  echo "Rebooting in $i second(s)..."
  sleep 1
done

reboot
