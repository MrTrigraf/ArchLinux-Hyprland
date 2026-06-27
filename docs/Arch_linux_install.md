# Установка Arch Linux

> Полная пошаговая инструкция установки Arch Linux с разметкой на **btrfs** (subvolume `@` и `@home`), загрузчиком **systemd-boot** и поддержкой видеокарт NVIDIA / AMD / Intel.

![Russian](https://img.shields.io/badge/lang-Russian-1793d1) [![English](https://img.shields.io/badge/lang-English-lightgrey)](Arch_linux_install.en.md)

---

## 📋 Содержание

- [1. Подготовка](#1-подготовка)
- [2. Разметка диска](#2-разметка-диска)
- [3. Файловая система btrfs](#3-файловая-система-btrfs)
- [4. Установка базовой системы](#4-установка-базовой-системы)
- [5. Настройка внутри chroot](#5-настройка-внутри-chroot)
- [6. Загрузчик systemd-boot](#6-загрузчик-systemd-boot)
- [7. Создание пользователя](#7-создание-пользователя)

---

## 1. Подготовка

### 🕒 Синхронизация системного времени

```bash
timedatectl set-ntp true
```

### 💽 Определение дисков

```bash
lsblk
```

### 🧹 Очистка сигнатур и разделов диска

```bash
wipefs --all /dev/<ваш-диск>
```

---

## 2. Разметка диска

### Открываем редактор разделов

```bash
cfdisk /dev/<ваш-диск>
```

Выбираем тип таблицы — **GPT**. Создаём три раздела:

| № | Размер | Тип | Назначение |
|---|---|---|---|
| 1 | **1 GiB** | EFI System | Загрузчик |
| 2 | **≈ объём RAM** | Linux swap | Подкачка |
| 3 | **Всё остальное** | Linux filesystem | Корень + home |

> 💡 **Размер swap:** обычно ≤ объёма RAM. Для гибернации — ≥ RAM + ~10%.

### Форматируем разделы

```bash
mkfs.btrfs -f /dev/<раздел-с-Linux-filesystem>
mkfs.fat -F32 /dev/<EFI-System>
```

### Инициализируем раздел подкачки

```bash
mkswap /dev/<раздел-Linux-swap>
```

---

## 3. Файловая система btrfs

### Монтируем корневой раздел

```bash
mount /dev/<раздел-с-Linux-filesystem> /mnt
```

### Создаём subvolume

```bash
cd /mnt

# subvolume для системы
btrfs subvolume create ./@

# subvolume для пользователя
btrfs subvolume create ./@home

cd
```

### Размонтируем `/mnt`

```bash
umount /mnt -R
```

### Монтируем subvolume к системе

**Корень:**
```bash
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@ \
    /dev/<раздел-с-Linux-filesystem> /mnt
```

**Папка home:**
```bash
mkdir /mnt/home
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@home \
    /dev/<раздел-с-Linux-filesystem> /mnt/home
```

**Проверка:**
```bash
mount | grep /mnt
mount | grep /mnt/home
```

### Активируем раздел подкачки

> Это нужно, чтобы `genfstab` автоматически добавил swap в `/etc/fstab`.

```bash
swapon /dev/<раздел-Linux-swap>
swapon --show
```

### Монтируем EFI-раздел

```bash
mkdir /mnt/boot
mount /dev/<EFI-System> /mnt/boot/
```

---

## 4. Установка базовой системы

Команда `pacstrap` собирается из **трёх частей**:

```
pacstrap /mnt  <базовый набор>  <CPU-microcode>  <GPU-драйверы>
```

### 🧩 Базовый набор (общий для всех конфигураций)

```
base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty
```

### ⚙️ CPU-microcode

Выбираем **один** пакет по производителю CPU:

| CPU | Пакет |
|---|---|
| **Intel** | `intel-ucode` |
| **AMD** | `amd-ucode` |

### 🎮 GPU-драйверы

Выбираем **один** набор по производителю видеокарты:

<details>
<summary><b>🟢 NVIDIA</b> (Turing 16xx / RTX 20xx и новее — от 2018 года)</summary>

```
nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

- На ядре `linux-zen` нужен именно **DKMS**-вариант.
- `nvidia-open-dkms` (открытые модули) — **обязательны для RTX 50xx Blackwell**, рекомендуются для всего, что новее Turing.
- На старых картах **до Turing** — `nvidia-dkms` вместо `nvidia-open-dkms`.

</details>

<details>
<summary><b>🔴 AMD</b></summary>

```
mesa vulkan-radeon libva-mesa-driver
```

- Драйвер `amdgpu` входит в ядро — отдельный пакет не нужен.
- `mesa` — OpenGL.
- `vulkan-radeon` — Vulkan.
- `libva-mesa-driver` — аппаратное декодирование видео через VA-API.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (Broadwell+, Gen 8+ — все iGPU примерно с 2014 года)</summary>

```
mesa vulkan-intel intel-media-driver
```

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (старше Broadwell)</summary>

```
mesa vulkan-intel libva-intel-driver
```

</details>

### 🚀 Готовые команды под типовые конфигурации

<details>
<summary><b>Intel CPU + NVIDIA GPU</b> (RTX 20xx и новее)</summary>

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

### Генерируем fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

### Метка системного диска

```bash
btrfs filesystem label /mnt "ArchLinux"
blkid   # проверка
```

### Входим в систему

```bash
arch-chroot /mnt
```

---

## 5. Настройка внутри chroot

### 🕰️ Локальное время

```bash
ln -sf /usr/share/zoneinfo/<Страна>/<Город> /etc/localtime
hwclock --systohc
```

### 🌍 Локали системы

Открываем файл и **раскомментируем** нужные локали:

```bash
sudo vim /etc/locale.gen
```

В моём случае:

- `en_US.UTF-8 UTF-8`
- `ru_RU.UTF-8 UTF-8`

Устанавливаем язык системы:

```bash
sudo vim /etc/locale.conf
```

Добавляем строку:

```
LANG=ru_RU.UTF-8
```

Генерируем локали:

```bash
locale-gen
```

### ⌨️ Русский язык в терминале (tty)

```bash
sudo vim /etc/vconsole.conf
```

```
KEYMAP=ru
FONT=cyr-sun16
```

### 🌐 Настройка сети

**Имя ПК:**

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

### 🔑 Пароль root

```bash
passwd
```

(вводим пароль два раза)

### 📡 Включаем NetworkManager

```bash
systemctl enable NetworkManager
systemctl mask NetworkManager-wait-online
```

---

## 6. Загрузчик systemd-boot

### Установка

```bash
bootctl install
```

### Основной конфиг

```bash
sudo vim /boot/loader/loader.conf
```

```
default linux-zen.conf
timeout 0
console-mode auto
editor no
```

### Запись о ядре

```bash
sudo vim /boot/loader/entries/linux-zen.conf
```

**Шаблон:**

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /<microcode>.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs <GPU-параметры>
```

### CPU-microcode (строка `initrd`)

| CPU | `initrd` |
|---|---|
| **Intel** | `initrd  /intel-ucode.img` |
| **AMD** | `initrd  /amd-ucode.img` |

### GPU-параметры (строка `options`)

| GPU | Параметр |
|---|---|
| **NVIDIA** | `nvidia-drm.modeset=1` — **обязательно** для Wayland-сессий (без него Hyprland/Sway не стартуют) |
| **AMD** | — (драйвер `amdgpu` грузится автоматически) |
| **Intel** | — (драйвер `i915` грузится автоматически) |

> 💡 На драйвере NVIDIA 545+ можно дополнительно добавить `nvidia-drm.fbdev=1` для нативного KMS-фреймбуфера.

### Готовые конфиги под типовые конфигурации

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

## 7. Создание пользователя

Выходим из chroot и перезагружаемся:

```bash
# выход из chroot — Ctrl+D
reboot
```

После перезагрузки **логинимся под `root`** и создаём пользователя:

```bash
useradd -m <имя_пользователя>
passwd <имя_пользователя>
usermod -aG wheel,audio,video,optical,storage <имя_пользователя>
userdbctl groups-of-user <имя_пользователя>
```

### Устанавливаем sudo

```bash
pacman -S sudo
visudo
```

**Раскомментируем строку:**

```
%wheel ALL=(ALL:ALL) ALL
```

---

## ✅ Готово

Делаем перезагрузку системы и заходим под созданным пользователем.

> 🎉 **Поздравляю — система установлена!**
