# ============================================================
# Генератор: btop/themes/velora.theme
#
# Вызывается из _theme_generate (theme.fish) после разбора
# активной темы. Пишет velora/btop/themes/velora.theme.
# Файл не коммитится в git.
#
# Формат темы btop (проверен на btop 1.4.8, man btop,
# /usr/share/btop/themes/*.theme):
#   theme[ключ]="#RRGGBB"
# Каталог тем btop ищет в "$HOME/.config/btop/themes"
# (~/.config/btop — симлинк на velora/btop).
#
# Мэппинг (ключ btop -> ключ theme.conf):
#   main_bg, main_fg   — background, foreground
#   title, hi_fg       — accent из метаданных (дефолт color4)
#   selected_bg/fg     — selection_background, selection_foreground
#                        (нет в теме — color0 / foreground)
#   inactive_fg        — color8
#   proc_misc          — color4
#   *_box, div_line    — color8 (рамки)
#   графики: зелёный -> жёлтый -> красный (color2 -> color3 -> color1),
#   память: color6 -> color4 -> color5, загрузка/отдача сети — те же.
# ============================================================

function _gen_btop
    set -l dir $VELORA_ROOT/btop
    mkdir -p -- $dir/themes
    or return 1

    set -l accent_key (_theme_meta accent)
    if test -z "$accent_key"
        set accent_key color4
    end

    # Значения по умолчанию для необязательных ключей палитры
    set -l sel_bg (_theme_color selection_background)
    test -z "$sel_bg"; and set sel_bg (_theme_color color0)
    set -l sel_fg (_theme_color selection_foreground)
    test -z "$sel_fg"; and set sel_fg (_theme_color foreground)

    # Пары: ключ btop, затем ключ theme.conf
    set -l pairs \
        main_bg background \
        main_fg foreground \
        title $accent_key \
        hi_fg $accent_key \
        selected_bg selection_background \
        selected_fg selection_foreground \
        followed_bg selection_background \
        followed_fg $accent_key \
        proc_banner_bg color0 \
        proc_banner_fg $accent_key \
        proc_follow_bg color11 \
        proc_pause_bg color3 \
        inactive_fg color8 \
        proc_misc color4 \
        cpu_box color8 \
        mem_box color8 \
        net_box color8 \
        proc_box color8 \
        div_line color8 \
        temp_start color2 \
        temp_mid color3 \
        temp_end color1 \
        cpu_start color2 \
        cpu_mid color3 \
        cpu_end color1 \
        free_start color6 \
        free_mid color4 \
        free_end color5 \
        cached_start color14 \
        cached_mid color13 \
        cached_end color5 \
        available_start color3 \
        available_mid color7 \
        available_end color15 \
        used_start color1 \
        used_mid color9 \
        used_end color13 \
        download_start color6 \
        download_mid color4 \
        download_end color5 \
        upload_start color5 \
        upload_mid color4 \
        upload_end color6 \
        process_start color2 \
        process_mid color3 \
        process_end color1

    set -l lines
    set -a lines '# velora.theme — сгенерирован командой theme set, править руками нельзя.'
    set -a lines '# Источник: velora/themes/current/theme.conf'
    set -a lines ''

    for i in (seq 1 2 (count $pairs))
        set -l key $pairs[$i]
        set -l src $pairs[(math $i + 1)]

        # Цвета выбора заменяются значениями по умолчанию
        if test "$src" = selection_background
            set -a lines "theme[$key]=\"$sel_bg\""
        else if test "$src" = selection_foreground
            set -a lines "theme[$key]=\"$sel_fg\""
        else
            set -l hex (_theme_color $src)
            if test -z "$hex"
                echo "Ошибка [btop]: в теме нет цвета '$src'" >&2
                return 1
            end
            set -a lines "theme[$key]=\"$hex\""
        end
    end

    _theme_write $dir/themes/velora.theme $lines
    or begin
        echo "Ошибка [btop]: не удалось записать $dir/themes/velora.theme" >&2
        return 1
    end
    echo "  [btop] $dir/themes/velora.theme"
end
