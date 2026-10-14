# Arch Linux Installation

> Complete step-by-step Arch Linux installation guide with **btrfs** partitioning (subvolumes `@` and `@home`), **systemd-boot** loader, and support for NVIDIA / AMD / Intel graphics.

[![Russian](https://img.shields.io/badge/lang-Russian-lightgrey)](Arch_linux_install.md) ![English](https://img.shields.io/badge/lang-English-1793d1)

---

## 📋 Table of Contents

- [1. Preparation](#1-preparation)
- [2. Disk Partitioning](#2-disk-partitioning)
- [3. The btrfs Filesystem (ssd)](#3-the-btrfs-filesystem-ssd)
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

### 🔍 Verify UEFI boot mode

```bash
cat /sys/firmware/efi/fw_platform_size
```

> 💡 `64` — x64 UEFI, all good. `32` — 32-bit UEFI (IA32): supported, but the choice of boot loaders is limited. `No such file or directory` — the live image was booted in BIOS/CSM mode: reboot and pick the UEFI entry for the USB drive in the boot menu.

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

> ⚠️ This command **irreversibly** wipes the partition layout of the whole disk. Double-check the disk name against the `lsblk` output.

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

## 3. The btrfs Filesystem (ssd)

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
base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git
```

> 💡 `linux-firmware` is a meta package: it pulls in the default set of firmware (`linux-firmware-amdgpu`, `-intel`, `-nvidia`, `-realtek`, etc.). You can list only the `linux-firmware-*` packages you need, but for a first install keeping the meta package is the safer choice.

### ⚙️ CPU-microcode

Choose **one** package by CPU vendor:

| CPU | Package |
|---|---|
| **Intel** | `intel-ucode` |
| **AMD** | `amd-ucode` |

### 🎮 GPU drivers

Choose the set by graphics card vendor (on a hybrid laptop — two sets, see below):

<details>
<summary><b>🟢 NVIDIA</b> (Turing 16xx / RTX 20xx and newer — from 2018)</summary>

```
nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

- On the `linux-zen` kernel, the **DKMS** variant is required (`nvidia-open` is built only for the stock `linux` kernel).
- `nvidia-open-dkms` (open modules) — the "for any kernel(s)" variant from the official repositories. Suitable for all cards from Turing up to RTX 50xx Blackwell.
- `nvidia-utils` is also pulled in as a dependency; listing it explicitly does no harm.
- `libva-nvidia-driver` — a VA-API layer on top of NVDEC (needed by browsers, for example). According to the wiki, with default settings it may consume **more power** than CPU decoding. Workaround for driver 580.105.08 and newer: the `CUDA_DISABLE_PERF_BOOST=1` environment variable.
- Ampere laptop with boot problems: the wiki describes GSP firmware failures on some of these laptops — in that case use the proprietary `nvidia-580xx-dkms` (AUR) with the `NVreg_EnableGpuFirmware=0` module parameter.

</details>

<details>
<summary><b>🟢 NVIDIA</b> (pre-Turing: Maxwell / Pascal / Volta)</summary>

Identify your card's family like this (and match it against the nouveau code names table linked from the NVIDIA wiki page):

```bash
lspci -k -d ::03xx
```

Since the 590 branch, Pascal (GTX 10xx) and older are not supported by the main packages: `nvidia-dkms` has been replaced by `nvidia-open-dkms`. Maxwell / Pascal / Volta need the legacy **`nvidia-580xx-dkms`** driver from the **AUR** (wiki status: *Legacy, supported*). AUR packages **cannot be installed** via `pacstrap`.

At the `pacstrap` stage, instead of the NVIDIA drivers specify:

```
mesa
```

The system will boot on the open-source `nouveau` driver. After installing an AUR helper:

```bash
yay -S nvidia-580xx-dkms
```

- Kepler — `nvidia-470xx-dkms` from the AUR, status *Legacy, unsupported*: NVIDIA no longer supports this branch, and the wiki notes it may be easier to stay on `nouveau`.

</details>

<details>
<summary><b>🔴 AMD</b></summary>

```
mesa vulkan-radeon
```

- The `amdgpu` driver is included in the kernel — no separate package needed.
- `mesa` — OpenGL + hardware video decoding via VA-API (a separate `libva-mesa-driver` is no longer needed).
- VDPAU was removed from the mesa drivers starting with version 25.3.0 — players and browsers use VA-API.
- `vulkan-radeon` — Vulkan.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (Broadwell+, Gen 8+ — all iGPUs roughly since 2014)</summary>

```
mesa vulkan-intel intel-media-driver
```

- `intel-media-driver` — hardware video decoding/encoding via VA-API.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (older than Broadwell)</summary>

```
mesa vulkan-intel libva-intel-driver
```

- Full Vulkan support in `vulkan-intel` starts with Broadwell; on older chips support is incomplete or missing, so the package can be skipped.

</details>

> 💡 **Hybrid laptop** (Intel/AMD iGPU + discrete NVIDIA) — install **both** sets: iGPU drivers + NVIDIA drivers. Details — the "NVIDIA Optimus" wiki article.

### 🚀 Ready-to-use commands for typical configurations

<details>
<summary><b>Intel CPU + NVIDIA GPU</b> (GTX 16xx / RTX 20xx and newer)</summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git intel-ucode nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

</details>

<details>
<summary><b>AMD CPU + AMD GPU</b></summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git amd-ucode mesa vulkan-radeon
```

</details>

<details>
<summary><b>Intel CPU + Intel iGPU</b> (Broadwell+)</summary>

```bash
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git intel-ucode mesa vulkan-intel intel-media-driver
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

> 💡 The **`-S`** flag (systemd mode) is the standard way to enter chroot for installing systemd-boot. Without it, `bootctl install` at [step 6](#6-systemd-boot-bootloader) copies the files but **does not create the EFI entry** in NVRAM (outputs `Not booted with EFI or running in a container, skipping EFI variable modifications`): in its regular mode `arch-chroot` runs in a separate PID namespace, and `bootctl` deliberately leaves EFI variables alone. This is how systemd behaves, not a temporary bug.
>
> ✅ `arch-chroot -S /mnt` is exactly what the official Installation guide now uses.
>
> ⚠️ If `arch-chroot` responds with `invalid option` — the image is outdated, download a fresh ISO.

---

## 5. Configuration Inside chroot

> 💡 Inside chroot you are already root — `sudo` is not needed (and not installed yet; it is installed at [step 7](#7-user-creation)).

### 🕰️ Local time

```bash
ln -sf /usr/share/zoneinfo/<Region>/<City> /etc/localtime
hwclock --systohc
```

### 🌍 System locales

Open the file and **uncomment** the required locales:

```bash
vim /etc/locale.gen
```

In my case:

- `en_US.UTF-8 UTF-8`
- `ru_RU.UTF-8 UTF-8`

Set the system language:

```bash
vim /etc/locale.conf
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
vim /etc/vconsole.conf
```

```
KEYMAP=ru
FONT=cyr-sun16
```

### 🌐 Network setup

**Hostname:**

```bash
vim /etc/hostname
```

```
archlinux
```

**hosts:**

```bash
vim /etc/hosts
```

```
127.0.0.1  localhost
::1        localhost
127.0.1.1  archlinux
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

### 🔄 Rebuild the initramfs

```bash
mkinitcpio -P
```

> 💡 The initramfs was built during `pacstrap`, when `/etc/vconsole.conf` did not exist yet. The Installation guide states it directly: if you changed the console keymap, the initramfs must be recreated.
>
> ✅ Microcode: the output should contain the line `-> Early uncompressed CPIO image generation successful`. To check that it made it into the image:
>
> ```bash
> lsinitcpio --early /boot/initramfs-linux-zen.img | grep microcode
> ```
>
> You should see `kernel/x86/microcode/` and `GenuineIntel.bin` or `AuthenticAMD.bin` (see [step 6](#6-systemd-boot-bootloader)).

---

## 6. systemd-boot Bootloader

### Installation

```bash
bootctl install
```

> 💡 The command works only if you entered chroot via `arch-chroot -S /mnt` at [step 4](#4-base-system-installation). With regular `arch-chroot /mnt`, `bootctl` outputs `Not booted with EFI` and won't write the boot entry.
>
> ✅ Check: the output should show the created UEFI entry **"Linux Boot Manager"**. After setting up the configs below, run `bootctl` without arguments — it shows whether systemd-boot can parse them, and `bootctl list` prints the boot entries.
>
> 🛠️ If the entry still wasn't created — the wiki describes creating it manually with `efibootmgr` (the package is installed separately).

### Main config

```bash
vim /boot/loader/loader.conf
```

```
default linux-zen.conf
timeout 0
console-mode auto
editor no
```

> 💡 With `timeout 0` the menu is not shown and the default entry boots immediately. If you want the menu — set e.g. `timeout 3` (in the menu, `t` / `T` change the timeout, `e` edits the parameters, `h` shows help).

### Kernel entry

```bash
vim /boot/loader/entries/linux-zen.conf
```

**Template:**

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs <GPU-parameters>
```

### CPU-microcode (`initrd` line)

A separate `initrd /intel-ucode.img` / `initrd /amd-ucode.img` line is **no longer needed**: the mkinitcpio `microcode` hook embeds the microcode directly into `initramfs-linux-zen.img`.

- The `intel-ucode` / `amd-ucode` package from [step 4](#4-base-system-installation) is still **required** — the hook takes the microcode from it.
- Make sure the `HOOKS` line in `/etc/mkinitcpio.conf` contains `microcode` after `autodetect` (the default config already has it).

### GPU parameters (`options` line)

| GPU | Parameter |
|---|---|
| **NVIDIA** (`nvidia-open-dkms`) | — (`nvidia-drm.modeset=1` and `nvidia-drm.fbdev=1` are enabled by default in `nvidia-utils`) |
| **NVIDIA** (legacy `nvidia-580xx-dkms` from the AUR) | `nvidia-drm.modeset=1` — just in case: it is enabled by default by the `nvidia-utils` package, which is not guaranteed for the AUR package; Wayland does not work without modeset |
| **AMD** | — (the `amdgpu` driver loads automatically) |
| **Intel** | — (the `i915` / `xe` driver loads automatically) |

> 💡 Check after booting (both commands should print `Y`):
>
> ```bash
> cat /sys/module/nvidia_drm/parameters/modeset
> cat /sys/module/nvidia_drm/parameters/fbdev
> ```
>
> If `fbdev` prints `N` — also add `nvidia-drm.fbdev=1` to `options`.

### Ready-to-use configs for typical configurations

For **Intel CPU + NVIDIA GPU**, **AMD CPU + AMD GPU** and **Intel CPU + Intel iGPU** the entry is now the same:

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs
```

> 💡 For legacy NVIDIA (`nvidia-580xx-dkms`) append the `nvidia-drm.modeset=1` parameter to the end of the `options` line.

---

## 7. User Creation

Exit chroot, unmount the partitions and reboot:

```bash
exit            # or Ctrl+D — exit chroot
umount -R /mnt
reboot
```

> 💡 `umount -R /mnt` is optional but recommended by the Installation guide: this way you notice if any partition is still busy.

After reboot, **log in as `root`** and create a user:

```bash
useradd -m <username>
passwd <username>
usermod -aG wheel <username>
userdbctl groups-of-user <username>
```

> 💡 The `wheel` group is enough (for `sudo`; also, polkit treats members of `wheel` as administrators by default). The `audio`, `video`, `optical`, `storage` groups are listed in the wiki as "Pre-systemd groups": nowadays udev marks devices with the `uaccess` tag, and `logind` grants permissions to the active session via ACLs. Adding users to them can even break things: the `audio` group breaks fast user switching and allows applications to block software mixing.
>
> Exceptions where a group is still needed:
> - `audio` — ALSA/OSS in remote sessions;
> - `storage` — working with some devices via `udisksctl`;
> - `video` — some brightness utilities (e.g. `light`) require membership in `video`.

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
