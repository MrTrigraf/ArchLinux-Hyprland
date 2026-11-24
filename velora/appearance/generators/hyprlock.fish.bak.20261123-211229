# ============================================================
# Генератор: hyprlock/theme.colors
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет velora/hyprlock/theme.colors —
# hyprlang-переменные для hyprlock.conf (source =, этап 1).
# Не коммитится в git.
#
# Формат (проверен на hyprlang 0.6.8, hyprlock 0.9.7):
#   $имя = rgb(RRGGBB)  — цвет для color / inner_color и т. д.
#   $имя_hex = ##RRGGBB — цвет для Pango-разметки в тексте
# Знак # в hyprlang начинает комментарий, поэтому в значении
# он удваивается: ## даёт один #.
#
# Мэппинг (переменная hyprlock -> ключ theme.conf):
#   v_fg        = foreground
#   v_fg_subtle = color8
#   v_accent    = <accent> из метаданных (дефолт color4)
#   v_check     = color3  — "проверяем"
#   v_fail      = color9  — неверный пароль
#   v_caps      = color11 — рамка Caps Lock
#   v_layout    = color12 — индикатор раскладки
# ============================================================

function _gen_hyprlock
    set -l dir $VELORA_ROOT/hyprlock
    mkdir -p -- $dir
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l names v_fg v_fg_subtle v_accent v_check v_fail v_caps v_layout
    set -l keys foreground color8 $accent_key color3 color9 color11 color12

    set -l rgb_lines
    set -l hex_lines
    for i in (seq (count $names))
        set -l hex (_theme_color $keys[$i])
        if not string match -qr -- '^#[0-9a-fA-F]{6}$' "$hex"
            echo "Ошибка [hyprlock]: нет цвета $keys[$i] для $names[$i]" >&2
            return 1
        end
        set -l digits (string sub -s 2 -- $hex)
        set -a rgb_lines (printf '$%-15s = rgb(%s)' $names[$i] $digits)
        set -a hex_lines (printf '$%-15s = ##%s' {$names[$i]}_hex $digits)
    end

    set -l lines
    set -a lines '# theme.colors — сгенерирован командой theme set, править руками нельзя.'
    set -a lines '# Источник: velora/themes/current/theme.conf'
    set -a lines ''
    set -a lines $rgb_lines
    set -a lines ''
    set -a lines '# Для Pango-разметки (<span foreground=...>)'
    set -a lines $hex_lines

    _theme_write $dir/theme.colors $lines
    or begin
        echo "Ошибка [hyprlock]: не удалось записать $dir/theme.colors" >&2
        return 1
    end
    echo "  [hyprlock] $dir/theme.colors"
end
