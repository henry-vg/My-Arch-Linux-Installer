#!/bin/bash

pause() {
    echo
    read -rp "Pressione Enter para continuar ou Ctrl+C para abortar..."
    echo
}

# ----------- Verificação da Conexão com a Internet -----------
echo "[1/10] Verificando conexão com a internet..."
ping -c 3 google.com > /dev/null 2>&1 || { echo "Sem conexão com a internet. Encerrando..."; exit 1; }
echo "✓ Conectado."
pause

# ----------------------- Configurações -----------------------
echo "[2/10] Configurações iniciais"

# Senha root
# ... (mesmo código de validação de senha root)
# Usuário
# ... (validação de nome de usuário)
# Senha do usuário
# ... (validação de senha de usuário)
# Hostname
# ... (validação do hostname)
pause

# Escolha do disco
echo "[3/10] Escolha do disco para instalação"
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

# Limpeza e particionamento
echo "[4/10] Limpando e particionando o disco..."
wipefs --all "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 501MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart primary ext4 501MiB 50.5GiB
parted -s "$DISK" mkpart primary linux-swap 50.5GiB 58.5GiB
parted -s "$DISK" mkpart primary ext4 58.5GiB 100%
echo "✓ Particionamento concluído."
pause

# Formatação
echo "[5/10] Formatando particoes..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 "${DISK}2"
mkfs.ext4 "${DISK}4"
mkswap "${DISK}3"
echo "✓ Partições formatadas."
pause

# Montagem
echo "[6/10] Montando particoes..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}1" /mnt/boot/efi
mkdir -p /mnt/home
mount "${DISK}4" /mnt/home
swapon "${DISK}3"
echo "✓ Partições montadas."
pause

# Instalação base
echo "[7/10] Instalando sistema base..."
pacstrap /mnt base linux linux-firmware networkmanager wpa_supplicant sudo dhcpcd
echo "✓ Sistema base instalado."
pause

# fstab
echo "[8/10] Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "✓ fstab gerado."
pause

# Configuração via chroot
echo "[9/10] Entrando no ambiente chroot para configuração..."
arch-chroot /mnt /bin/bash <<EOF
# ...
EOF
echo "✓ Configuração concluída."
pause

# Interface gráfica e ferramentas
echo "[10/10] Instalando interface gráfica e ferramentas..."
arch-chroot /mnt /bin/bash <<EOF
# ...
EOF
echo "✓ Ambiente gráfico instalado."
pause

echo "Instalação concluída. Desmontando particoes e reiniciando."
umount -lR /mnt
swapoff -a
echo "Reiniciando em 5 segundos..."
sleep 5
reboot
