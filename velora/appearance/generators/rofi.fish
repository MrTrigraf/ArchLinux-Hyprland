# ============================================================
# Генератор: rofi/colors.rasi
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет velora/rofi/colors.rasi — файл
# не коммитится в git.
#
# Мэппинг (переменная rofi -> ключ theme.conf):
#   fg           = foreground
#   fg-subtle    = color8
#   fg-muted     = selection_foreground (фолбэк: foreground)
#   accent       = <accent> из метаданных (дефолт color4)
#   fg-on-accent = background
#   edge         = foreground, alpha 0.30
#   edge-strong  = foreground, alpha 0.50
#   bg-input     = selection_background (фолбэк: background), alpha 0.60
#   bg-window    = selection_background (фолбэк: background), alpha 0.95
#   bg-modi-idle = selection_background (фолбэк: background)
# ============================================================

function _gen_rofi
    set -l dir $VELORA_ROOT/rofi
    mkdir -p -- $dir
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l bg (_theme_color background)
    set -l fg (_theme_color foreground)
    set -l sel_bg (_theme_color selection_background)
    set -l sel_fg (_theme_color selection_foreground)
    if test -z "$sel_bg"
        set sel_bg $bg
    end
    if test -z "$sel_fg"
        set sel_fg $fg
    end

    set -l subtle (_theme_color color8)
    set -l accent (_theme_color $accent_key)

    # Любой пустой цвет дал бы битый .rasi — прерываемся до записи
    set -l bg_window (_theme_rgba $sel_bg 0.95)
    and set -l bg_input (_theme_rgba $sel_bg 0.60)
    and set -l edge (_theme_rgba $fg 0.30)
    and set -l edge_strong (_theme_rgba $fg 0.50)
    or begin
        echo "Ошибка [rofi]: не удалось получить цвета из темы" >&2
        return 1
    end
    for c in $fg $subtle $sel_fg $accent $bg $sel_bg
        if not string match -qr -- '^#[0-9a-fA-F]{6}$' "$c"
            echo "Ошибка [rofi]: неверный цвет '$c'" >&2
            return 1
        end
    end

    set -l lines
    set -a lines '/*'
    set -a lines ' * colors.rasi — сгенерирован командой theme set, править руками нельзя.'
    set -a lines ' * Источник: velora/themes/current/theme.conf'
    set -a lines ' */'
    set -a lines ''
    set -a lines '* {'
    set -a lines "    bg-window:        $bg_window;"
    set -a lines "    edge:             $edge;"
    set -a lines "    edge-strong:      $edge_strong;"
    set -a lines "    bg-input:         $bg_input;"
    set -a lines "    bg-modi-idle:     $sel_bg;"
    set -a lines "    fg:               $fg;"
    set -a lines "    fg-subtle:        $subtle;"
    set -a lines "    fg-muted:         $sel_fg;"
    set -a lines "    accent:           $accent;"
    set -a lines "    fg-on-accent:     $bg;"
    set -a lines '    background-color: transparent;'
    set -a lines '    text-color:       @fg;'
    set -a lines '}'

    _theme_write $dir/colors.rasi $lines
    or begin
        echo "Ошибка [rofi]: не удалось записать $dir/colors.rasi" >&2
        return 1
    end
    echo "  [rofi] $dir/colors.rasi"
end
