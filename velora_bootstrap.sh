#!/usr/bin/env bash
set -euo pipefail

# Защита от запуска от root / через sudo.
if [ "$EUID" -eq 0 ]; then
  echo "Ошибка: запускайте скрипт от обычного пользователя, не от root и не через sudo."
  echo "Скрипт сам поднимает права через sudo там, где это нужно."
  exit 1
fi

VELORA_DIR="$HOME/.config/hypr/velora"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Проверка, что репозиторий развёрнут в ~/.config/hypr/ до запуска.
for dir in fish starship hypridle cmus appearance system-watchers; do
  if [ ! -d "$VELORA_DIR/$dir" ]; then
    echo "Ошибка: нет $VELORA_DIR/$dir"
    echo "Разверните репозиторий в ~/.config/hypr/ до запуска bootstrap."
    exit 1
  fi
done

# link_safe <цель> <ссылка> — создаёт симлинк.
# Существующий обычный файл или папка переносится в <ссылка>.bak.<дата>.
# Старый симлинк заменяется без бэкапа: он хранит только путь.
link_safe() {
  local target="$1"
  local link="$2"

  if [ -L "$link" ]; then
    rm -f "$link"
  elif [ -e "$link" ]; then
    mv "$link" "$link.bak.$STAMP"
    echo "  [бэкап] $link -> $link.bak.$STAMP"
  fi
  mkdir -p "$(dirname "$link")"
  ln -s "$target" "$link"
}

# ============================================================
# Определение железа по модулям.
# Возвращают 0 (есть) или 1 (нет), либо печатают результат.
# ============================================================

# Батарея. /sys/class/power_supply/BAT* экспортируется ядром для батарей
# ноутбука и ИБП. На десктопе без ИБП каталога нет.
has_battery() {
  compgen -G '/sys/class/power_supply/BAT*' > /dev/null
}

# Подсветка экрана. /sys/class/backlight/* — управляемая яркость
# встроенной панели. Только при встроенном дисплее (ноутбук).
has_backlight() {
  compgen -G '/sys/class/backlight/*' > /dev/null
}

# Bluetooth-адаптер. /sys/class/bluetooth/hci* — контроллер, видимый
# ядру. Отсутствует на десктопе без USB-свистка (или если свисток вынут).
has_bluetooth() {
  compgen -G '/sys/class/bluetooth/hci*' > /dev/null
}

# Производители GPU в системе. Читаем vendor ID каждой карты DRM
# из /sys/class/drm/cardN/device/vendor. Печатаем уникальные имена
# через пробел: nvidia, amd, intel.
detect_gpus() {
  local card vendor_id
  local -a vendors=()
  for card in /sys/class/drm/card*/; do
    # Отбираем только карты (card0), пропускаем коннекторы (card0-DP-1).
    [[ "$(basename "$card")" =~ ^card[0-9]+$ ]] || continue
    if [ -r "${card}device/vendor" ]; then
      vendor_id=$(cat "${card}device/vendor" 2>/dev/null)
      vendor_id=${vendor_id#0x}
      case "$vendor_id" in
        10de) vendors+=("nvidia") ;;
        1002) vendors+=("amd") ;;
        8086) vendors+=("intel") ;;
      esac
    fi
  done
  if [ ${#vendors[@]} -eq 0 ]; then
    return 1
  fi
  printf '%s\n' "${vendors[@]}" | sort -u | paste -sd' ' -
}

# === 1. Обновление системы ===
sudo pacman -Syu --noconfirm

# === 2. Пакеты из официальных репозиториев ===
PACMAN_PKGS=(
  # Сборка (нужно для makepkg и yay)
  base-devel

  # Hyprland + инфраструктура
  hyprland hyprlock hyprshot hypridle polkit hyprpolkitagent
  xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  xorg-xwayland
  qt5-wayland qt6-wayland qt5ct qt6ct
  lua
  awww

  # Шрифты
  noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd

  # Аудио
  pipewire pipewire-pulse pipewire-jack wireplumber pavucontrol playerctl

  # Shell
  fish starship lsd

  # CLI-утилиты
  git less fastfetch btop wl-clipboard

  # Панель и лаунчер
  quickshell rofi

  # GUI-приложения
  firefox telegram-desktop obsidian

  # Файловый менеджер
  nautilus sushi file-roller viewnior

  # Автомонтирование
  udiskie

  # Темизация
  papirus-icon-theme adw-gtk-theme

  # Сеть
  nm-connection-editor networkmanager-openvpn

  # Системные звуки
  sound-theme-freedesktop

  # Уведомления
  libnotify

  # GStreamer
  gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav gst-plugin-pipewire

  # Медиа
  showtime cmus impression

  # Прочее
  qbittorrent
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# === 2a. Пакеты по производителю GPU ===
# Драйверы ставятся по всем найденным видеокартам. На гибриде
# ставятся оба набора; переменные окружения выбирает gpu_env в fish.
read -ra GPUS <<< "$(detect_gpus || true)"
GPU_PKGS=()
for gpu in "${GPUS[@]}"; do
  case "$gpu" in
    amd)    GPU_PKGS+=(vulkan-radeon libva-mesa-driver) ;;
    intel)  GPU_PKGS+=(vulkan-intel intel-media-driver) ;;
    nvidia) GPU_PKGS+=(nvidia-open-dkms nvidia-utils libva-nvidia-driver) ;;
  esac
done

if [ ${#GPU_PKGS[@]} -gt 0 ]; then
  echo "[detect] GPU: ${GPUS[*]} — ставлю ${GPU_PKGS[*]}"
  sudo pacman -S --needed --noconfirm "${GPU_PKGS[@]}"
else
  echo "[detect] GPU не определён — драйверы не ставлю"
fi

# === 2b. Пакеты по модулям железа ===
# Батарея → power-profiles-daemon (управление CPU-профилями через ACPI).
if has_battery; then
  echo "[detect] батарея обнаружена — ставлю power-profiles-daemon"
  sudo pacman -S --needed --noconfirm power-profiles-daemon
else
  echo "[detect] батареи нет — пропускаю power-profiles-daemon"
fi

# Подсветка → brightnessctl (управление яркостью встроенной панели).
if has_backlight; then
  echo "[detect] подсветка обнаружена — ставлю brightnessctl"
  sudo pacman -S --needed --noconfirm brightnessctl
else
  echo "[detect] подсветки нет — пропускаю brightnessctl"
fi

# Bluetooth → bluez + blueman (стек и GUI-менеджер).
if has_bluetooth; then
  echo "[detect] Bluetooth модуль обнаружена — ставлю bluez bluez-utils blueman"
  sudo pacman -S --needed --noconfirm bluez bluez-utils blueman
else
  echo "[detect] Bluetooth нет — пропускаю BT-стек"
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
  vesktop-bin
  ttf-material-symbols-variable-git
  xcursor-pro-hyprcursor
  papirus-folders-git
)

yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# === 5. Включение сервисов ===
# PipeWire — всегда (аудио-стек, user-сервисы).
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# power-profiles-daemon — только при батарее (system-сервис).
if has_battery; then
  echo "[svc] Включаю power-profiles-daemon.service"
  sudo systemctl enable --now power-profiles-daemon.service
else
  echo "[svc] Пропускаю power-profiles-daemon"
fi

# bluetooth — только при BT-адаптере (system-сервис).
if has_bluetooth; then
  echo "[svc] Включаю bluetooth.service"
  sudo systemctl enable --now bluetooth.service
else
  echo "[svc] Пропускаю bluetooth.service"
fi

# === 6. Системные правки hyprlock (PAM + faillock) ===
# Arch-пакет hyprlock ставит неполный /etc/pam.d/hyprlock: только строка auth.
# Из-за этого не работает pam_faillock и возможен краш при разблокировке
# через pam_end (hyprwm/hyprlock#953). Дополняем до полного стека.
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
  sudo cp "$pam_file" "$pam_file.bak.$STAMP"
  sudo tee "$pam_file" > /dev/null <<'PAMEOF'
#%PAM-1.0
auth      include   login
account   include   login
session   include   login
PAMEOF
  echo "  [pam] готово"
}

# Снять лимит неудачных попыток PAM (deny = 0).
# ВНИМАНИЕ: /etc/security/faillock.conf глобален — отключает счётчик
# для ВСЕХ PAM-сервисов (TTY, sudo, hyprlock), не только для hyprlock.
# Осознанный выбор для домашней однопользовательской машины.
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

  sudo cp "$f" "$f.bak.$STAMP"

  if grep -qE '^[[:space:]]*#?[[:space:]]*deny[[:space:]]*=' "$f"; then
    sudo sed -i -E 's/^[[:space:]]*#?[[:space:]]*deny[[:space:]]*=.*/deny = 0/' "$f"
  else
    echo 'deny = 0' | sudo tee -a "$f" > /dev/null
  fi
  echo "  [faillock] установлен deny = 0"
}

echo "=== Системные правки hyprlock ==="
fix_hyprlock_pam
ensure_faillock_deny0

# === 7. Смена оболочки на fish ===
# chsh от обычного пользователя требует пароль через PAM — в неинтерактивном
# скрипте это повесит выполнение. От root chsh меняет оболочку без запроса.
sudo chsh -s /usr/bin/fish "$USER"

# === 8. Генерация производных файлов темы ===
# Нужна до симлинков: cmus, GTK и Qt ссылаются на сгенерированные файлы.
# Команда theme set откатывает изменения при сбое генератора.
THEME_SCRIPT="$VELORA_DIR/appearance/theme.fish"
DEFAULT_THEME="kanagawa-paper"

fish "$THEME_SCRIPT" set "$DEFAULT_THEME"

# === 9. Симлинки fish, starship, hypridle ===
# Проверка до замены: пустой или битый fish-конфиг не должен занять место.
if [ ! -f "$VELORA_DIR/fish/config.fish" ]; then
  echo "Ошибка: нет $VELORA_DIR/fish/config.fish, пропускаю замену ~/.config/fish"
  exit 1
fi

# Симлинк создаётся ДО первого запуска fish: иначе fish создаст свою папку
# и симлинк ляжет рекурсивно.
link_safe "$VELORA_DIR/fish" ~/.config/fish
link_safe "$VELORA_DIR/starship/starship.toml" ~/.config/starship.toml
link_safe "velora/hypridle/hypridle.conf" ~/.config/hypr/hypridle.conf

# === 9b. Симлинки cmus (тема + rc) ===
# Симлинкуем ОТДЕЛЬНЫЕ ФАЙЛЫ, не папку целиком: cmus пишет в неё
# runtime-данные (autosave, lib.pl, playlists) — это состояние, не тема.
# cmus ищет тему по имени в ~/.config/cmus: velora.theme → current.theme.
CMUS_DIR="$VELORA_DIR/cmus"

mkdir -p ~/.config/cmus
link_safe "$CMUS_DIR/current.theme" ~/.config/cmus/velora.theme
link_safe "$CMUS_DIR/rc" ~/.config/cmus/rc

# === 10. Симлинки темизации + цвет папок Papirus ===
# Симлинкуем КАЖДЫЙ файл отдельно: в ~/.config/gtk-3.0/ может лежать
# чужой bookmarks, а симлинк папки на папку даёт грабли colors/colors/.
THEMING_DIR="$VELORA_DIR/appearance"

link_safe "$THEMING_DIR/gtk/gtk-3.0/gtk.css"      ~/.config/gtk-3.0/gtk.css
link_safe "$THEMING_DIR/gtk/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini
link_safe "$THEMING_DIR/gtk/gtk-4.0/gtk.css"      ~/.config/gtk-4.0/gtk.css
link_safe "$THEMING_DIR/gtk/gtk-4.0/settings.ini" ~/.config/gtk-4.0/settings.ini

link_safe "$THEMING_DIR/cursor/default" ~/.icons/default

link_safe "$THEMING_DIR/qt/qt5ct/qt5ct.conf"             ~/.config/qt5ct/qt5ct.conf
link_safe "$THEMING_DIR/qt/qt5ct/colors/velora.conf"     ~/.config/qt5ct/colors/velora.conf
link_safe "$THEMING_DIR/qt/qt6ct/qt6ct.conf"             ~/.config/qt6ct/qt6ct.conf
link_safe "$THEMING_DIR/qt/qt6ct/colors/velora.conf"     ~/.config/qt6ct/colors/velora.conf

if command -v papirus-folders &>/dev/null; then
  echo "  [papirus] устанавливаю цвет папок: paleorange"
  sudo papirus-folders -C paleorange --theme Papirus-Dark
else
  echo "  [papirus] утилита не найдена, пропускаю смену цвета"
fi

# === 11. System-watchers (упавшие systemd-юниты) ===
# Симлинкуем service+timer в ~/.config/systemd/user (обязательный путь,
# переопределить нельзя), перезагружаем systemd и активируем таймер.
# Таймер раз в 5 минут собирает `systemctl --failed` (system + user scope).
# При появлении новых упавших юнитов шлёт notify-send с urgency=critical.
SYSWATCH_DIR="$VELORA_DIR/system-watchers"

# Скрипт должен быть исполняемым (на случай, если git не сохранил +x).
chmod +x "$SYSWATCH_DIR/failed-units-check.fish"

link_safe "$SYSWATCH_DIR/failed-units-check.service" ~/.config/systemd/user/failed-units-check.service
link_safe "$SYSWATCH_DIR/failed-units-check.timer"   ~/.config/systemd/user/failed-units-check.timer

systemctl --user daemon-reload
systemctl --user enable --now failed-units-check.timer
echo "  [system-watchers] failed-units-check.timer активирован"

# === 12. Точка входа Hyprland ===
# Не переключается автоматически: сначала проверка velora/hypr вручную.
# Команда для ручного переключения (см. отчёт этапа 1):
#   Hyprland --verify-config --config ~/.config/hypr/velora/hypr/hyprland.lua
echo "=== Готово. Точка входа ~/.config/hypr/hyprland.lua не изменена. ==="
