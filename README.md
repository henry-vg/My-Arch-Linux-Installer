# My Arch Linux Installer

To install and configure Arch Linux (UEFI) using this repository's script, follow these steps:

In the Arch ISO console:

1. *(Optional)* Set the keyboard layout

```bash
loadkeys br-abnt2
```

2. Download and extract the repository snapshot

```bash
curl -L "https://github.com/henry-vg/My-Arch-Linux-Installer/archive/refs/heads/main.tar.gz" | tar -xz
cd My-Arch-Linux-Installer-main
```

3. Make the installer executable and run it

```bash
chmod +x ./main.sh
./main.sh
```

Follow the prompts (disk, sizes, user, etc.).
