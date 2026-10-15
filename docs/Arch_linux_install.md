# Установка Arch Linux

> Полная пошаговая инструкция установки Arch Linux с разметкой на **btrfs** (subvolume `@` и `@home`), загрузчиком **systemd-boot** и поддержкой видеокарт NVIDIA / AMD / Intel.

![Russian](https://img.shields.io/badge/lang-Russian-1793d1) [![English](https://img.shields.io/badge/lang-English-lightgrey)](Arch_linux_install.en.md)

---
## 📋 Содержание

- [1. Подготовка](#1-подготовка)
- [2. Разметка диска](#2-разметка-диска)
- [3. Файловая система btrfs (ssd)](#3-файловая-система-btrfs-ssd)
- [4. Установка базовой системы](#4-установка-базовой-системы)
- [5. Настройка внутри chroot](#5-настройка-внутри-chroot)
- [6. Загрузчик systemd-boot](#6-загрузчик-systemd-boot)
- [7. Создание пользователя](#7-создание-пользователя)
- [8. Подключение к Wi-Fi после установки](#8-подключение-к-wi-fi-после-установки)
---
## 1. Подготовка

<details>
<summary><b>📶 Подключение к Wi-Fi (опционально)</b></summary>

Если ноутбук подключается по Ethernet — пропускай этот блок. Для Wi-Fi используем встроенную утилиту `iwctl`.

### Запуск

```bash
iwctl
```

Запустится интерактивная оболочка с приглашением `[iwd]#`.

### Узнать имя беспроводного интерфейса

```
[iwd]# device list
```

Запомни имя устройства (обычно `wlan0`).

### Если адаптер выключен

```
[iwd]# device <устройство> set-property Powered on
[iwd]# adapter <адаптер> set-property Powered on
```

### Сканирование сетей

```
[iwd]# station <устройство> scan
[iwd]# station <устройство> get-networks
```

### Подключение

```
[iwd]# station <устройство> connect <SSID>
```

Запросит пароль — введи и нажми Enter.

### Выход

`Ctrl+C` — возврат к стандартному shell.

### Проверка

```bash
ping -c 3 archlinux.org
```

</details>

### 🔍 Проверка режима загрузки UEFI

```bash
cat /sys/firmware/efi/fw_platform_size
```

> 💡 `64` — UEFI x64, всё в порядке. `32` — 32-битный UEFI (IA32): поддерживается, но выбор загрузчиков ограничен. `No such file or directory` — live-образ загружен в режиме BIOS/CSM: перезагрузись и выбери UEFI-вариант флешки в меню загрузки.

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

> ⚠️ Команда **безвозвратно** стирает разметку всего диска. Дважды проверь имя диска по выводу `lsblk`.

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

## 3. Файловая система btrfs (ssd)

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
mount /dev/<EFI-System> /mnt/boot
```

---

## 4. Установка базовой системы

Команда `pacstrap` собирается из **трёх частей**:

```
pacstrap -K /mnt  <базовый набор>  <CPU-microcode>  <GPU-драйверы>
```

### 🧩 Базовый набор (общий для всех конфигураций)

```
base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git
```

> 💡 `linux-firmware` — метапакет: он тянет набор прошивок по умолчанию (`linux-firmware-amdgpu`, `-intel`, `-nvidia`, `-realtek` и др.). Можно указать только нужные `linux-firmware-*`, но для первой установки надёжнее оставить метапакет.

### ⚙️ CPU-microcode

Выбираем **один** пакет по производителю CPU:

| CPU | Пакет |
|---|---|
| **Intel** | `intel-ucode` |
| **AMD** | `amd-ucode` |

### 🎮 GPU-драйверы

Выбираем набор по производителю видеокарты (на гибридном ноутбуке — два, см. ниже):

<details>
<summary><b>🟢 NVIDIA</b> (Turing 16xx / RTX 20xx и новее — от 2018 года)</summary>

```
nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

- На ядре `linux-zen` нужен именно **DKMS**-вариант (`nvidia-open` собран только под стандартное ядро `linux`).
- `nvidia-open-dkms` (открытые модули) — вариант «for any kernel(s)» из официальных репозиториев. Подходит для всех карт от Turing до RTX 50xx Blackwell.
- `nvidia-utils` подтянется и как зависимость, явное указание не мешает.
- `libva-nvidia-driver` — прослойка VA-API поверх NVDEC (нужна, например, браузерам). По вики, с настройками по умолчанию она может потреблять **больше энергии**, чем декодирование на CPU. Обходной путь для драйвера 580.105.08 и новее — переменная окружения `CUDA_DISABLE_PERF_BOOST=1`.
- GSP-прошивка: по вики, она вызывает проблемы — от неоптимального энергопотребления на Turing до полного отказа на некоторых ноутбуках с Ampere. Если это твой случай — проприетарный `nvidia-580xx-dkms` (AUR) с параметром модуля `NVreg_EnableGpuFirmware=0` ([вики NVIDIA](https://wiki.archlinux.org/title/NVIDIA#Installation)).

</details>

<details>
<summary><b>🟢 NVIDIA</b> (до Turing: Maxwell / Pascal / Volta)</summary>

Семейство карты определяем так (и сверяем с таблицей кодовых имён nouveau, ссылка есть в вики NVIDIA):

```bash
lspci -k -d ::03xx
```

С ветки 590 Pascal (GTX 10xx) и старше не поддерживаются основными пакетами: `nvidia-dkms` заменён на `nvidia-open-dkms`. Для Maxwell / Pascal / Volta нужен legacy-драйвер **`nvidia-580xx-dkms`** из **AUR** (статус в вики — *Legacy, supported*). Пакеты из AUR через `pacstrap` **не ставятся**.

На этапе `pacstrap` вместо драйверов NVIDIA указываем:

```
mesa
```

Система загрузится на открытом драйвере `nouveau`. После установки AUR-хелпера:

```bash
yay -S nvidia-580xx-dkms
```

- Kepler — `nvidia-470xx-dkms` из AUR, статус *Legacy, unsupported*: NVIDIA эту ветку больше не поддерживает, и вики допускает, что проще остаться на `nouveau`.

</details>

<details>
<summary><b>🔴 AMD</b></summary>

```
mesa vulkan-radeon
```

- Драйвер `amdgpu` входит в ядро — отдельный пакет не нужен.
- `mesa` — OpenGL + аппаратное декодирование видео через VA-API (отдельный `libva-mesa-driver` больше не нужен).
- VDPAU удалён из драйверов mesa начиная с версии 25.3.0 — плееры и браузеры используют VA-API.
- `vulkan-radeon` — Vulkan.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (Broadwell+, Gen 8+ — все iGPU примерно с 2014 года)</summary>

```
mesa vulkan-intel intel-media-driver
```

- `intel-media-driver` — аппаратное декодирование/кодирование видео через VA-API.

</details>

<details>
<summary><b>🔵 Intel iGPU</b> (старше Broadwell)</summary>

```
mesa vulkan-intel libva-intel-driver
```

- Полноценный Vulkan в `vulkan-intel` — с Broadwell; на более старых чипах поддержка неполная или отсутствует, так что пакет можно не ставить.

</details>

> 💡 **Гибридный ноутбук** (iGPU Intel/AMD + дискретная NVIDIA) — ставим **оба** набора: драйверы iGPU + драйверы NVIDIA. Подробности — статья вики «NVIDIA Optimus».

### 🚀 Готовые команды под типовые конфигурации

<details>
<summary><b>Intel CPU + NVIDIA GPU</b> (GTX 16xx / RTX 20xx и новее)</summary>

```bash
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git intel-ucode nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
```

</details>

<details>
<summary><b>AMD CPU + AMD GPU</b></summary>

```bash
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git amd-ucode mesa vulkan-radeon
```

</details>

<details>
<summary><b>Intel CPU + Intel iGPU</b> (Broadwell+)</summary>

```bash
pacstrap -K /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty git intel-ucode mesa vulkan-intel intel-media-driver
```

</details>

### Генерируем fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Проверяем результат и при ошибках исправляем ([Installation guide](https://wiki.archlinux.org/title/Installation_guide#Fstab)):

```bash
cat /mnt/etc/fstab
```

> 💡 Должны быть строки для `/` (`subvol=/@`), `/home` (`subvol=/@home`), `/boot` и `swap`.

### Метка системного диска

```bash
btrfs filesystem label /mnt "ArchLinux"
blkid   # проверка
```

### Входим в систему

```bash
arch-chroot -S /mnt
```

> 💡 Флаг **`-S`** (systemd mode) — штатный способ входа в chroot для установки systemd-boot. Без него `bootctl install` на [шаге 6](#6-загрузчик-systemd-boot) скопирует файлы, но **не создаст EFI-запись** в NVRAM (выводит `Not booted with EFI or running in a container, skipping EFI variable modifications`): в обычном режиме `arch-chroot` работает в отдельном PID namespace, и `bootctl` намеренно не трогает EFI-переменные. Это поведение systemd, а не временный баг.
>
> ✅ Именно `arch-chroot -S /mnt` сейчас указан в официальном Installation guide.
>
> ⚠️ Если `arch-chroot` отвечает `invalid option` — образ устарел, скачай свежий ISO.

---

## 5. Настройка внутри chroot

> 💡 Внутри chroot ты уже root — `sudo` не нужен (и пока не установлен, он ставится на [шаге 7](#7-создание-пользователя)).

### 🕰️ Локальное время

```bash
ln -sf /usr/share/zoneinfo/<Страна>/<Город> /etc/localtime
hwclock --systohc
```

### 🌍 Локали системы

Открываем файл и **раскомментируем** нужные локали:

```bash
vim /etc/locale.gen
```

В моём случае:

- `en_US.UTF-8 UTF-8`
- `ru_RU.UTF-8 UTF-8`

Устанавливаем язык системы:

```bash
vim /etc/locale.conf
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
vim /etc/vconsole.conf
```

```
KEYMAP=ru
FONT=cyr-sun16
```

### 🌐 Настройка сети

**Имя ПК:**

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

### 🟢 Только NVIDIA (`nvidia-open-dkms`): убрать `kms` из `HOOKS` (опционально)

```bash
vim /etc/mkinitcpio.conf
```

В строке `HOOKS=(...)` удаляем слово `kms`. Пересборка — следующей командой `mkinitcpio -P`.

> 💡 Шаг необязательный: `nvidia-utils` и так блокирует `nouveau`. Без хука `kms` модуль `nouveau` не попадёт в initramfs, и ядро гарантированно не загрузит его на раннем этапе ([вики NVIDIA](https://wiki.archlinux.org/title/NVIDIA#Installation)).
>
> ⚠️ Для legacy `nvidia-580xx-dkms` этот шаг делаем **после** установки драйвера из AUR: до этого система работает на `nouveau`. После правки — `sudo mkinitcpio -P`.

### 🔄 Пересборка initramfs

```bash
mkinitcpio -P
```

> 💡 Initramfs был собран ещё во время `pacstrap`, когда `/etc/vconsole.conf` не существовало. Installation guide прямо говорит: если меняли раскладку консоли, initramfs нужно пересоздать.
>
> ✅ Микрокод: в выводе должна быть строка `-> Early uncompressed CPIO image generation successful`. Проверить, что он попал в образ:
>
> ```bash
> lsinitcpio --early /boot/initramfs-linux-zen.img | grep microcode
> ```
>
> Должны появиться `kernel/x86/microcode/` и `GenuineIntel.bin` или `AuthenticAMD.bin` (см. [шаг 6](#6-загрузчик-systemd-boot)).

---

## 6. Загрузчик systemd-boot

### Установка

```bash
bootctl install
```

> 💡 Команда сработает только если на [шаге 4](#4-установка-базовой-системы) ты зашёл в chroot через `arch-chroot -S /mnt`. В обычном `arch-chroot /mnt` bootctl выведет `Not booted with EFI` и не запишет загрузочную запись.
>
> ✅ Проверка: в выводе должна появиться созданная запись UEFI **«Linux Boot Manager»**. После настройки конфигов ниже запусти `bootctl` без аргументов — он покажет, сможет ли systemd-boot их разобрать, а `bootctl list` выведет записи загрузки.
>
> 🛠️ Если запись так и не создалась — вики описывает ручное создание через `efibootmgr` (пакет ставится отдельно).

### Основной конфиг

```bash
vim /boot/loader/loader.conf
```

```
default linux-zen.conf
timeout 0
console-mode auto
editor no
```

> 💡 С `timeout 0` меню не показывается и сразу грузится запись по умолчанию. Если меню нужно — поставь, например, `timeout 3` (в меню клавишами `t` / `T` таймаут можно менять, `e` — правка параметров, `h` — подсказка).

### Запись о ядре

```bash
vim /boot/loader/entries/linux-zen.conf
```

Шаблон:

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs <GPU-параметры>
```

### CPU-microcode (строка initrd)

Отдельная строка `initrd /intel-ucode.img` / `initrd /amd-ucode.img` **больше не нужна**: хук `microcode` в mkinitcpio встраивает микрокод прямо в `initramfs-linux-zen.img`.

- Пакет `intel-ucode` / `amd-ucode` из [шага 4](#4-установка-базовой-системы) всё равно **нужен** — хук берёт микрокод из него.
- Проверь, что в `/etc/mkinitcpio.conf` в строке `HOOKS` есть `microcode` после `autodetect` (в стандартном конфиге он уже есть).

### GPU-параметры (строка options)

| GPU | Параметр |
|---|---|
| **NVIDIA** (`nvidia-open-dkms`) | — (`nvidia-drm.modeset=1` и `nvidia-drm.fbdev=1` включены по умолчанию в `nvidia-utils`) |
| **NVIDIA** (legacy `nvidia-580xx-dkms` из AUR) | `nvidia-drm.modeset=1` — на всякий случай: по умолчанию его включает пакет `nvidia-utils`, а для AUR-пакета это не гарантировано; без modeset Wayland не работает |
| **AMD** | — (драйвер `amdgpu` грузится автоматически) |
| **Intel** | — (драйвер `i915` / `xe` грузится автоматически) |

> 💡 Проверка после загрузки (обе команды должны вывести `Y`):
>
> ```bash
> cat /sys/module/nvidia_drm/parameters/modeset
> cat /sys/module/nvidia_drm/parameters/fbdev
> ```
>
> Если `fbdev` выводит `N` — добавь в `options` ещё и `nvidia-drm.fbdev=1`.

### Готовые конфиги под типовые конфигурации

Для **Intel CPU + NVIDIA GPU**, **AMD CPU + AMD GPU** и **Intel CPU + Intel iGPU** запись теперь одинаковая:

```
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs
```

> 💡 Для legacy NVIDIA (`nvidia-580xx-dkms`) добавь в конец строки `options` параметр `nvidia-drm.modeset=1`.

---

## 7. Создание пользователя

Выходим из chroot, размонтируем разделы и перезагружаемся:

```bash
exit            # или Ctrl+D — выход из chroot
umount -R /mnt
reboot
```

> 💡 `umount -R /mnt` не обязателен, но рекомендован установочным руководством: так видно, если какой-то раздел ещё занят.

После перезагрузки **логинимся под `root`** и создаём пользователя:

```bash
useradd -m <имя_пользователя>
passwd <имя_пользователя>
usermod -aG wheel <имя_пользователя>
userdbctl groups-of-user <имя_пользователя>
```

> 💡 Достаточно группы `wheel` (для `sudo`; кроме того, polkit по умолчанию считает членов `wheel` администраторами). Группы `audio`, `video`, `optical`, `storage` в вики — «Pre-systemd groups»: сейчас udev помечает устройства тегом `uaccess`, а `logind` выдаёт права активной сессии через ACL. Добавление в них может даже ломать функции: группа `audio` ломает быстрое переключение пользователей и позволяет приложениям блокировать программное микширование.
>
> Исключения, когда группа всё-таки нужна:
> - `audio` — ALSA/OSS в удалённых сессиях;
> - `storage` — работа с некоторыми устройствами через `udisksctl`;
> - `video` — некоторые утилиты яркости (например, `light`) требуют членства в `video`.

### Устанавливаем sudo

```bash
pacman -S sudo
EDITOR=vim visudo
```

> 💡 Переменная **`EDITOR=vim`** обязательна: в пакете `base` редактор `vi` отсутствует, есть только `vim` (поставлен через pacstrap). Без указания переменной `visudo` ищет `/usr/bin/vi` и падает с ошибкой `редактор не найден`.

**Раскомментируем строку:**

```
%wheel ALL=(ALL:ALL) ALL
```

---

## 8. Подключение к Wi-Fi после установки

Если ноутбук подключается по Ethernet — пропускай этот раздел. Wi-Fi после установки настраивается через **NetworkManager** (уже включён нами на [шаге 5](#-включаем-networkmanager)).

### 🚀 Быстрый способ — `nmcli`

Включить Wi-Fi (если выключен):

```bash
nmcli radio wifi on
```

Посмотреть доступные сети:

```bash
nmcli device wifi list
```

Подключиться:

```bash
nmcli device wifi connect "<SSID>" password "<пароль>"
```

> 💡 Кавычки нужны, если в имени сети или пароле есть пробелы / спецсимволы.

Проверить интернет:

```bash
ping -c 3 archlinux.org
```

### 🖥️ Удобный способ — `nmtui` (текстовое меню)

```bash
nmtui
```

В меню:

1. **Activate a connection** → Enter
2. Стрелками выбрать свою сеть → Enter
3. Ввести пароль → OK
4. **Back** → **Quit**

### 🛠️ Полезные команды

**Посмотреть текущее подключение:**

```bash
nmcli connection show --active
```

**Отключиться:**

```bash
nmcli device disconnect wlan0
```

**Удалить сохранённое подключение:**

```bash
nmcli connection delete "<SSID>"
```

**Если Wi-Fi-карта не видна:**

```bash
nmcli device status
```

> 💡 Должна быть строка вида `wlan0  wifi  ...`. Если её нет — отсутствует firmware. Проверь, что в pacstrap был пакет `linux-firmware`.

NetworkManager автоматически сохраняет подключение — при следующих загрузках Wi-Fi подключится сам.

---

## ✅ Готово

Делаем перезагрузку системы и заходим под созданным пользователем.

> 🎉 **Поздравляю — система установлена!**
