Для синхронизации системного времени вводим:
timedatectl set-ntp true

Для того что бы узнать свои системные диски вводим:
lsblk

Для очисток сигнатуры и разделов диска вводим:
wipefs --all /dev/"ваш диск"

Для разметки диска вводим:
cfdisk /dev/"ваш диск"
выбираем тип разделом gpt. 
создаем 3 раздела:
* 1g - EFI System
* Nx - Linux swap (раздел подкачки; размер по объёму RAM: обычно ≤ RAM, для гибернации ≥ RAM + ~10%)
* все остальное место - Linux filesystem

Форматируем диски используя файловую систему btrfs:
mkfs.btrfs -f /dev/"раздел с Linux filesystem"
mkfs.fat -F32 /dev/"EFI System"

Инициализируем раздел подкачки:
mkswap /dev/"раздел Linux swap"

Монтирование разделов:
mount /dev/"раздел с Linux filesystem" /mnt

Переходим в /mnt и создаем два подраздела (subvolume):
cd /mnt
создаем подраздел (subvolume)  для системы
btrfs subvolume create ./@
создаем подраздел (subvolume)  для пользователя
btrfs subvolume create ./@home
возвращаемся обратно введя cd

Размонтируем папку mnt:
umount /mnt -R

Монтируем подразделы (subvolume) к нашей системе и создаем папку home
монтируем подраздел (subvolume) для корня /mnt
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@ /dev/"раздел с Linux filesystem" /mnt
создаем папку home
mkdir /mnt/home
монтируем подраздел (subvolume) для корня home
mount -o rw,noatime,compress=zstd:3,ssd,ssd_spread,discard=async,space_cache=v2,subvol=/@home  /dev/"раздел с Linux filesystem" /mnt/home
проверка mount | grep /mnt и mount | grep /mnt/home

Включаем раздел подкачки, чтобы genfstab автоматически добавил его в /etc/fstab:
swapon /dev/"раздел Linux swap"
проверка swapon --show

Создаем папку для загрузчика и монтируем ее в EFI System:
mkdir /mnt/boot
mount /dev/"EFI System" /mnt/boot/

Переходим к установке самой системы.

Команда pacstrap собирается из трёх частей: базовый набор + CPU-microcode + GPU-драйверы.
pacstrap /mnt

Базовый набор (общий для всех конфигураций):
base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty

CPU-microcode — выбираем один пакет по производителю CPU:
* Intel: intel-ucode
* AMD:   amd-ucode

GPU-драйверы — выбираем набор по производителю видеокарты:
* NVIDIA (Turing 16xx / RTX 20xx и новее — от 2018 года):
    nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver
  (на ядре linux-zen нужен именно DKMS-вариант. nvidia-open-dkms = открытые модули, обязательны для RTX 50xx Blackwell и рекомендуются для всего, что новее Turing. На старых картах до Turing — nvidia-dkms вместо nvidia-open-dkms)
* AMD:
    mesa vulkan-radeon libva-mesa-driver
  (драйвер amdgpu идёт в ядре, отдельный пакет не нужен. mesa даёт OpenGL, vulkan-radeon — Vulkan, libva-mesa-driver — аппаратное декодирование видео через VA-API)
* Intel (Broadwell и новее, Gen 8+ — все iGPU примерно с 2014 года):
    mesa vulkan-intel intel-media-driver
* Intel (старее Broadwell):
    mesa vulkan-intel libva-intel-driver

Примеры готовых команд под три типовые конфигурации:

CPU = Intel + GPU = NVIDIA (RTX 20xx и новее):
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty intel-ucode nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver

CPU = AMD + GPU = AMD:
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty amd-ucode mesa vulkan-radeon libva-mesa-driver

CPU = Intel + GPU = Intel iGPU (Broadwell и новее):
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware vim networkmanager btrfs-progs kitty intel-ucode mesa vulkan-intel intel-media-driver

Генерируем файл fstab:
genfstab -U /mnt >> /mnt/etc/fstab

Даем название системному диску:
btrfs filesystem label /mnt "ArchLinux"
для проверки используем команду blkid

Входи в систему:
arch-chroot /mnt

Генерируем файл для установки локального времени:
ln -sf /usr/share/zoneinfo/"Страна"/"Город" /etc/localtime
hwclock --systohc

Настраиваем локали системы:
sudo vim /etc/locale.gen
расскоментируйте те локали которые вам необходимы
в моем случаи это
* en_US.UTF-8 UTF-8
* ru_RU.UTF-8 UTF-8
устанавливаем язык системы
sudo vim /etc/locale.conf
прописываем
LANG=и вашу локаль
LANG=ru_RU.UTF-8
генерируем локали
locale-gen

Для Русского языка в терминале:
sudo vim /etc/vconsole.conf
прописываем
KEYMAP=ru
FONT=cyr-sun16

Настройка сети:
задаем имя ПК:
sudo vim /etc/hostname
вводим любое удобное имя
в моем случаи ArchLinux
Прописываем hosts:
sudo vim /etc/hosts
вводим
127.0.0.1 localhost
::1 localhost
127.0.1.1 ArchLinux "Имя вашего ПК"

Задаем пароль для root:
passwd и вводим пароль два раза

Включаем networkmanager для корректной работы сети:
systemctl enable NetworkManager 
systemctl mask NetworkManager-wait-online

Устанавливаем загрузчик:
bootctl install
sudo vim /boot/loader/loader.conf
прописываем туда
default linux-zen.conf
timeout 0
console-mode auto
editor no

sudo vim /boot/loader/entries/linux-zen.conf
прописываем (см. варианты под CPU и GPU ниже):
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /<microcode>.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs <GPU-параметры>

CPU — выбираем initrd microcode по производителю:
* Intel CPU: initrd  /intel-ucode.img
* AMD CPU:   initrd  /amd-ucode.img

GPU — параметры в строке options:
* NVIDIA: добавить nvidia-drm.modeset=1 (обязательно для Wayland-сессий, без него Hyprland/Sway не стартуют). На драйвере 545+ можно дополнительно добавить nvidia-drm.fbdev=1 для нативного KMS-фреймбуфера
* AMD:    отдельных параметров не нужно — драйвер amdgpu грузится автоматически
* Intel:  отдельных параметров не нужно — драйвер i915 грузится автоматически

Примеры готовых конфигов под три типовые конфигурации:

CPU = Intel + GPU = NVIDIA:
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs nvidia-drm.modeset=1

CPU = AMD + GPU = AMD:
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /amd-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs

CPU = Intel + GPU = Intel iGPU:
title   linux-zen
linux   /vmlinuz-linux-zen
initrd  /intel-ucode.img
initrd  /initramfs-linux-zen.img
options root="LABEL=ArchLinux" rw rootflags=subvol=@ nowatchdog loglevel=6 rootfstype=btrfs

Создаем пользователя:
нажимаем ctrl + d
reboot
заходим под root
вводим
useradd -m "имя пользователя"
passwd "имя пользователя"
usermod -aG wheel,audio,video,optical,storage "имя пользователя"
userdbctl groups-of-user "имя пользователя"
pacman -S sudo
visudo
раскомментируйте строку:
%wheel ALL=(ALL:ALL) ALL

Делаем перезапуск системы и заходим под пользователем.

Поздравляю система установлена
