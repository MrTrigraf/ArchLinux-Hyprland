# === PATH (нужно и в неинтерактивных сессиях) ===
# ~/go/bin — Go-утилиты (например, миграции PostgreSQL).
# Go ставится отдельно в составе nvim-bootstrap.
fish_add_path -g ~/go/bin

# === Промпт через starship ===
starship init fish | source

# === Цветовая палитра fish — kanagawa-paper ===
set -gx fish_color_normal          DCD7BA
set -gx fish_color_command         698a9b
set -gx fish_color_keyword         a292a3
set -gx fish_color_quote           c4b28a
set -gx fish_color_redirection     8ea49e
set -gx fish_color_end             a292a3
set -gx fish_color_error           cc928e
set -gx fish_color_param           aca9a4
set -gx fish_color_comment         aca9a4
set -gx fish_color_operator        96ada7
set -gx fish_color_escape          b6927b
set -gx fish_color_autosuggestion  5a5a5a
set -gx fish_color_selection       --background=363646
set -gx fish_color_search_match    --background=363646
set -gx fish_color_cancel          cc928e
set -gx fish_color_option          d4c196

# === Интерактивные настройки ===
if status is-interactive
    # Приветствие — fastfetch при открытии терминала
    #fastfetch --config ~/.config/hypr/kanagawa-paper/fastfetch/config.jsonc

    # Отключить дефолтный fish-greeting (логотип fish)
    set -U fish_greeting

    # Алиасы
    alias ls='lsd --tree --group-dirs=first --depth 1'
end

# === Быстрое редактирование конфига kitty (не идти по симлинкам) ===
function edit-kitty
    nvim ~/.config/hypr/kanagawa-paper/kitty/kitty.conf
end

# === Автозапуск Hyprland на tty1 ===
if status is-login
    if test -z "$DISPLAY" -a "$(tty)" = /dev/tty1
        exec start-hyprland
    end
end
