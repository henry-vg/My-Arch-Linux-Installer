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

## Cursores

Abaixo segue os aliases para o `henry-cursors`:

```bash
ln -sf arrow default
ln -sf bd_double_arrow nwse-resize
ln -sf bottom_left_corner sw-resize
ln -sf bottom_right_corner se-resize
ln -sf bottom_side s-resize
ln -sf col-resize ew-resize
ln -sf cross crosshair
ln -sf cross_reverse crosshair
ln -sf diamond_cross crosshair
ln -sf e-resize ew-resize
ln -sf fd_double_arrow nesw-resize
ln -sf fleur move
ln -sf hand1 grab
ln -sf hand2 pointer
ln -sf left_ptr default
ln -sf left_ptr_watch progress
ln -sf left_side w-resize
ln -sf n-resize ns-resize
ln -sf ne-resize nesw-resize
ln -sf nw-resize nwse-resize
ln -sf question_arrow help
ln -sf right_side e-resize
ln -sf row-resize ns-resize
ln -sf s-resize ns-resize
ln -sf sb_h_double_arrow ew-resize
ln -sf sb_v_double_arrow ns-resize
ln -sf se-resize nwse-resize
ln -sf sw-resize nesw-resize
ln -sf tcross crosshair
ln -sf top_left_arrow default
ln -sf top_left_corner nw-resize
ln -sf top_right_corner ne-resize
ln -sf top_side n-resize
ln -sf w-resize ew-resize
ln -sf watch wait
ln -sf xterm text
```