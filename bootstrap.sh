#!/usr/bin/env bash
# ВАЖНО: запускать от обычного пользователя, НЕ через sudo.
# Скрипт сам поднимает права через sudo там, где нужно.
# При запуске через sudo файлы в $HOME лягут с владельцем root.
 
set -euo pipefail

# Защита от запуска от root / через sudo.
# $EUID — стандартная bash-переменная, эффективный UID процесса.
# Если запустить через "sudo bash bootstrap.sh", $EUID будет 0,
# и все симлинки в ~/.config/... лягут с владельцем root (либо вообще в /root/),
# что приведёт к нерабочей системе и долгой починке chown'ом.
# Комментарий в шапке этого не предотвращает — нужна явная защита.
if [ "$EUID" -eq 0 ]; then
  echo "Ошибка: запускайте скрипт от обычного пользователя, не от root и не через sudo."
  echo "Скрипт сам поднимает права через sudo там, где это нужно."
  exit 1
fi
 
# ============================================================
# Функции системных правок (определяются здесь, вызываются ниже)
# ============================================================

# Детект «ноутбук или десктоп».
# Используется для:
#   - выбора набора пакетов (laptop-only: PPD, brightnessctl, BT-стек);
#   - включения сервисов power-profiles-daemon и bluetooth.
# Логика: на ноуте ядро экспортирует батарею в /sys/class/power_supply/BAT*.
# На десктопе этого каталога нет (есть только AC, mains, USB-power-bank и т.п.).
# Это надёжнее dmidecode (требует root, может врать на самосборах) и uname.
is_laptop() {
  compgen -G '/sys/class/power_supply/BAT*' > /dev/null
}
 
# Починка PAM-стека hyprlock.
# Arch-пакет hyprlock ставит неполный /etc/pam.d/hyprlock (только строка auth),
# из-за чего не работает pam_faillock и возможен краш при разблокировке через
# pam_end (см. hyprwm/hyprlock#953). Дополняем до полного стека auth/account/session.
# Идемпотентно: если account и session уже есть — ничего не делает.
fix_hyprlock_pam() {
  local pam_file="/etc/pam.d/hyprlock"
 
  if [ ! -f "$pam_file" ]; then
    echo "  [pam] $pam_file не найден, пропускаю (hyprlock не установлен?)"
    return 0
  fi
 
  if grep -qE '^[[:space:]]*account[[:space:]]' "$pam_file" \
     && grep -qE '^[[:space:]]*session[[:space:]]' "$pam_file"; then
    echo "  [pam] account/session уже на месте, пропускаю"
    return 0
  fi
 
  echo "  [pam] дополняю $pam_file"
  # Бэкап с таймстампом перед перезаписью.
  sudo cp "$pam_file" "$pam_file.bak.$(date +%Y%m%d-%H%M%S)"
  # Перезаписываем каноническим полным стеком (порядок строк в PAM важен).
  sudo tee "$pam_file" > /dev/null <<'PAMEOF'
#%PAM-1.0
auth      include   login
account   include   login
session   include   login
PAMEOF
  echo "  [pam] готово"
}
 
# Снять лимит неудачных попыток PAM (deny = 0).
# ВНИМАНИЕ: /etc/security/faillock.conf глобален — отключает счётчик неудачных
# попыток для ВСЕХ PAM-сервисов (вход в TTY, sudo и т.д.), не только hyprlock.
# Это осознанный выбор для домашней однопользовательской машины.
# Идемпотентно: покрывает случаи «уже 0», «есть число», «закомментировано», «нет строки».
ensure_faillock_deny0() {
  local f="/etc/security/faillock.conf"
 
  if [ ! -f "$f" ]; then
    echo "  [faillock] $f не найден, пропускаю"
    return 0
  fi
 
  if grep -qE '^[[:space:]]*deny[[:space:]]*=[[:space:]]*0[[:space:]]*$' "$f"; then
    echo "  [faillock] deny = 0 уже установлен"
    return 0
  fi
 
  sudo cp "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"
 
  if grep -qE '^[[:space:]]*#?[[:space:]]*deny[[:space:]]*=' "$f"; then
    # Строка deny есть (активная или закомментированная) — заменяем.
    sudo sed -i -E 's/^[[:space:]]*#?[[:space:]]*deny[[:space:]]*=.*/deny = 0/' "$f"
  else
    # Строки deny нет вовсе — добавляем в конец.
    echo 'deny = 0' | sudo tee -a "$f" > /dev/null
  fi
  echo "  [faillock] установлен deny = 0"
}
 
# === 1. Обновление системы ===
sudo pacman -Syu --noconfirm
 
# === 2. Пакеты из официальных репозиториев ===
PACMAN_PKGS=(
  # Hyprland core + инфраструктура
  hyprland hyprlock hyprshot hypridle polkit hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  xorg-xwayland
  qt5-wayland qt6-wayland qt5ct qt6ct
  lua
  awww
 
  # Шрифты
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
 
  # Аудио (pipewire-jack — при конфликте с jack2 выбираем его)
  pipewire pipewire-pulse pipewire-jack wireplumber pavucontrol playerctl
 
  # Shell и промпт
  fish starship lsd
 
  # CLI-утилиты
  git less fastfetch btop wl-clipboard
 
  # Статус-панель и лаунчер
  quickshell rofi
 
  # GUI-приложения
  firefox telegram-desktop obsidian
  nautilus sushi file-roller
  viewnior

  # Автомонтирование USB/SD + уведомления mount/unmount
  udiskie

  # Темизация GTK/иконки
  papirus-icon-theme adw-gtk-theme

  #Network
  nm-connection-editor networkmanager-openvpn

  # Системные звуки (для notification sounds через paplay)
  sound-theme-freedesktop

  # Notifications (для notify-send в тестах и скриптах)
  libnotify

  # GStreamer codecs — инфраструктура для GUI-медиа (Showtime и др.)
  gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gst-plugin-pipewire

  # Медиа-приложения
  # showtime    — видеоплеер.
  # cmus        — аудиоплеер.
  # impression  — запись ISO на USB.
  showtime cmus impression
 
  # дополнительно
  qbittorrent
)
 
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# === 2b. Laptop-only пакеты ===
# Ставятся только при детекте ноутбука. На десктопе эти пакеты бесполезны:
#   - power-profiles-daemon — управление CPU-профилями через ACPI platform_profile,
#     на десктопе нет ни батареи, ни platform_profile;
#   - brightnessctl — управление подсветкой экрана, на десктопном мониторе подсветка
#     управляется самим монитором через OSD;
#   - bluez/bluez-utils/blueman — на десктопе нет встроенного BT-чипа
#     (см. HANDOFF, специфика по машинам).
LAPTOP_PKGS=(
  # Laptop power
  power-profiles-daemon brightnessctl

  # Bluetooth
  bluez bluez-utils blueman
)

if is_laptop; then
  echo "[detect] обнаружен ноутбук — устанавливаю laptop-only пакеты"
  sudo pacman -S --needed --noconfirm "${LAPTOP_PKGS[@]}"
else
  echo "[detect] обнаружен десктоп — пропускаю laptop-only пакеты"
fi
 
# === 3. Установка yay (AUR-хелпер) ===
if ! command -v yay &>/dev/null; then
  TMPDIR_YAY=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$TMPDIR_YAY/yay-bin"
  (cd "$TMPDIR_YAY/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$TMPDIR_YAY"
fi
 
# === 4. Пакеты из AUR ===
AUR_PKGS=(
  vesktop-bin  # ИМЕННО -bin, сборка из исходников падает на ECONNRESET (GitHub)
  ttf-material-symbols-variable-git    # Иконочный шрифт для Quickshell-бара (variable axis для анимаций FILL/wght)
  xcursor-pro-hyprcursor               # Курсор: hyprcursor от 0xk1f0 (форк ful1e5), работает и в XWayland
  papirus-folders-git                  # Утилита смены цвета папок Papirus (см. секцию 9)
)
 
yay -S --needed --noconfirm "${AUR_PKGS[@]}"
 
# === 5a. Системные сервисы (PipeWire) ===
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# === 5b. Power-profiles-daemon (только на ноутбуке) ===
# На десктопе сервис бесполезен (нет батареи и нет ACPI platform_profile),
# на ноуте — нужен для управления CPU-профилями через DBus.
# Пакет power-profiles-daemon ставится только на ноуте (см. секцию 2b),
# поэтому на десктопе сервиса нет физически — но проверку оставляем как
# страховку на случай, если пакет когда-нибудь окажется в системе по другой причине.
if is_laptop; then
    echo "  [ppd] ноутбук — включаю power-profiles-daemon.service"
    sudo systemctl enable --now power-profiles-daemon.service
else
    echo "  [ppd] десктоп — пропускаю включение PPD"
fi

#=== 5c. Bluetooth (только на ноутбуке с BT-адаптером) ===
# На десктопе без встроенного BT-чипа сервис висит вхолостую и засоряет
# журналы. На ноуте — нужен для работы blueman/Quickshell-попапа.
# Двухуровнево: сначала проверяем что это вообще ноут, внутри — что в нём есть BT.
if is_laptop; then
    if compgen -G '/sys/class/bluetooth/hci*' > /dev/null; then
        echo "  [bt] ноутбук с BT-адаптером — включаю bluetooth.service"
        sudo systemctl enable --now bluetooth.service
    else
        echo "  [bt] ноутбук, но BT-адаптер не обнаружен — пропускаю включение сервиса"
    fi
else
    echo "  [bt] десктоп — пропускаю включение bluetooth.service"
fi
 
# === 6. Системные правки для hyprlock (PAM + faillock) ===
# Зависит от установленного пакета hyprlock (см. шаг 2).
echo "=== Системные правки hyprlock ==="
fix_hyprlock_pam
ensure_faillock_deny0
 
# === 7. Смена дефолтной оболочки на fish ===
# chsh без sudo требует пароль через PAM (/etc/pam.d/chsh) — в неинтерактивном
# скрипте это либо повесит выполнение на запросе пароля, либо упадёт.
# От root chsh -s меняет shell любого пользователя без PAM-запроса.
# sudo-сессия здесь уже активна с момента первого sudo pacman в секции 1.
sudo chsh -s /usr/bin/fish "$USER"
 
# === 8. Симлинки fish, starship, hypridle ===
# Папки kanagawa-paper/{fish,starship,hypridle} с конфигами уже приехали из репозитория.
# Симлинки создаём ДО первого запуска fish, иначе fish создаст свою папку
# и симлинк ляжет рекурсивно.
 
[ -e ~/.config/fish ] && rm -rf ~/.config/fish
ln -s ~/.config/hypr/kanagawa-paper/fish ~/.config/fish
 
[ -e ~/.config/starship.toml ] && rm -f ~/.config/starship.toml
ln -s ~/.config/hypr/kanagawa-paper/starship/starship.toml ~/.config/starship.toml
  
[ -e ~/.config/hypr/hypridle.conf ] && rm -f ~/.config/hypr/hypridle.conf
ln -s kanagawa-paper/hypridle/hypridle.conf ~/.config/hypr/hypridle.conf

# === 8b. Симлинки cmus (тема + rc) ===
# Симлинкуем ОТДЕЛЬНЫЕ ФАЙЛЫ, не папку ~/.config/cmus целиком:
# cmus пишет в неё runtime-данные (autosave, lib.pl, playlists/, cache,
# command-history) — это библиотека и состояние, не часть темы.
# Симлинк папкой утянул бы runtime в git-репо темы.
#
# Папка ~/.config/cmus может ещё не существовать (свежая система,
# cmus не запускался) — создаём заранее, чтобы первый запуск увидел rc
# и сразу применил colorscheme.

CMUS_DIR="$HOME/.config/hypr/kanagawa-paper/cmus"

if [ ! -d "$CMUS_DIR" ]; then
  echo "  [cmus] $CMUS_DIR не найден"
  echo "  [cmus] Разверните репозиторий в ~/.config/hypr/ до запуска bootstrap"
  exit 1
fi

mkdir -p ~/.config/cmus

ln -sfn "$CMUS_DIR/kanagawa-paper.theme" ~/.config/cmus/kanagawa-paper.theme
ln -sfn "$CMUS_DIR/rc"                   ~/.config/cmus/rc

# === 9. Симлинки темизации (GTK3/GTK4/cursor/qt5ct/qt6ct) + цвет папок Papirus ===
# Папка theming/ с конфигами уже приехала из репозитория.
# Симлинкуем КАЖДЫЙ файл отдельно (не папку), потому что:
#   - в ~/.config/gtk-3.0/ уже может лежать bookmarks (не наш) — не трогаем
#   - симлинк папки на папку даёт классические грабли с colors/colors/

THEMING_DIR="$HOME/.config/hypr/kanagawa-paper/theming"

if [ ! -d "$THEMING_DIR" ]; then
  echo "  [theming] $THEMING_DIR не найден"
  echo "  [theming] Разверните репозиторий в ~/.config/hypr/ до запуска bootstrap"
  exit 1
fi

# Гарантируем существование целевых директорий
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0 \
         ~/.config/qt5ct/colors ~/.config/qt6ct/colors \
         ~/.icons

# GTK3
ln -sfn "$THEMING_DIR/gtk/gtk-3.0/gtk.css"      ~/.config/gtk-3.0/gtk.css
ln -sfn "$THEMING_DIR/gtk/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini

# GTK4 (libadwaita использует :root + --vars, темы виджетов её игнорируют)
ln -sfn "$THEMING_DIR/gtk/gtk-4.0/gtk.css"      ~/.config/gtk-4.0/gtk.css
ln -sfn "$THEMING_DIR/gtk/gtk-4.0/settings.ini" ~/.config/gtk-4.0/settings.ini

# XCursor fallback (~/.icons/default → симлинк на папку, потому что её ещё нет)
[ -e ~/.icons/default ] && rm -rf ~/.icons/default
ln -sfn "$THEMING_DIR/cursor/default" ~/.icons/default

# Qt5ct
ln -sfn "$THEMING_DIR/qt/qt5ct/qt5ct.conf"                 ~/.config/qt5ct/qt5ct.conf
ln -sfn "$THEMING_DIR/qt/qt5ct/colors/kanagawa-paper.conf" ~/.config/qt5ct/colors/kanagawa-paper.conf

# Qt6ct
ln -sfn "$THEMING_DIR/qt/qt6ct/qt6ct.conf"                 ~/.config/qt6ct/qt6ct.conf
ln -sfn "$THEMING_DIR/qt/qt6ct/colors/kanagawa-paper.conf" ~/.config/qt6ct/colors/kanagawa-paper.conf

# Цвет папок Papirus (требует sudo — papirus-folders правит /usr/share/icons/)
# Зависит от установленных папок papirus-icon-theme + papirus-folders-git выше.
if command -v papirus-folders &>/dev/null; then
  echo "  [papirus] устанавливаю цвет папок: paleorange"
  sudo papirus-folders -C paleorange --theme Papirus-Dark
else
  echo "  [papirus] утилита papirus-folders не найдена, пропускаю смену цвета"
fi
 
# === 10. System-watchers (failed systemd units) ===
# Симлинкуем service+timer из репо в стандартный путь user-юнитов
# (~/.config/systemd/user — обязательный путь, override-ить нельзя),
# перезагружаем systemd и активируем таймер.
# Таймер раз в 5 минут собирает `systemctl --failed` (system + user scope),
# при появлении новых упавших юнитов шлёт notify-send с urgency=critical →
# попадает в Critical-tier нашего NotificationServer.

SYSWATCH_DIR="$HOME/.config/hypr/kanagawa-paper/system-watchers"

if [ ! -d "$SYSWATCH_DIR" ]; then
  echo "  [system-watchers] $SYSWATCH_DIR не найден"
  echo "  [system-watchers] Разверните репозиторий в ~/.config/hypr/ до запуска bootstrap"
  exit 1
fi

# Скрипт должен быть исполняемым (на случай, если git не сохранил +x).
chmod +x "$SYSWATCH_DIR/failed-units-check.fish"

mkdir -p ~/.config/systemd/user

ln -sfn "$SYSWATCH_DIR/failed-units-check.service" ~/.config/systemd/user/failed-units-check.service
ln -sfn "$SYSWATCH_DIR/failed-units-check.timer"   ~/.config/systemd/user/failed-units-check.timer

systemctl --user daemon-reload
systemctl --user enable --now failed-units-check.timer
echo "  [system-watchers] failed-units-check.timer активирован"

# === 11. Autologin на tty1 ===
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
 
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
Type=idle
EOF
 
echo
echo "=== Bootstrap завершён. ==="
echo "Дальше: перезагрузка → autologin → fish → Hyprland."
echo "Перед reboot убедитесь, что репозиторий с конфигами развёрнут в ~/.config/hypr/"
 
