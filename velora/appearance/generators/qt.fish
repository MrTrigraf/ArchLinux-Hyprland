# ============================================================
# Генератор: qt5ct и qt6ct
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет:
#   velora/appearance/qt/qt5ct/colors/velora.conf
#   velora/appearance/qt/qt6ct/colors/velora.conf
# Файлы не коммитятся в git.
#
# Порядок ролей — QPalette::ColorRole (Qt 6.12, qpalette.h):
#   WindowText, Button, Light, Midlight, Dark, Mid, Text, BrightText,
#   ButtonText, Base, Window, Shadow, Highlight, HighlightedText, Link,
#   LinkVisited, AlternateBase, ToolTipBase, ToolTipText, PlaceholderText,
#   Accent.
# qt5ct читает первые 20 ролей (без Accent), qt6ct — все 21.
#
# Мэппинг:
#   фон / текст        = background / foreground
#   поверхности        = selection_background
#   выделение          = accent / background
#   ссылки             = url_color (фолбэк: accent)
#   placeholder        = color8
#   error (BrightText) = color1
# ============================================================

# _qt_argb <#RRGGBB> — цвет Qt в формате #AARRGGBB
function _qt_argb
    set -l hex (string sub -s 2 -- "$argv[1]")
    printf '#ff%s' $hex
end

function _gen_qt
    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l bg (_theme_color background)
    set -l fg (_theme_color foreground)
    set -l sel_bg (_theme_color selection_background)
    set -l sel_fg (_theme_color selection_foreground)
    set -l url (_theme_color url_color)
    set -l c1 (_theme_color color1)
    set -l c8 (_theme_color color8)
    set -l accent (_theme_color $accent_key)

    if test -z "$sel_bg"
        set sel_bg $bg
    end
    if test -z "$sel_fg"
        set sel_fg $fg
    end
    if test -z "$url"
        set url $accent
    end

    for c in $bg $fg $sel_bg $sel_fg $url $c1 $c8 $accent
        if not string match -qr -- '^#[0-9a-fA-F]{6}$' "$c"
            echo "Ошибка [qt]: неверный цвет '$c'" >&2
            return 1
        end
    end

    # 21 роль в порядке QPalette::ColorRole
    set -l active \
        $fg $sel_bg $sel_bg $sel_bg $bg $sel_bg \
        $fg $c1 $fg \
        $bg $bg $bg \
        $accent $bg \
        $url $url \
        $sel_bg \
        $fg $bg \
        $c8 \
        $accent

    set -l disabled \
        $sel_fg $bg $sel_bg $sel_bg $bg $sel_bg \
        $sel_fg $c1 $sel_fg \
        $bg $bg $bg \
        $sel_bg $sel_fg \
        $url $url \
        $sel_bg \
        $sel_fg $bg \
        $sel_fg \
        $sel_fg

    if test (count $active) -ne 21; or test (count $disabled) -ne 21
        printf 'Ошибка [qt]: ожидалось 21 цвет, получено %d/%d\n' (count $active) (count $disabled) >&2
        return 1
    end

    set -l active_argb
    set -l disabled_argb
    set -l inactive_argb
    for c in $active
        set -a active_argb (_qt_argb $c)
    end
    for c in $disabled
        set -a disabled_argb (_qt_argb $c)
    end
    for c in $active
        set -a inactive_argb (_qt_argb $c)
    end

    set -l lines
    set -a lines '[ColorScheme]'
    set -a lines 'active_colors='(string join ', ' $active_argb)
    set -a lines 'disabled_colors='(string join ', ' $disabled_argb)
    set -a lines 'inactive_colors='(string join ', ' $inactive_argb)

    for tool in qt5ct qt6ct
        set -l dir $VELORA_ROOT/appearance/qt/$tool/colors
        mkdir -p -- $dir
        or return 1
        _theme_write $dir/velora.conf $lines
        or begin
            echo "Ошибка [qt]: не удалось записать $dir/velora.conf" >&2
            return 1
        end
        echo "  [qt] $dir/velora.conf"
    end
end
