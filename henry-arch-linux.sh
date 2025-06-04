#!/bin/bash

# ----------- Verificação da Conexão com a Internet -----------
echo "Checking internet connection..."
ping -c 3 google.com > /dev/null 2>&1 || { echo "No internet connection. Exiting..."; exit 1; }
# -------------------------------------------------------------

# ----------------------- Configurações -----------------------
# Escolha da senha do root
echo "Password Rules:"
echo "  - Must contain at least one letter, one digit, or one special character"
echo "  - Must be between 3 and 32 characters long."
echo
while true; do
    read -rsp "Insert root's password: " ROOT_PASSWORD
    echo
    read -rsp "Confirm root's password: " ROOT_PASSWORD_CONFIRM
    echo
    if [[ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]]; then
        echo "ERROR! Passwords do not match. Try again."
        continue
    fi
    if [[ ${#ROOT_PASSWORD} -lt 3 || ${#ROOT_PASSWORD} -gt 32 || ! "$ROOT_PASSWORD" =~ [a-zA-Z] && ! "$ROOT_PASSWORD" =~ [0-9] && ! "$ROOT_PASSWORD" =~ [[:punct:]] ]]; then
        echo "ERROR! Invalid password. Please, follow the rules above and try again."
        continue
    fi
    break
done

# Escolha do nome do usuário
echo "Username Rules:"
echo "  - Must start with a lowercase letter."
echo "  - Can only contain lowercase letters, numbers, hyphens and underscores."
echo "  - Must be between 3 and 32 characters long."
echo "  - Cannot already exist on the system."
echo
while true; do
    read -rp "Insert the desired username: " USERNAME
    if [[ ! "$USERNAME" =~ ^[a-z][-a-z0-9_]{2,31}$ ]] || id "$USERNAME" &>/dev/null; then
        echo "ERROR! Invalid username. Please, follow the rules above and try again."
        continue
    fi
    break
done

# Escolha da senha do usuário
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
        echo "ERROR! Passwords do not match. Try again."
        continue
    fi
    if [[ ${#USER_PASSWORD} -lt 3 || ${#USER_PASSWORD} -gt 32 || ! "$USER_PASSWORD" =~ [a-zA-Z] && ! "$USER_PASSWORD" =~ [0-9] && ! "$USER_PASSWORD" =~ [[:punct:]] ]]; then
        echo "ERROR! Invalid password. Please, follow the rules above and try again."
        continue
    fi
    break
done

# Escolha do hostname
echo "Hostname Rules:"
echo "  - Must contain only lowercase letters, numbers, hyphens, and dots."
echo "  - Cannot start or end with a hyphen."
echo "  - Must be at most 253 characters long."
echo "  - Each segment (split by dots) must be at most 63 characters long."
echo
while true; do
    read -rp "Insert the desired hostname: " HOSTNAME
    if [[ ! "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9]))*$ ]] || [[ ${#HOSTNAME} -gt 253 ]]; then
        echo "ERROR! Invalid hostname. Please, follow the rules above and try again."
        continue
    fi
    break
done

# Escolha do disco
echo "Available disks:"
lsblk -d -n -p -o NAME,SIZE,TYPE
while true; do
    read -rp "Insert the disk name to install Arch Linux: " DISK
    if ! lsblk -d -n -p -o NAME,TYPE | grep -E "^$DISK\s+disk$" > /dev/null; then
        echo "ERROR! Invalid disk name. Try again."
        continue
    fi
    echo "Disk \"$DISK\" selected."
    break
done
# -------------------------------------------------------------


# Limpeza do disco
echo "Cleaning the disk..."
wipefs --all "$DISK"

# Criação das partições
echo "Creating partitions..."
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 501MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 501MiB 50.5GiB
parted -s "$DISK" mkpart primary linux-swap 50.5GiB 58.5GiB
parted -s "$DISK" mkpart primary ext4 58.5GiB 100%

# Formatação das partições
echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
mkswap "${DISK}3"

# Montagem das partições
echo "Mounting partitions..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi
mkdir -p /mnt/home
mount "${DISK}4" /mnt/home
swapon "${DISK}3"

# Instalação do sistema base
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware networkmanager wpa_supplicant sudo dhcpcd

# Criação do fstab
echo "Generating fstab file..."
genfstab -U /mnt >> /mnt/etc/fstab

# Configuração do sistema
echo "Configuring system..."
arch-chroot /mnt /bin/bash <<EOF
pacman -Sy --noconfirm
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1   localhost.localdomain localhost
::1         localhost.localdomain localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT
echo "root:$ROOT_PASSWORD" | chpasswd
useradd -m -g users -G wheel $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd
echo "$USERNAME ALL=(ALL) ALL" | EDITOR='tee -a' visudo
systemctl enable NetworkManager
EOF

# Instação do bootloader
echo "Installing bootloader..."
arch-chroot /mnt /bin/bash <<EOF
pacman -S grub efibootmgr os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
EOF

# Instalação da interface gráfica
echo "Installing graphical user interface..."
arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm xorg-server nvidia nvidia-utils nvidia-prime nvidia-settings mesa gdm gnome-shell gnome-terminal gnome-control-center gnome-tweaks
systemctl enable gdm
EOF

# Instação de ferramentas adicionais
echo "Installing additional tools..."
arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm firefox nautilus gimp network-manager-applet networkmanager-openvpn intel-ucode dosfstools ntfs-3g exfat-utils nano git wget curl zip unzip
EOF

# Fim da instalação
echo "Arch Linux installation finished. Unmounting partitions..."
umount -lR /mnt
echo "Disabling swap partitions..."
swapoff -a
echo "Rebooting in 5 seconds..."
sleep 5
reboot