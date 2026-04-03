# My Arch Linux Installer

Para instalar e configurar um Arch Linux (UEFI) usando o script deste repositório, siga esses passos:

No console da ISO do Arch:

1. *(Opcional)* Ajuste o layout de teclado

```bash
loadkeys br-abnt2
```

2. Baixe e extraia o repositório (snapshot)

```bash
curl -L "https://github.com/henry-vg/My-Arch-Linux-Installer/archive/refs/heads/main.tar.gz" | tar -xz
cd My-Arch-Linux-Installer-main
```

3. Dê permissão e execute o instalador

```bash
chmod +x ./install.sh
./install.sh
```

Siga os prompts (disco, tamanhos, usuário etc.).