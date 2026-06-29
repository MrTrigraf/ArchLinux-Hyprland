# Arch Linux Installation

> Complete step-by-step Arch Linux installation guide with **btrfs** partitioning (subvolumes `@` and `@home`), **systemd-boot** loader, and support for NVIDIA / AMD / Intel graphics.

[![Russian](https://img.shields.io/badge/lang-Russian-lightgrey)](Arch_linux_install.md) ![English](https://img.shields.io/badge/lang-English-1793d1)

---

## 📋 Table of Contents

- [1. Preparation](#1-preparation)
- [2. Disk Partitioning](#2-disk-partitioning)
- [3. The btrfs Filesystem](#3-the-btrfs-filesystem)
- [4. Base System Installation](#4-base-system-installation)
- [5. Configuration Inside chroot](#5-configuration-inside-chroot)
- [6. systemd-boot Bootloader](#6-systemd-boot-bootloader)
- [7. User Creation](#7-user-creation)
- [8. Wi-Fi Connection After Installation](#8-wi-fi-connection-after-installation)

---

## 1. Preparation

<details>
<summary><b>📶 Wi-Fi connection (optional)</b></summary>

If your laptop connects via Ethernet — skip this block. For Wi-Fi we use the built-in `iwctl` utility.

### Launch

```bash
iwctl
```

An interactive shell with the `[iwd]#` prompt will start.

### Find wireless interface name

```
[iwd]# device list
```

Remember the device name (usually `wlan0`).

### If the adapter is off

```
[iwd]# device <device> set-property Powered on
[iwd]# adapter <adapter> set-property Powered on
```

### Scan networks

```
[iwd]# station <device> scan
[iwd]# station <device> get-networks
```

### Connect

```
[iwd]# station <device> connect <SSID>
```

It will ask for the password — enter it and press Enter.

### Exit

`Ctrl+C` — return to the standard shell.

### Verify

```bash
ping -c 3 archlinux.org
```

</details>

### 🕒 System time synchronization

```bash
timedatectl set-ntp true
```

### 💽 Disk identification

```bash
lsblk
```

### 🧹 Clear disk signatures and partitions

```bash
wipefs --all /dev/<your-disk>
```

---

## 2. Disk Partitioning

### Open the partition editor

```bash
cfdisk /dev/<your-disk>
```

Choose table type — **GPT**. Create three partitions:

| # | Size | Type | Purpose |
|---|---|---|---|
| 1 | **1 GiB** | EFI System | Bootloader |
| 2 | **≈ RAM size** | Linux swap | Swap |
| 3 | **All remaining** | Linux filesystem | Root + home |

> 💡 **Swap size:** usually ≤ RAM size. For hibernation — ≥ RAM + ~10%.

### Format the partitions

```bash
mkfs.btrfs -f /dev/<linux-filesystem-partition>
mkfs.fat -F32 /dev/<EFI-System-partition>
```

### Initialize the swap partition

```bash
mkswap /dev/<linux-swap-partition>
```

---

## 3. The btrfs Filesystem

### Mount the root partition

```bash
mount /dev/<linux-filesystem-partition> /mnt
```

### Create subvolumes

```bash
cd /mnt

# subvolume for the system
btrfs subvolume create ./@

# subvolume for the user
btrfs subvolume create ./@home

cd
```

### Unmount `/mnt`

```bash
umount /mnt -R
```

### Mount subvolumes to the system

**Root:**
```bash
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@ \
    /dev/<linux-filesystem-partition> /mnt
```

**home folder:**
```bash
mkdir /mnt/home
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@home \
    /dev/<linux-filesystem-partition> /mnt/home
```

**Verify:**
```bash
mount | grep /mnt
mount | grep /mnt/home
```

### Activate the swap partition

> Needed so that `genfstab` automatically adds swap to `/etc/fstab`.

```bash
swapon /dev/<linux-swap-partition>
swapon --show
```

### Mount the EFI partition

```bash
mkdir /mnt/boot
mount /dev/<EFI-System-partition> /mnt/boot
```

---

## 4. Base System Installation

The `pacstrap` command consists of **three parts**:

```
pacstrap /mnt  <base set>  <CPU-microcode>  <GPU drivers>
```

### 🧩 Base set (common for all configurations)

```
base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty
```

### ⚙️ CPU-microcode

Choose **one** package by CPU vendor:

| CPU | Package |
|---|---|
| **Intel** | `intel-ucode` |
| **AMD** | `amd-ucode` |

### 🎮 GPU drivers

Choose **one** set by graphics card vendor:

<details>
<summary><b>🟢 NVIDIA</b> (Turing 16xx / RTX 20xx and newer — from 2018)</summary>

```
nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

- On the `linux-zen` kernel, the **DKMS** variant is required.
- `nvidia-open-dkms` (open modules) — **required for RTX 50xx Blackwell**, recommended for anything newer than Turing.
- On older cards **before Turing** — `nvidia-dkms` instead of `nvidia-open-dkms`.

</details>

<details>
<summary><b>🔴 AMD</b></summary>

```
mesa vulkan-radeon libva-mesa-driver
```

- The `amdgpu` driver is included in the kernel — no separate package needed.
- `mesa` — OpenGL.
- `vulkan-radeon` — Vulkan.
- `libva-mesa-driver` — hardware video decoding via VA-API.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (Broadwell+, Gen 8+ — all iGPUs roughly since 2014)</summary>

```
mesa vulkan-intel intel-media-driver
```

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (older than Broadwell)</summary>

```
mesa vulkan-intel libva-intel-driver
```

</details>

### 🚀 Ready-to-use commands for typical configurations

<details>
<summary><b>Intel CPU + NVIDIA GPU</b> (RTX 20xx and newer)</summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty intel-ucode nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

</details>

<details>
<summary><b>AMD CPU + AMD GPU</b></summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty amd-ucode mesa vulkan-radeon libva-mesa-driver
```

</details>

<details>
<summary><b>Intel CPU + Intel iGPU</b> (Broadwell+)</summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty intel-ucode mesa vulkan-intel intel-media-driver
```

</details>

### Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### Label the system disk

```bash
btrfs filesystem label /mnt "ArchLinux"
blkid   # verify
```

### Enter the system

```bash
arch-chroot -S /mnt
```

> 💡 The **`-S`** flag (systemd mode) — required since late 2025. Without it, `bootctl install` at [step 6](#6-systemd-boot-bootloader) won't write the EFI entry to NVRAM due to a systemd regression (outputs `Not booted with EFI`). With `-S` everything works.

---

## 5. Configuration Inside chroot

### 🕰️ Local time

```bash
ln -sf /usr/share/zoneinfo/<Region>/<City> /etc/localtime
hwclock --systohc
```

### 🌍 System locales

Open the file and **uncomment** the required locales:

```bash
sudo vim /etc/locale.gen
```

In my case:

- `en_US.UTF-8 UTF-8`
- `ru_RU.UTF-8 UTF-8`

Set the system language:

```bash
sudo vim /etc/locale.conf
```

Add the line:

```
LANG=ru_RU.UTF-8
```

Generate locales:

```bash
locale-gen
```

### ⌨️ Russian language in the terminal (tty)

```bash
sudo vim /etc/vconsole.conf
```

```
KEYMAP=ru
FONT=cyr-sun16
```

### 🌐 Network setup

**Hostname:**

```bash
sudo vim /etc/hostname
```

```
ArchLinux
```

**hosts:**

```bash
sudo vim /etc/hosts
```

```
127.0.0.1  localhost
::1        localhost
127.0.1.1  ArchLinux
```

### 🔑 root password

```bash
passwd
```

(enter the password twice)

### 📡 Enable NetworkManager

```bash
systemctl enable NetworkManager
systemctl mask NetworkManager-wait-online
```

---

## 6. systemd-boot Bootloader

### Installation

```bash
bootctl install
```

> 💡 The command works only if you entered chroot via `arch-chroot -S /mnt` at [step 4](#4-base-system-installation). With regular `arch-chroot /mnt`, `bootctl` outputs `Not booted with EFI` and won't write the boot entry.

### Main config

```bash
sudo vim /boot/loader/loader.conf
```

```
default linux-zen.conf
timeout 0
console-mode auto
editor no
```

### Kernel entry

```bash
sudo vim /boot/loader/entries/linux-zen.conf
```

**Template:**

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /<microcode>.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs <GPU-parameters>
```

### CPU-microcode (`initrd` line)

| CPU | `initrd` |
|---|---|
| **Intel** | `initrd  /intel-ucode.img` |
| **AMD** | `initrd  /amd-ucode.img` |

### GPU parameters (`options` line)

| GPU | Parameter |
|---|---|
| **NVIDIA** | `nvidia-drm.modeset=1` — **required** for Wayland sessions (without it Hyprland/Sway won't start) |
| **AMD** | — (the `amdgpu` driver loads automatically) |
| **Intel** | — (the `i915` driver loads automatically) |

> 💡 On NVIDIA driver 545+, you can additionally add `nvidia-drm.fbdev=1` for native KMS framebuffer.

### Ready-to-use configs for typical configurations

<details>
<summary><b>Intel CPU + NVIDIA GPU</b></summary>

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs nvidia-drm.modeset=1
```

</details>

<details>
<summary><b>AMD CPU + AMD GPU</b></summary>

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /amd-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs
```

</details>

<details>
<summary><b>Intel CPU + Intel iGPU</b></summary>

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs
```

</details>

---

## 7. User Creation

Exit chroot and reboot:

```bash
# exit chroot — Ctrl+D
reboot
```

After reboot, **log in as `root`** and create a user:

```bash
useradd -m <username>
passwd <username>
usermod -aG wheel,audio,video,optical,storage <username>
userdbctl groups-of-user <username>
```

### Install sudo

```bash
pacman -S sudo
EDITOR=vim visudo
```

> 💡 The **`EDITOR=vim`** variable is required: the `base` package doesn't include `vi`, only `vim` (installed via pacstrap). Without specifying the variable, `visudo` looks for `/usr/bin/vi` and fails with `editor not found`.

**Uncomment the line:**

```
%wheel ALL=(ALL:ALL) ALL
```

---

## 8. Wi-Fi Connection After Installation

If your laptop connects via Ethernet — skip this section. After installation, Wi-Fi is configured through **NetworkManager** (already enabled by us at [step 5](#-enable-networkmanager)).

### 🚀 Quick way — `nmcli`

Enable Wi-Fi (if off):

```bash
nmcli radio wifi on
```

List available networks:

```bash
nmcli device wifi list
```

Connect:

```bash
nmcli device wifi connect "<SSID>" password "<password>"
```

> 💡 Quotes are required if the network name or password contains spaces / special characters.

Test internet:

```bash
ping -c 3 archlinux.org
```

### 🖥️ Convenient way — `nmtui` (text menu)

```bash
nmtui
```

In the menu:

1. **Activate a connection** → Enter
2. Use arrows to select your network → Enter
3. Enter password → OK
4. **Back** → **Quit**

### 🛠️ Useful commands

**Show current connection:**

```bash
nmcli connection show --active
```

**Disconnect:**

```bash
nmcli device disconnect wlan0
```

**Delete saved connection:**

```bash
nmcli connection delete "<SSID>"
```

**If Wi-Fi card is not visible:**

```bash
nmcli device status
```

> 💡 There should be a line like `wlan0  wifi  ...`. If it's missing — firmware is absent. Check that `linux-firmware` was in pacstrap.

NetworkManager automatically saves the connection — on subsequent boots, Wi-Fi will connect on its own.

---

## ✅ Done

Reboot the system and log in as the created user.

> 🎉 **Congratulations — the system is installed!**
