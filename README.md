# My Arch Linux Installer

A personal Arch Linux installation and desktop configuration project, built around a minimal, modular system with full control over its appearance and behavior. The installer sets up the system; configuration files and small integration scripts define the desktop without requiring a full desktop environment.

The intended architecture uses Sway for window management, Eww for custom desktop interfaces, and dedicated tools for the underlying functionality. See [MANIFESTO.md](MANIFESTO.md) for the project's principles and architectural decisions.

## Installation

Boot the official Arch Linux installation medium in **UEFI mode**, connect to the internet, and open a root shell (the Arch ISO starts as root by default). The installer requires a dedicated target disk: **all existing partitions and data on the selected disk will be erased** after an explicit confirmation. It is not a dual-boot installer.

1. Optionally select the Brazilian ABNT2 keyboard layout:

   ```bash
   loadkeys br-abnt2
   ```

2. Download and enter the repository:

   ```bash
   curl -fL https://github.com/henry-vg/My-Arch-Linux-Installer/archive/refs/heads/main.tar.gz -o installer.tar.gz
   tar -xzf installer.tar.gz
   cd My-Arch-Linux-Installer-main
   ```

3. Run the installer as root:

   ```bash
   bash main.sh
   ```

4. Follow the prompts to set the root and user passwords, username, hostname, target disk, and partition sizes. Confirm disk erasure only after verifying the selected device.

The partition layout is GPT with a **512 MiB EFI system partition**, an **ext4 root partition of at least 32 GiB**, a swap partition, and an **ext4 `/home` partition** using the remaining space. Both root and swap sizes are selected during installation; `/home` requires at least 1 GiB of remaining space.

The installer configures the base system, network management, locale, time zone, user permissions, and GRUB bootloader, then reboots. After rebooting, sign in with the username and password you provided.

## Using and customizing the system

The desktop is organized by responsibility rather than as a monolithic desktop environment:

| Location | Purpose |
| --- | --- |
| `~/.config/` | Application and desktop configuration, including Eww interface definitions and styling |
| `~/.scripts/` | Small, independent Bash scripts for desktop automation and integration, when necessary |
| `~/.local/share/` | User-managed static resources, such as wallpapers or custom icons |

Use each program's native configuration whenever possible. Eww provides the custom visual interface; it delegates window management, audio, networking, and other system operations to the tools responsible for them. Desktop shortcuts and behavior are configured in the corresponding applications, such as Sway.

System-level requirements (packages, services, permissions, and configuration outside the home directory) belong to the installer. This separation makes the environment understandable and reproducible without maintaining patched applications or a custom desktop framework.

For routine Arch Linux package updates, use:

```bash
sudo pacman -Syu
```

Packages installed through the AUR, if any, require separate maintenance through their package build/update workflow; `pacman -Syu` alone does not update them.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `main.sh` | Installation entry point and execution sequence |
| `src/` | Shell modules for installation, disk setup, system configuration, and components |
| `assets/` | Static resources provided with the installer |
| `README.md` | Project overview, installation, and usage |
| `MANIFESTO.md` | Vision, principles, and architectural decisions |
| `AGENTS.md` | Instructions for Codex working on the repository |

The installer and its modules are designed to reproduce the approved system configuration on a clean installation.
