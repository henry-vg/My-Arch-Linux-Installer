#!/bin/bash

pause() {
    echo
    if [ -n "$1" ]; then
        echo "$1"
    fi
    read -rp "Press Enter to continue or Ctrl+C to abort..."
    echo
}

echo "[1/15] Internet connection check"
ping -c 4 8.8.8.8 > /dev/null 2>&1 || { echo "[ERROR] No internet connection. Exiting..."; exit 1; }

echo "[OK] Connected."
pause "[2/15] Initial configuration"

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
    if [[ ! "$HOSTNAME" =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9]))*$ ]] || [[ ${#HOSTNAME} -gt 253 ]]; then
        echo "[ERROR] Invalid hostname. Try again."
        continue
    fi
    break
done
echo "[OK] Hostname set successfully."
pause "[3/15] Disk selection"

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
pause "[4/15] Disk sizing"

DISK_SIZE_BYTES=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_GIB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024 - 1))

while true; do
    echo "Disk size is approximately ${DISK_SIZE_GIB} GiB."
    read -rp "Size (GiB) for root (/) partition: " ROOT_SIZE
    read -rp "Size (GiB) for swap partition: " SWAP_SIZE

    if ! [[ "$ROOT_SIZE" =~ ^[0-9]+$ && "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] Sizes must be positive integers."
        continue
    fi

    TOTAL=$((512/1024 + ROOT_SIZE + SWAP_SIZE))
    if (( TOTAL >= DISK_SIZE_GIB )); then
        echo "[ERROR] Not enough space. Adjust partition sizes."
        continue
    fi

    FREE_LEFT=$((DISK_SIZE_GIB - TOTAL))
    break
done

echo "[OK] ${FREE_LEFT} GiB will be allocated to /home."
pause "[5/15] Disk partitioning"

ROOT_END=$((512/1024 + ROOT_SIZE))
SWAP_END=$((ROOT_END + SWAP_SIZE))

umount -R "$DISK"* 2>/dev/null || true
wipefs --all "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 513MiB ${ROOT_END}GiB
parted -s "$DISK" mkpart primary linux-swap ${ROOT_END}GiB ${SWAP_END}GiB
parted -s "$DISK" mkpart primary ext4 ${SWAP_END}GiB 100%

echo "[OK] Disk partitioned."
pause "[6/15] Formatting partitions"

mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
swapoff "$DISK"3 2>/dev/null || true
mkswap "${DISK}3"
mkfs.ext4 "${DISK}4"

echo "[OK] Partitions formatted."
pause "[7/15] Mounting partitions"

mount "${DISK}2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi
mkdir -p /mnt/home
mount "${DISK}4" /mnt/home
swapon "${DISK}3"

echo "[OK] Partitions mounted."
pause "[8/15] Installing base system"

pacstrap /mnt base linux linux-firmware networkmanager sudo

echo "[OK] Base system installed."
pause "[9/15] Generating fstab"

genfstab -U /mnt >> /mnt/etc/fstab

echo "[OK] fstab generated."
pause "[10/15] System configuration"

arch-chroot /mnt /bin/bash -c "
pacman -Syu --noconfirm
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'pt_BR.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo 'KEYMAP=br-abnt2' > /etc/vconsole.conf
echo '$HOSTNAME' > /etc/hostname
cat <<EOT >> /etc/hosts
127.0.0.1   localhost.localdomain localhost
::1         localhost.localdomain localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT
echo 'root:$ROOT_PASSWORD' | chpasswd
useradd -m -g users -G wheel $USERNAME
echo '$USERNAME:$USER_PASSWORD' | chpasswd
echo '$USERNAME ALL=(ALL) ALL' | EDITOR='tee -a' visudo
systemctl enable NetworkManager
"

unset ROOT_PASSWORD ROOT_PASSWORD_CONFIRM USER_PASSWORD USER_PASSWORD_CONFIRM

echo "[OK] System configured."
pause "[11/15] Installing bootloader"

if [ ! -d /sys/firmware/efi ]; then
    echo "[ERROR] System not booted in UEFI mode. GRUB install will fail."
    exit 1
fi

arch-chroot /mnt /bin/bash -c "
pacman -S grub efibootmgr os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
"

echo "[OK] Bootloader installed."
pause "[12/15] Installing graphical interface"

arch-chroot /mnt /bin/bash -c "
pacman -S --noconfirm xorg-server gnome-shell gnome-session gnome-terminal gdm mesa
systemctl enable gdm
"

echo "[OK] Graphical environment installed."
pause "[13/15] Installing extra tools"

# firefox                  (web browser)
# baobab                   (GNOME - analisador gráfico de uso do disco)
# loupe                    (GNOME - visualizador de imagens)
# gnome-system-monitor     (GNOME - monitor de processos e uso de recursos)
# gnome-screenshot         (GNOME - captura de tela)
# gnome-tweaks             (GNOME - ajustes avançados do ambiente)
# gnome-font-viewer        (GNOME - visualizador e instalador de fontes)
# gnome-disk-utility       (GNOME - gerenciador de discos com interface gráfica)
# gnome-calculator         (GNOME - calculadora)
# gnome-clocks             (GNOME - relógio com alarme, cronômetro e fuso horário)
# gnome-weather            (GNOME - previsão do tempo)
# gnome-backgrounds        (GNOME - papéis de parede)
# gnome-calendar           (GNOME - calendário gráfico com eventos)
# gnome-control-center     (GNOME - painel de configurações)
# gnome-text-editor        (GNOME - editor de texto simples)
# gnome-music              (GNOME - reprodutor de música)
# gnome-browser-connector  (GNOME - para gerenciar extensões pelo browser)
# totem                    (GNOME - reprodutor de vídeos)
# gparted                  (editor de partições com interface gráfica)
# network-manager-applet   (ícone de rede na bandeja do sistema)
# networkmanager-openvpn   (suporte a conexões VPN do tipo OpenVPN)
# intel-ucode              (microcódigo da Intel para melhorar segurança e estabilidade da CPU)
# rclone                   (para sincronização com onedrive)
# libreoffice              (office suite completo)
# keepass                  (gerenciador de senhas)
# xdotool                  (para autotype do keepass)
# eyedropper               (seletor de cores na tela)
# piper                    (configuração de periféricos)
# base-devel               (conjunto essencial para compilar pacotes)
# reflector                (para acelerar downloads (atualiza e ordena espelhos de repositório))
# wget                     (download via terminal)
# traceroute               (rastreador de pacotes na rede)
# nmap                     (scanner de rede e segurança)
# rsync                    (sincronização e backup de arquivos)
# neovim                   (editor de texto avançado baseado no Vim)
# bleachbit                (limpeza de arquivos temporários)
# git                      (sistema de controle de versões)
# which                    (localiza a localização de um executável no PATH)
# nano                     (editor de texto simples e fácil no terminal)
# tree                     (exibe estrutura de diretórios como uma árvore)
# lsof                     (lista arquivos abertos por processos)
# inetutils                (coleção de utilitários de rede)
# zip                      (compactador de arquivos no formato .zip)

arch-chroot /mnt /bin/bash -c "
pacman -S --noconfirm firefox baobab loupe gnome-system-monitor gnome-screenshot gnome-tweaks gnome-font-viewer gnome-disk-utility gnome-calculator gnome-clocks gnome-weather gnome-backgrounds gnome-calendar gnome-control-center gnome-text-editor gnome-music gnome-browser-connector totem gparted network-manager-applet networkmanager-openvpn intel-ucode rclone libreoffice keepass xdotool eyedropper piper base-devel reflector wget traceroute nmap rsync neovim bleachbit git which nano tree lsof inetutils zip 
"

echo "[OK] Extra tools installed."
pause "[14/15] Configuring user environment"

arch-chroot /mnt /bin/bash -c "
runuser -l $USERNAME -c \"
gsettings set org.gnome.desktop.input-sources sources \\\"[('xkb', 'br')]\\\"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.system.locale region 'pt_BR.UTF-8'
gsettings set org.gnome.desktop.interface clock-show-seconds true
gsettings set org.gnome.mutter dynamic-workspaces false
gsettings set org.gnome.desktop.wm.preferences num-workspaces 1
gsettings set org.gnome.desktop.wm.preferences button-layout ':minimize,maximize,close'
\"
"
echo "[OK] User environment configured."
pause "[15/15] Finalizing installation"

echo "Unmounting and rebooting..."
umount -lR /mnt
swapoff -a
for i in {5..1}; do
  echo "Rebooting in $i second(s)..."
  sleep 1
done

reboot
