# ============================================================
# Генератор: GTK 3 и GTK 4
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет:
#   velora/appearance/gtk/gtk-3.0/gtk.css
#   velora/appearance/gtk/gtk-4.0/gtk.css
# Файлы не коммитятся в git.
#
# Мэппинг:
#   фон / текст               = background / foreground
#   выделение                 = accent / background
#   headerbar                 = color0
#   popover                   = selection_background
#   error / warning / success = color1 / color3 / color2
#   borders и shade           = foreground с прозрачностью
# ============================================================

function _gen_gtk
    set -l dir $VELORA_ROOT/appearance/gtk
    mkdir -p -- $dir/gtk-3.0 $dir/gtk-4.0
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    set -l bg (_theme_color background)
    set -l fg (_theme_color foreground)
    set -l sel_bg (_theme_color selection_background)
    set -l accent (_theme_color $accent_key)
    set -l c0 (_theme_color color0)
    set -l c1 (_theme_color color1)
    set -l c2 (_theme_color color2)
    set -l c3 (_theme_color color3)

    if test -z "$sel_bg"
        set sel_bg $bg
    end

    for c in $bg $fg $sel_bg $accent $c0 $c1 $c2 $c3
        if not string match -qr -- '^#[0-9a-fA-F]{6}$' "$c"
            echo "Ошибка [gtk]: неверный цвет '$c'" >&2
            return 1
        end
    end

    set -l insens (_theme_rgba $fg 0.50)
    and set -l borders (_theme_rgba $fg 0.18)
    and set -l borders_dim (_theme_rgba $fg 0.12)
    and set -l shadow (_theme_rgba $fg 0.20)
    or begin
        echo "Ошибка [gtk]: не удалось вычислить прозрачные цвета" >&2
        return 1
    end

    set -l lines
    set -a lines '/* gtk.css — сгенерирован командой theme set, править руками нельзя. */'
    set -a lines '/* Источник: velora/themes/current/theme.conf */'
    set -a lines ''
    set -a lines "@define-color theme_bg_color $bg;"
    set -a lines "@define-color theme_fg_color $fg;"
    set -a lines "@define-color theme_base_color $bg;"
    set -a lines "@define-color theme_text_color $fg;"
    set -a lines "@define-color theme_selected_bg_color $accent;"
    set -a lines "@define-color theme_selected_fg_color $bg;"
    set -a lines "@define-color insensitive_bg_color $bg;"
    set -a lines "@define-color insensitive_fg_color $insens;"
    set -a lines "@define-color insensitive_base_color $bg;"
    set -a lines "@define-color theme_unfocused_bg_color $bg;"
    set -a lines "@define-color theme_unfocused_fg_color $fg;"
    set -a lines "@define-color theme_unfocused_base_color $bg;"
    set -a lines "@define-color theme_unfocused_text_color $fg;"
    set -a lines "@define-color theme_unfocused_selected_bg_color $accent;"
    set -a lines "@define-color theme_unfocused_selected_fg_color $bg;"
    set -a lines "@define-color unfocused_insensitive_color $insens;"
    set -a lines "@define-color borders $borders;"
    set -a lines "@define-color unfocused_borders $borders_dim;"
    set -a lines "@define-color warning_color $c3;"
    set -a lines "@define-color error_color $c1;"
    set -a lines "@define-color success_color $c2;"
    set -a lines "@define-color window_bg_color $bg;"
    set -a lines "@define-color window_fg_color $fg;"
    set -a lines "@define-color view_bg_color $bg;"
    set -a lines "@define-color view_fg_color $fg;"
    set -a lines "@define-color headerbar_bg_color $c0;"
    set -a lines "@define-color headerbar_fg_color $fg;"
    set -a lines "@define-color headerbar_border_color $borders_dim;"
    set -a lines "@define-color headerbar_backdrop_color $bg;"
    set -a lines "@define-color headerbar_shade_color $borders_dim;"
    set -a lines "@define-color card_bg_color $bg;"
    set -a lines "@define-color card_fg_color $fg;"
    set -a lines "@define-color card_shade_color $borders_dim;"
    set -a lines "@define-color dialog_bg_color $bg;"
    set -a lines "@define-color dialog_fg_color $fg;"
    set -a lines "@define-color popover_bg_color $sel_bg;"
    set -a lines "@define-color popover_fg_color $fg;"
    set -a lines "@define-color accent_bg_color $accent;"
    set -a lines "@define-color accent_fg_color $bg;"
    set -a lines "@define-color accent_color $accent;"
    set -a lines "@define-color destructive_bg_color $c1;"
    set -a lines "@define-color destructive_fg_color $fg;"
    set -a lines "@define-color destructive_color $c1;"
    set -a lines "@define-color success_bg_color $c2;"
    set -a lines "@define-color success_fg_color $fg;"
    set -a lines "@define-color warning_bg_color $c3;"
    set -a lines "@define-color warning_fg_color $fg;"
    set -a lines "@define-color error_bg_color $c1;"
    set -a lines "@define-color error_fg_color $fg;"
    set -a lines "@define-color shade_color $borders_dim;"
    set -a lines "@define-color scrollbar_outline_color $borders_dim;"

    _theme_write $dir/gtk-3.0/gtk.css $lines
    or begin
        echo "Ошибка [gtk]: не удалось записать $dir/gtk-3.0/gtk.css" >&2
        return 1
    end
    echo "  [gtk] $dir/gtk-3.0/gtk.css"

    set -l lines4
    set -a lines4 ':root {'
    set -a lines4 "  --window-bg-color: $bg;"
    set -a lines4 "  --window-fg-color: $fg;"
    set -a lines4 "  --view-bg-color: $bg;"
    set -a lines4 "  --view-fg-color: $fg;"
    set -a lines4 "  --sidebar-bg-color: $bg;"
    set -a lines4 "  --sidebar-fg-color: $fg;"
    set -a lines4 "  --headerbar-bg-color: $c0;"
    set -a lines4 "  --headerbar-fg-color: $fg;"
    set -a lines4 "  --headerbar-backdrop-color: $bg;"
    set -a lines4 "  --headerbar-shade-color: $borders_dim;"
    set -a lines4 "  --sidebar-backdrop-color: $bg;"
    set -a lines4 "  --sidebar-shade-color: $borders_dim;"
    set -a lines4 "  --popover-bg-color: $sel_bg;"
    set -a lines4 "  --popover-fg-color: $fg;"
    set -a lines4 "  --popover-shade-color: $borders_dim;"
    set -a lines4 "  --card-bg-color: $bg;"
    set -a lines4 "  --card-fg-color: $fg;"
    set -a lines4 "  --card-shade-color: $borders_dim;"
    set -a lines4 "  --dialog-bg-color: $bg;"
    set -a lines4 "  --dialog-fg-color: $fg;"
    set -a lines4 "  --thumbnail-bg-color: $bg;"
    set -a lines4 "  --thumbnail-fg-color: $fg;"
    set -a lines4 "  --accent-bg-color: $accent;"
    set -a lines4 "  --accent-fg-color: $bg;"
    set -a lines4 "  --accent-color: $accent;"
    set -a lines4 "  --destructive-bg-color: $c1;"
    set -a lines4 "  --destructive-fg-color: $fg;"
    set -a lines4 "  --destructive-color: $c1;"
    set -a lines4 "  --success-bg-color: $c2;"
    set -a lines4 "  --success-fg-color: $fg;"
    set -a lines4 "  --success-color: $c2;"
    set -a lines4 "  --warning-bg-color: $c3;"
    set -a lines4 "  --warning-fg-color: $fg;"
    set -a lines4 "  --warning-color: $c3;"
    set -a lines4 "  --error-bg-color: $c1;"
    set -a lines4 "  --error-fg-color: $fg;"
    set -a lines4 "  --error-color: $c1;"
    set -a lines4 "  --shade-color: $borders_dim;"
    set -a lines4 "  --scrollbar-outline-color: $borders_dim;"
    set -a lines4 "  --border-color: $borders;"
    set -a lines4 '}'
    set -a lines4 ''
    set -a lines4 '/* Фон overlay: selection_background вместо жёсткого #2F2F3A. */'
    set -a lines4 'overlay > scrolledwindow {'
    set -a lines4 "  background-color: $sel_bg;"
    set -a lines4 '  border-radius: 12px;'
    set -a lines4 '  margin: 11px;'
    set -a lines4 "  box-shadow: 0 2px 8px $shadow;"
    set -a lines4 '}'
    set -a lines4 ''
    set -a lines4 'overlay-split-view > widget,'
    set -a lines4 'overlay-split-view > widget.sidebar,'
    set -a lines4 'overlay-split-view > widget:first-child {'
    set -a lines4 '  border: none;'
    set -a lines4 '  box-shadow: none;'
    set -a lines4 '}'
    set -a lines4 ''
    set -a lines4 '.navigation-sidebar {'
    set -a lines4 '  border-right: none;'
    set -a lines4 '  box-shadow: none;'
    set -a lines4 '}'

    _theme_write $dir/gtk-4.0/gtk.css $lines4
    or begin
        echo "Ошибка [gtk]: не удалось записать $dir/gtk-4.0/gtk.css" >&2
        return 1
    end
    echo "  [gtk] $dir/gtk-4.0/gtk.css"
end
