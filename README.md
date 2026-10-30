# My Arch Linux Installer

`main.sh` installs a bootable Arch Linux base system in UEFI mode. It runs the steps defined in `src/`.

| File | Responsibility |
| --- | --- |
| `console.sh` | Prompts, progress messages, and terminal colors |
| `requirements.sh` | Root, UEFI, and internet checks |
| `installation_details.sh` | Hostname, username, and passwords |
| `disk.sh` | Disk selection, partitioning, formatting, and mounting |
| `system.sh` | Base packages, system settings, bootloader, and reboot |
| `graphical_environment.sh` | Graphical environment installation and configuration |
| `cursor_theme.sh` | Install the default cursor theme |
| `general_programs.sh` | Install general programs |

## Install

From the Arch ISO:

1. Optionally set the keyboard layout with `loadkeys br-abnt2`.
2. Download the repository:

   ```bash
   curl -L "https://github.com/henry-vg/My-Arch-Linux-Installer/archive/refs/heads/main.tar.gz" | tar -xz
   cd My-Arch-Linux-Installer-main
   ```

3. Run the installer:

   ```bash
   chmod +x main.sh
   ./main.sh
   ```

- Allocate at least 32 GiB to `/`.
- The remaining space after EFI and swap becomes `/home`.
- Ctrl+C exits at a step prompt and is disabled while a step runs.
