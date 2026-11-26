# ============================================================
# theme_lib.fish — общий парсер theme.conf для velora.
#
# Подключается из theme.fish и файлов генераторов.
# Логика путей здесь отсутствует: путь к теме передаёт вызывающий.
#
# Использование:
#   source <velora>/appearance/theme_lib.fish
#   _theme_parse <папка_темы>
#
# После успешного _theme_parse заполнены глобальные переменные:
#   THEME_COLOR_<ключ> = #RRGGBB  (background, foreground, color0..)
#   THEME_META_<ключ>  = значение (name, variant, accent, nvim, wallpaper)
#
# Функции:
#   _theme_parse <папка>   — разбор theme.conf; 0 — успех, 1 — ошибка
#   _theme_meta <ключ>     — печатает значение метаданных (или ничего)
#   _theme_color <ключ>    — печатает hex цвета (или ничего)
#   _theme_has_color <ключ> — код возврата 0, если цвет задан
# ============================================================

function _theme_parse
    if test (count $argv) -eq 0; or test -z "$argv[1]"
        echo "Ошибка: _theme_parse требует путь к папке темы" >&2
        return 1
    end

    set -l conf $argv[1]/theme.conf

    # Чистим значения от предыдущего разбора до любых проверок:
    # при ошибке старая тема не должна оставаться в памяти
    for var in (set --names --global | string match -r '^THEME_(?:COLOR|META)_.+')
        set -e -g $var
    end

    if not test -f $conf
        echo "Ошибка: нет $conf" >&2
        return 1
    end

    # Допустимые ключи метаданных; неизвестный ключ — ошибка, а не пропуск
    set -l meta_keys name variant accent nvim wallpaper

    # Именованные цветовые ключи kitty.
    # Источник: /usr/share/doc/kitty/kitty.conf, раздел Color scheme.
    # color0..color255 проверяются отдельно.
    set -l color_keys \
        background foreground \
        selection_background selection_foreground \
        cursor cursor_text_color cursor_trail_color \
        url_color visual_bell_color \
        active_border_color inactive_border_color bell_border_color \
        window_title_bar_active_foreground window_title_bar_active_background \
        window_title_bar_inactive_foreground window_title_bar_inactive_background \
        tab_bar_background tab_bar_margin_color \
        active_tab_background active_tab_foreground \
        inactive_tab_background inactive_tab_foreground \
        mark1_foreground mark1_background \
        mark2_foreground mark2_background \
        mark3_foreground mark3_background

    for line in (cat $conf)
        set line (string trim -- $line)
        if test -z "$line"
            continue
        end

        if string match -q -- '##*' $line
            # Метаданные: ## ключ = значение
            set -l m (string match -r -- '^##\s*(\w+)\s*=\s*(.*)$' $line)
            if test (count $m) -eq 3; and contains -- $m[2] $meta_keys
                set -g THEME_META_$m[2] (string trim -- "$m[3]")
            else
                echo "Ошибка: нераспознана строка в $conf: $line" >&2
                return 1
            end
        else if string match -q -- '#*' $line
            # Одиночный # — комментарий kitty
            continue
        else
            # Цвет: <ключ> #RRGGBB
            set -l m (string match -r -- '^(\w+)\s+(#[0-9a-fA-F]{6})$' $line)
            if test (count $m) -ne 3
                echo "Ошибка: нераспознана строка в $conf: $line" >&2
                return 1
            end

            set -l key $m[2]
            set -l num (string match -r -- '^color(0|[1-9][0-9]{0,2})$' $key)
            if contains -- $key $color_keys
                set -g THEME_COLOR_$key $m[3]
            else if test (count $num) -eq 2
                if test "$num[2]" -gt 255
                    echo "Ошибка: номер цвета вне диапазона 0–255 в $conf: $line" >&2
                    return 1
                end
                set -g THEME_COLOR_$key $m[3]
            else
                echo "Ошибка: неизвестный ключ цвета в $conf: $line" >&2
                return 1
            end
        end
    end
    return 0
end

# _theme_get <префикс> <ключ> — общий доступ к THEME_<префикс>_<ключ>
function _theme_get
    string match -qr -- '^\w+$' $argv[2]
    or return 1

    set -l var THEME_$argv[1]_$argv[2]
    if set -q $var
        printf '%s\n' $$var
    end
end

function _theme_meta
    _theme_get META $argv[1]
end

function _theme_color
    _theme_get COLOR $argv[1]
end

function _theme_has_color
    string match -qr -- '^\w+$' $argv[1]
    or return 1

    set -q THEME_COLOR_$argv[1]
end

# _theme_rgba <#RRGGBB> <alpha> — печатает "rgba(R, G, B, A)"
function _theme_rgba
    set -l hex (string replace -- '#' '' "$argv[1]")
    if not string match -qr -- '^[0-9a-fA-F]{6}$' $hex
        echo "Ошибка: неверный цвет '$argv[1]'" >&2
        return 1
    end
    if not string match -qr -- '^[01](\.\d+)?$' "$argv[2]"
        echo "Ошибка: неверная прозрачность '$argv[2]'" >&2
        return 1
    end

    set -l r (string sub -s 1 -l 2 -- $hex)
    set -l g (string sub -s 3 -l 2 -- $hex)
    set -l b (string sub -s 5 -l 2 -- $hex)
    printf 'rgba(%d, %d, %d, %s)\n' 0x$r 0x$g 0x$b $argv[2]
end

# _theme_write <файл> <строки...> — запись через временный файл и mv:
# читатель никогда не увидит наполовину записанный файл
function _theme_write
    set -l target $argv[1]
    set -l tmp $target.new.$fish_pid

    printf '%s\n' $argv[2..-1] >$tmp
    and mv -Tf -- $tmp $target
    and return 0

    rm -f -- $tmp
    return 1
end
