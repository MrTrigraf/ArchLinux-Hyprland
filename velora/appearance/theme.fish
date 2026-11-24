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
set -g THEME_SCRIPT $script

# Производные файлы: _theme_set откатывает их при сбое генератора.
# Новый генератор добавляет свой выходной файл сюда.
# hypr/wallpaper.lua — генератора пока нет; файл может отсутствовать.
set -g THEME_DERIVED_FILES \
    $VELORA_ROOT/hypr/theme.lua \
    $VELORA_ROOT/hypr/wallpaper.lua \
    $VELORA_ROOT/rofi/colors.rasi \
    $VELORA_ROOT/hyprlock/theme.colors \
    $VELORA_ROOT/hyprlock/wallpaper.conf \
    $VELORA_ROOT/cmus/current.theme \
    $VELORA_ROOT/btop/themes/velora.theme \
    $VELORA_ROOT/appearance/gtk/gtk-3.0/gtk.css \
    $VELORA_ROOT/appearance/gtk/gtk-4.0/gtk.css \
    $VELORA_ROOT/appearance/qt/qt5ct/colors/velora.conf \
    $VELORA_ROOT/appearance/qt/qt6ct/colors/velora.conf

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

# ── Транзакция переключения темы ─────────────────────────

# _theme_snapshot <папка> — копирует существующие производные файлы в <папка>/files/N
function _theme_snapshot
    set -l dir $argv[1]
    mkdir -p -- $dir/files
    or return 1

    for i in (seq (count $THEME_DERIVED_FILES))
        set -l file $THEME_DERIVED_FILES[$i]
        if test -f $file
            cp -p -- $file $dir/files/$i
            or return 1
        end
    end
    return 0
end

# _theme_restore <папка> [старая_цель] — возвращает симлинк и производные файлы.
# Файл, которого не было в снимке, удаляется. Возвращает 1 при любом сбое.
function _theme_restore
    set -l dir $argv[1]
    set -l old_target $argv[2]
    set -l failed 0

    if test -n "$old_target"
        set -l tmp $THEME_LINK.restore.$fish_pid
        if not ln -s -- $old_target $tmp; or not mv -Tf -- $tmp $THEME_LINK
            rm -f -- $tmp
            set failed 1
        end
    else
        rm -f -- $THEME_LINK
        or set failed 1
    end

    for i in (seq (count $THEME_DERIVED_FILES))
        set -l file $THEME_DERIVED_FILES[$i]
        if test -f $dir/files/$i
            cp -p -- $dir/files/$i $file
            or set failed 1
        else
            rm -f -- $file
            or set failed 1
        end
    end

    return $failed
end

# _theme_cleanup <папка> — удаляет только временный каталог velora-theme.*
function _theme_cleanup
    if string match -q -- '*/velora-theme.*' "$argv[1]"
        rm -rf -- $argv[1]
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

    set -l old_target
    if test -L $THEME_LINK
        set old_target (readlink -- $THEME_LINK)
    end

    set -l snapshot (mktemp -d --tmpdir velora-theme.XXXXXX)
    if test -z "$snapshot"
        echo "Ошибка: не удалось создать временный каталог" >&2
        return 1
    end
    if not _theme_snapshot $snapshot
        _theme_cleanup $snapshot
        echo "Ошибка: не удалось сохранить производные файлы" >&2
        return 1
    end

    # Атомарная замена: новый симлинк под временным именем, затем mv -T
    set -l tmp $THEME_LINK.new.$fish_pid
    if not ln -s -- $name $tmp; or not mv -Tf -- $tmp $THEME_LINK
        rm -f -- $tmp
        _theme_cleanup $snapshot
        echo "Ошибка: не удалось заменить симлинк $THEME_LINK" >&2
        return 1
    end

    echo "Переключаю тему: $name"
    if not _theme_generate $name
        echo "Ошибка: генерация не удалась, откат к прежней теме" >&2
        if not _theme_restore $snapshot $old_target
            echo "Критическая ошибка: откат не удался, снимок: $snapshot" >&2
            return 1
        end
        _theme_cleanup $snapshot
        if test -n "$old_target"
            echo "Тема возвращена: $old_target" >&2
        else
            echo "Активной темы нет, симлинк удалён" >&2
        end
        return 1
    end

    _theme_cleanup $snapshot
    echo "Активна тема: $name"
    _theme_reload_live
    return 0
end

# _theme_reload_live — перечитывает конфиги запущенных программ, которые
# умеют это без перезапуска. Процессы не завершаются.
#   kitty: SIGUSR1 перечитывает kitty.conf вместе с include
#          (sw.kovidgoyal.net/kitty/conf: «sending kitty the SIGUSR1 signal»).
#   Hyprland: сам перечитывает hyprland.lua и theme.lua при изменении файлов.
#   GTK 4: gtk.css читается один раз при старте приложения (gtk/gtksettings.c),
#          поэтому запущенные приложения получат тему после перезапуска.
# Сбой здесь не меняет результат theme set: тема уже применена.
function _theme_reload_live
    if command -q pkill
        pkill -USR1 -x kitty
        or true
    end
    echo "GTK-приложения применят тему после перезапуска"
    return 0
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

# _theme_set_locked <имя> — выполняет theme set под блокировкой flock.
# Две одновременные смены иначе перезаписывают общие файлы и симлинк друг
# друга. Схема как в omarchy-theme-set: файл блокировки в $XDG_RUNTIME_DIR.
# Вторая смена ждёт до 60 с. Внутри блокировки скрипт запускает сам себя
# с VELORA_THEME_LOCKED=1, чтобы не взять блокировку повторно.
function _theme_set_locked
    if set -q VELORA_THEME_LOCKED
        _theme_set $argv[1]
        return $status
    end
    if not command -q flock
        echo "Предупреждение: flock не найден, смена темы без блокировки" >&2
        _theme_set $argv[1]
        return $status
    end

    set -l dir /tmp
    if test -n "$XDG_RUNTIME_DIR"
        set dir $XDG_RUNTIME_DIR
    end
    flock -w 60 -E 75 $dir/velora-theme-set.lock \
        env VELORA_THEME_LOCKED=1 fish $THEME_SCRIPT set $argv[1]
    set -l rc $status
    if test $rc -eq 75
        echo "Ошибка: другая смена темы не завершилась за 60 с" >&2
    end
    return $rc
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
            _theme_set_locked $argv[2]
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
