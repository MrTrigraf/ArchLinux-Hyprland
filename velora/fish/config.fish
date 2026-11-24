# === PATH (нужно и в неинтерактивных сессиях) ===
# ~/go/bin — Go-утилиты (например, миграции PostgreSQL).
# Go ставится отдельно в составе nvim-bootstrap.
fish_add_path -g ~/go/bin

set -gx KITTY_CONFIG_DIRECTORY $HOME/.config/hypr/velora/kitty

# === Промпт через starship ===
starship init fish | source

# === Цвета fish — имена ANSI ===
# Значения берутся из палитры kitty, то есть из текущей темы.
# Допустимые имена — man set_color; опции вроде --background — тоже.
set -gx fish_color_normal          normal
set -gx fish_color_command         brblue
set -gx fish_color_keyword         magenta
set -gx fish_color_quote           yellow
set -gx fish_color_redirection     cyan
set -gx fish_color_end             magenta
set -gx fish_color_error           brred
set -gx fish_color_param           brblack
set -gx fish_color_comment         brblack
set -gx fish_color_operator        brcyan
set -gx fish_color_escape          yellow
set -gx fish_color_autosuggestion  brblack
set -gx fish_color_selection       --background=black
set -gx fish_color_search_match    --background=black
set -gx fish_color_cancel          brred
set -gx fish_color_option          bryellow

# === Интерактивные настройки ===
if status is-interactive
    #fastfetch
    # Цвет ключей и значков — акцент текущей темы (## accent = colorN, по умолчанию color4).
    # Формат @N — цвет N палитры терминала (fastfetch 2.57+), поэтому цвет следует палитре kitty.
    function fastfetch --wraps='fastfetch'
      set -l accent 4
      set -l m (string match -r -- '^##\s*accent\s*=\s*color(\d+)\s*$' < ~/.config/hypr/velora/themes/current/theme.conf 2>/dev/null)
      test -n "$m[2]"; and set accent $m[2]
      command fastfetch --config ~/.config/hypr/velora/fastfetch/config.jsonc --color-keys @$accent $argv
    end

    # Отключить дефолтный fish-greeting (логотип fish)
    set -U fish_greeting

    # Алиасы
    alias ls='lsd --tree --group-dirs=first --depth 1'
end

# === Быстрое редактирование конфига kitty (не идти по симлинкам) ===
function edit-kitty
    nvim ~/.config/hypr/velora/kitty/kitty.conf
end

# === GPU-переменные до запуска Hyprland ===
# Hyprland и все программы сессии наследуют окружение этого процесса.
# NVIDIA-переменные задаём, только если монитор подключён к карте NVIDIA
# (vendor 0x10de). На гибридах с выводом через AMD/Intel переменных нет.
# Набор переменных — тот же, что в v1 (kanagawa-paper/hypr/env.lua, блок Desktop).
# Страница NVIDIA в Arch Wiki эти переменные для Wayland не требует;
# перед изменением набора сверяться с ней.
function gpu_env
    for connector in /sys/class/drm/card*-*
        test -r $connector/status; or continue
        test (cat $connector/status) = connected; or continue

        set -l card (string replace -r -- '-.*$' '' (path basename $connector))
        test -r /sys/class/drm/$card/device/vendor; or continue

        if test (cat /sys/class/drm/$card/device/vendor) = 0x10de
            set -gx LIBVA_DRIVER_NAME nvidia
            set -gx __GLX_VENDOR_LIBRARY_NAME nvidia
            set -gx NVD_BACKEND direct
            set -gx GBM_BACKEND nvidia-drm
        end
        return 0
    end
end

# === Автозапуск Hyprland на tty1 ===
if status is-login
    if test -z "$DISPLAY" -a "$(tty)" = /dev/tty1
        gpu_env
        exec start-hyprland
    end
end
