#!/bin/bash

pause() {
    echo
    read -rp "Pressione Enter para continuar ou Ctrl+C para abortar..."
    echo
}

# ----------- Verificação da Conexão com a Internet -----------
echo "[1/12] Verificando conexão com a internet..."
ping -c 3 google.com > /dev/null 2>&1 || { echo "Sem conexão com a internet. Encerrando..."; exit 1; }
echo "✓ Conectado."
pause

# ----------------------- Configurações -----------------------
echo "[2/12] Configurações iniciais"

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
pause

# Escolha do disco
echo "[3/12] Escolha do disco para instalação"
echo "Discos disponíveis:"
lsblk -d -n -p -o NAME,SIZE,TYPE
while true; do
    read -rp "Insira o nome do disco (ex: /dev/sda): " DISK
    if ! lsblk -d -n -p -o NAME,TYPE | grep -Eq "^$DISK\s+disk$"; then
        echo "ERRO! Disco inválido. Tente novamente."
        continue
    fi
    echo "Disco selecionado: $DISK"
    break
done
pause

# ---------------------- Tamanhos personalizados ----------------------
echo "[INFO] Será criada uma partição EFI (boot) de 512 MiB automaticamente."
pause
DISK_SIZE_BYTES=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_GIB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024 - 1))

while true; do
    echo "O disco tem aproximadamente ${DISK_SIZE_GIB} GiB."
    read -rp "Tamanho (em GiB) para a particao root (/): " ROOT_SIZE
    read -rp "Tamanho (em GiB) para a particao swap: " SWAP_SIZE

    if ! [[ "$ROOT_SIZE" =~ ^[0-9]+$ && "$SWAP_SIZE" =~ ^[0-9]+$ ]]; then
        echo "Erro: valores devem ser inteiros positivos."
        continue
    fi

    TOTAL=$((512/1024 + ROOT_SIZE + SWAP_SIZE))  # 512MiB = ~0.5 GiB

    if (( TOTAL >= DISK_SIZE_GIB )); then
        echo "Erro: espaço solicitado excede o tamanho do disco."
        continue
    fi

    FREE_LEFT=$((DISK_SIZE_GIB - TOTAL))
    echo "✓ ${FREE_LEFT} GiB serão usados para /home"
    read -rp "Confirmar particionamento com esses tamanhos? (s/n): " CONFIRMA
    [[ "$CONFIRMA" =~ ^[sS]$ ]] && break
done
pause

# Limpeza e particionamento
# ---------------------- Particionamento ----------------------
ROOT_END=$((512/1024 + ROOT_SIZE))
SWAP_END=$((ROOT_END + SWAP_SIZE))

echo "[4/12] Limpando e particionando o disco $DISK..."
wipefs --all "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 512MiB ${ROOT_END}GiB
parted -s "$DISK" mkpart primary linux-swap ${ROOT_END}GiB ${SWAP_END}GiB
parted -s "$DISK" mkpart primary ext4 ${SWAP_END}GiB 100%
echo "✓ Particionamento concluído."
pause

# Formatação
echo "[5/12] Formatando particoes..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
mkswap "${DISK}3"
echo "✓ Partições formatadas."
pause

# Montagem
echo "[6/12] Montando particoes..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi
mkdir -p /mnt/home
mount "${DISK}4" /mnt/home
swapon "${DISK}3"
echo "✓ Partições montadas."
pause

# Instalação base
echo "[7/12] Instalando sistema base..."
pacstrap /mnt base linux linux-firmware networkmanager wpa_supplicant sudo dhcpcd
echo "✓ Sistema base instalado."
pause

# fstab
echo "[8/12] Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "✓ fstab gerado."
pause

# Configuração via chroot
echo "[9/12] Entrando no ambiente chroot para configuração..."
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
echo "✓ Configuração concluída."
pause

# Instalação do bootloader
echo "[10/12] Instalando bootloader..."
arch-chroot /mnt /bin/bash <<EOF
pacman -S grub efibootmgr os-prober --noconfirm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
EOF
echo "✓ Instalação do bootloader concluída."
pause

# Interface gráfica
echo "[11/12] Instalando interface gráfica"
arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm xorg-server nvidia nvidia-utils nvidia-prime nvidia-settings mesa gdm gnome-shell gnome-terminal gnome-control-center gnome-tweaks
systemctl enable gdm
EOF
echo "✓ Ambiente gráfico instalado."
pause

# Instação de ferramentas adicionais
echo "[12/12] Instalando ferramentas adicionais..."
arch-chroot /mnt /bin/bash <<EOF
pacman -S --noconfirm firefox nautilus gimp network-manager-applet networkmanager-openvpn intel-ucode dosfstools ntfs-3g exfat-utils nano git wget curl zip unzip
EOF
echo "✓ Ferramentas adicionais instaladas."
pause

echo "Instalação concluída. Desmontando particoes e reiniciando."
umount -lR /mnt
swapoff -a
echo "Reiniciando em 5 segundos..."
sleep 5
reboot
