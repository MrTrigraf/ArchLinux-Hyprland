# ============================================================
# Генератор: velora/hypr/theme.lua
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет Lua-модуль с цветами Hyprland.
# Файл не коммитится в git.
#
# Мэппинг:
#   active_border   = color14 + accent + color3 (три цвета, angle 45)
#   inactive_border = selection_background, alpha 66
#   shadow          = background, alpha ee
# ============================================================

# _hypr_rgba <#RRGGBB> <AA> — цвет Hyprland в формате rgba(RRGGBBAA)
function _hypr_rgba
    set -l hex (string sub -s 2 -- "$argv[1]")
    if not string match -qr -- '^[0-9a-fA-F]{6}$' "$hex"
        echo "Ошибка [hyprland]: неверный цвет '$argv[1]'" >&2
        return 1
    end
    if not string match -qr -- '^[0-9a-fA-F]{2}$' "$argv[2]"
        echo "Ошибка [hyprland]: неверная прозрачность '$argv[2]'" >&2
        return 1
    end
    printf 'rgba(%s%s)' $hex $argv[2]
end

function _gen_hyprland
    set -l dir $VELORA_ROOT/hypr
    mkdir -p -- $dir
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l bg (_theme_color background)
    set -l sel_bg (_theme_color selection_background)
    set -l c14 (_theme_color color14)
    set -l accent (_theme_color $accent_key)
    set -l c3 (_theme_color color3)

    if test -z "$sel_bg"
        set sel_bg $bg
    end

    for c in $bg $sel_bg $c14 $accent $c3
        if not string match -qr -- '^#[0-9a-fA-F]{6}$' "$c"
            echo "Ошибка [hyprland]: неверный цвет '$c'" >&2
            return 1
        end
    end

    set -l active_a (_hypr_rgba $c14 ff)
    and set -l active_b (_hypr_rgba $accent ee)
    and set -l active_c (_hypr_rgba $c3 cc)
    and set -l inactive (_hypr_rgba $sel_bg 66)
    or begin
        echo "Ошибка [hyprland]: не удалось вычислить цвета" >&2
        return 1
    end

    set -l bg_digits (string sub -s 2 -- $bg)
    set -l shadow "0xee$bg_digits"

    set -l lines
    set -a lines '-- theme.lua — сгенерирован командой theme set, править руками нельзя.'
    set -a lines '-- Источник: velora/themes/current/theme.conf'
    set -a lines 'return {'
    set -a lines "    active_border = { colors = { \"$active_a\", \"$active_b\", \"$active_c\" }, angle = 45 },"
    set -a lines "    inactive_border = \"$inactive\","
    set -a lines "    shadow = \"$shadow\","
    set -a lines '}'

    _theme_write $dir/theme.lua $lines
    or begin
        echo "Ошибка [hyprland]: не удалось записать $dir/theme.lua" >&2
        return 1
    end
    echo "  [hyprland] $dir/theme.lua"
end
