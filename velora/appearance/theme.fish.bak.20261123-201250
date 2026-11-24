#!/usr/bin/env fish
# ============================================================
# theme — менеджер тем velora.
#
#   list           — список тем (* = активная)
#   current        — имя активной темы
#   set <name>     — проверка и переключение темы
#   check [name]   — проверка формата темы (по умолчанию — current)
# ============================================================

# ── Пути ─────────────────────────────────────────────────
set -l script (path resolve (status filename))
if test -z "$script"
    echo "Ошибка: не удалось определить путь к скрипту" >&2
    exit 1
end

set -l lib (path dirname $script)/theme_lib.fish
if not test -f $lib
    echo "Ошибка: нет $lib" >&2
    exit 1
end

set -g VELORA_ROOT (path dirname (path dirname $script))
set -g THEME_ROOT $VELORA_ROOT/themes
set -g THEME_LINK $THEME_ROOT/current

if not test -d $THEME_ROOT
    echo "Ошибка: нет папки тем $THEME_ROOT" >&2
    exit 1
end

source $lib

# Генераторы производных файлов: каждый generators/*.fish определяет
# функцию _gen_<потребитель>; _theme_generate вызывает их все.
for gen_file in (path dirname $script)/generators/*.fish
    source $gen_file
end

# ── Вспомогательные ──────────────────────────────────────

# _theme_valid_name <имя> — имя папки темы без путей; "current" зарезервировано
function _theme_valid_name
    string match -qr -- '^[A-Za-z0-9][A-Za-z0-9._-]*$' "$argv[1]"
    and test "$argv[1]" != current
end

# ── check ────────────────────────────────────────────────

function _theme_check
    set -l name $argv[1]
    if not _theme_valid_name "$name"
        echo "Ошибка: недопустимое имя темы '$name'" >&2
        return 1
    end

    set -l dir $THEME_ROOT/$name
    if not test -d $dir
        echo "Ошибка: нет темы '$name' в $THEME_ROOT" >&2
        return 1
    end
    _theme_parse $dir
    or return 1

    set -l errors

    # 16 цветов палитры + background/foreground
    set -l required background foreground
    for i in (seq 0 15)
        set -a required color$i
    end
    for key in $required
        if not _theme_has_color $key
            set -a errors "нет цвета $key"
        end
    end

    # Метаданные name совпадают с именем папки
    set -l tname (_theme_meta name)
    if test -z "$tname"
        set -a errors "нет метаданных 'name'"
    else if test "$tname" != "$name"
        set -a errors "метаданные 'name' ('$tname') не совпадают с папкой ('$name')"
    end

    # accent: по умолчанию color4; должен быть colorN (0–17) из палитры
    set -l accent (_theme_meta accent)
    if test -z "$accent"
        set accent color4
    end
    set -l am (string match -r -- '^color(\d+)$' $accent)
    if test (count $am) -ne 2
        set -a errors "accent должен ссылаться на colorN, получено '$accent'"
    else if test $am[2] -gt 17
        set -a errors "номер цвета для accent вне диапазона (0–17): $accent"
    else if not _theme_has_color $accent
        set -a errors "accent указывает на несуществующий цвет $accent"
    end

    # wallpaper: файл в wallpapers/ темы, без вложенных путей
    set -l wall (_theme_meta wallpaper)
    if test -z "$wall"
        set -a errors "нет метаданных 'wallpaper'"
    else if string match -q -- '*/*' $wall
        set -a errors "wallpaper должен быть именем файла без '/': '$wall'"
    else if not test -f $dir/wallpapers/$wall
        set -a errors "нет файла обоев $dir/wallpapers/$wall"
    end

    if test (count $errors) -eq 0
        echo "OK: тема '$name' прошла проверку"
        return 0
    end

    for e in $errors
        echo "Ошибка: $e" >&2
    end
    echo "Тема '$name': ошибок — "(count $errors) >&2
    return 1
end

# ── current / list / set ─────────────────────────────────

function _theme_current
    if not test -L $THEME_LINK
        echo "Ошибка: активной темы нет (нет симлинка $THEME_LINK)" >&2
        return 1
    end
    path basename (path resolve $THEME_LINK)
end

function _theme_list
    set -l active (_theme_current 2>/dev/null)
    echo "Доступные темы:"
    for conf in $THEME_ROOT/*/theme.conf
        set -l name (path basename (path dirname $conf))
        if test "$name" = current
            continue
        end
        if test -n "$active"; and test "$name" = "$active"
            echo "* $name (активна)"
        else
            echo "  $name"
        end
    end
end

function _theme_set
    set -l name $argv[1]
    if test -z "$name"
        echo "Использование: theme set <имя_темы>" >&2
        return 1
    end
    if not _theme_check $name
        echo "Тема '$name' не прошла проверку — переключение отменено" >&2
        return 1
    end
    # Если themes/current — реальная папка, замена симлинка невозможна
    if test -e $THEME_LINK; and not test -L $THEME_LINK
        echo "Ошибка: $THEME_LINK существует и не является симлинком" >&2
        return 1
    end

    # Атомарная замена: новый симлинк под временным именем, затем mv -T
    set -l tmp $THEME_LINK.new.$fish_pid
    if not ln -s -- $name $tmp
        echo "Ошибка: не удалось создать симлинк $tmp" >&2
        return 1
    end
    if not mv -Tf -- $tmp $THEME_LINK
        rm -f -- $tmp
        echo "Ошибка: не удалось заменить симлинк $THEME_LINK" >&2
        return 1
    end

    echo "Активна тема: $name"
    _theme_generate $name
end

# Генерация производных файлов: проверяет и заново разбирает тему,
# затем вызывает все загруженные генераторы _gen_*.
# Сбой одного генератора не отменяет остальные.
function _theme_generate
    set -l name $argv[1]
    if test -z "$name"
        echo "Ошибка: _theme_generate требует имя темы" >&2
        return 1
    end

    _theme_check $name >/dev/null
    or return 1

    set -l failed
    # --all: без него functions скрывает имена с префиксом _
    set -l gens (functions --all --names | string match -r '^_gen_\w+$' | sort)
    if test (count $gens) -eq 0
        echo "Ошибка: не найдено ни одного генератора _gen_*" >&2
        return 1
    end
    for gen in $gens
        if not $gen
            set -a failed $gen
        end
    end

    if test (count $failed) -gt 0
        echo "Ошибка: сбой генераторов: $failed" >&2
        return 1
    end
    echo "Сгенерированы производные файлы (тема: $name)"
end

# ── Диспетчер ────────────────────────────────────────────

function _theme_usage
    echo "Использование: theme <list | current | set <имя> | check [имя]>"
end

function _theme_main
    if test (count $argv) -eq 0
        _theme_usage >&2
        return 1
    end

    switch $argv[1]
        case list
            _theme_list
        case current
            _theme_current
        case set
            _theme_set $argv[2]
        case check
            set -l name $argv[2]
            if test -z "$name"
                set name (_theme_current)
                or return 1
            end
            _theme_check $name
        case '*'
            _theme_usage >&2
            return 1
    end
end

_theme_main $argv
exit $status
